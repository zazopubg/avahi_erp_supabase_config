import 'package:drift/drift.dart' show Value;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../cloud/supabase/repositories/notification_repository_impl.dart'
    as cloud;
import '../dto/notification_dto.dart';
import '../local/daos/notification_dao.dart';
import '../local/local_database.dart'
    show NotificationRow, NotificationTableCompanion;
import '../sync/connectivity/network_monitor.dart';
import '../sync/outbox/idempotency_helper.dart';
import '../sync/outbox/outbox_processor.dart' show LocalSyncStateWriter;
import '../sync/outbox/outbox_queue.dart';

/// تنفيذ [INotificationRepository] الموحَّد الذي يُحقَن فعلياً في
/// `UseCases` بدءاً من هذه الخطوة. 🆕
///
/// القاعدة هنا مختلفة قليلاً عن بقية هذه الخطوة بحسب متطلبات الشجرة:
/// - القراءة محلية دائماً (ذاكرة مؤقتة، `NotificationTable`).
/// - تحديث `isRead` (`markAsRead`/`markAllAsRead`) يُكتب محلياً فوراً
///   دائماً (استجابة فورية لضغطة المستخدم)، ثم:
///   - إن وُجد اتصال الآن ([NetworkMonitor.isOnline]): يُرسَل *مباشرة*
///     عبر التنفيذ السحابي (Prompt 07) دون انتظار دورة `sync_engine`
///     التالية — إشعارات "مقروء" منخفضة الخطورة ولا تحتاج ضمانات
///     Idempotency معقّدة، فإرسالها الفوري عند توفر الشبكة أبسط وأسرع
///     من الانتظار.
///   - وإلا (بلا اتصال): تُضاف إلى `outbox_queue` كبقية الكيانات.
/// - `watchNewNotifications` يُفوَّض إلى الاشتراك اللحظي السحابي
///   (`NotificationSubscription`، Realtime، Prompt 07) مباشرة — لا بديل
///   محلياً لبثّ لحظي حقيقي — لكنه أيضاً يحدّث الذاكرة المؤقتة المحلية
///   بكل إشعار جديد يصل، بحيث يعكس `getNotifications` اللاحق هذا
///   الإشعار فوراً دون انتظار مزامنة سحب كاملة.
class NotificationRepositoryImpl
    implements INotificationRepository, LocalSyncStateWriter {
  NotificationRepositoryImpl({
    required NotificationDao dao,
    required OutboxQueue outboxQueue,
    required NetworkMonitor networkMonitor,
    cloud.NotificationRepositoryImpl? cloudRepository,
  })  : _dao = dao,
        _outbox = outboxQueue,
        _network = networkMonitor,
        _cloud = cloudRepository ?? cloud.NotificationRepositoryImpl();

  final NotificationDao _dao;
  final OutboxQueue _outbox;
  final NetworkMonitor _network;
  final cloud.NotificationRepositoryImpl _cloud;

  // ── قراءات (محلية فقط) ──────────────────────────────────────────

  @override
  Future<ResultOf<List<AppNotification>>> getNotifications({
    required String userId,
    bool unreadOnly = false,
  }) async {
    final List<NotificationRow> rows = await _dao.getAllForUser(userId);
    final Iterable<NotificationRow> filtered =
        unreadOnly ? rows.where((NotificationRow r) => !r.isRead) : rows;
    return Right<Failure, List<AppNotification>>(
      filtered.map(_rowToEntity).toList(growable: false),
    );
  }

  // ── كتابات (محلي أولاً دائماً، ثم إرسال فوري إن وُجد اتصال وإلا outbox) ──

  @override
  Future<ResultOf<AppNotification>> markAsRead(String notificationId) async {
    final NotificationRow? row = await _dao.getById(notificationId);
    if (row == null) {
      return const Left<Failure, AppNotification>(
        ValidationFailure(
          message: 'الإشعار غير موجود في الذاكرة المحلية.',
          code: 'notification.not_found_locally',
        ),
      );
    }

    await _dao.markRead(notificationId);
    final AppNotification optimistic = _rowToEntity(row).copyWith(
      isRead: true,
      readAt: DateTime.now().toUtc(),
    );

    if (!_network.isOnline) {
      await _enqueueMarkRead(optimistic);
      return Right<Failure, AppNotification>(optimistic);
    }

    final ResultOf<AppNotification> remote =
        await _cloud.markAsRead(notificationId);
    return remote.fold<Future<ResultOf<AppNotification>>>(
      (Failure failure) async {
        await _enqueueMarkRead(optimistic);
        return Left<Failure, AppNotification>(failure);
      },
      (AppNotification confirmed) async {
        await _dao.upsertNotification(
          _toCompanion(confirmed, syncState: SyncState.synced),
        );
        return Right<Failure, AppNotification>(confirmed);
      },
    );
  }

  @override
  Future<ResultOf<void>> markAllAsRead(String userId) async {
    final List<NotificationRow> unreadBefore =
        (await _dao.getAllForUser(userId))
            .where((NotificationRow r) => !r.isRead)
            .toList(growable: false);
    if (unreadBefore.isEmpty) return const Right<Failure, void>(null);

    await _dao.markAllReadForUser(userId);

    if (!_network.isOnline) {
      final DateTime readAt = DateTime.now().toUtc();
      for (final NotificationRow row in unreadBefore) {
        await _enqueueMarkRead(
          _rowToEntity(row).copyWith(isRead: true, readAt: readAt),
        );
      }
      return const Right<Failure, void>(null);
    }

    final ResultOf<void> remote = await _cloud.markAllAsRead(userId);
    return remote.fold<Future<ResultOf<void>>>(
      (Failure failure) async {
        final DateTime readAt = DateTime.now().toUtc();
        for (final NotificationRow row in unreadBefore) {
          await _enqueueMarkRead(
            _rowToEntity(row).copyWith(isRead: true, readAt: readAt),
          );
        }
        return Left<Failure, void>(failure);
      },
      (_) async {
        for (final NotificationRow row in unreadBefore) {
          await _dao.markSyncState(row.id, SyncState.synced.name);
        }
        return const Right<Failure, void>(null);
      },
    );
  }

  @override
  Stream<AppNotification> watchNewNotifications(String userId) {
    return _cloud.watchNewNotifications(userId).asyncMap((
      AppNotification notification,
    ) async {
      await _dao.upsertNotification(
        _toCompanion(notification, syncState: SyncState.synced),
      );
      return notification;
    });
  }

  // ── LocalSyncStateWriter (تُسجَّل لدى `OutboxProcessor` عبر
  //    `core/di/` في Prompt 11 تحت مفتاح `ApiConstants.tableNotifications`) ──

  @override
  Future<void> markSynced(String entityId) =>
      _dao.markSyncState(entityId, SyncState.synced.name);

  @override
  Future<void> markFailed(String entityId, String error) =>
      _dao.markSyncState(entityId, SyncState.failed.name);

  @override
  Future<void> markConflict(
    String entityId,
    Map<String, dynamic> remotePayload,
  ) =>
      _dao.markSyncState(entityId, SyncState.conflict.name);

  @override
  Future<void> overwriteWithRemote(
    String entityId,
    Map<String, dynamic> remotePayload,
  ) {
    final AppNotification remote =
        NotificationDto.fromJson(remotePayload).toEntity();
    return _dao.upsertNotification(
      _toCompanion(remote, syncState: SyncState.synced),
    );
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  Future<void> _enqueueMarkRead(AppNotification notification) {
    return _outbox.enqueue(
      entityType: ApiConstants.tableNotifications,
      entityId: notification.id,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': notification.id,
        'is_read': true,
        'read_at': notification.readAt?.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
  }

  AppNotification _rowToEntity(NotificationRow row) {
    return NotificationDto.fromJson(<String, dynamic>{
      'id': row.id,
      'company_id': row.companyId,
      'user_id': row.userId,
      'title': row.title,
      'body': row.body,
      'type': row.type,
      'related_entity_type': row.relatedEntityType,
      'related_entity_id': row.relatedEntityId,
      'is_read': row.isRead,
      'read_at': row.readAt?.toIso8601String(),
      'created_at': row.createdAt.toIso8601String(),
    }).toEntity();
  }

  NotificationTableCompanion _toCompanion(
    AppNotification entity, {
    required SyncState syncState,
  }) {
    return NotificationTableCompanion(
      id: Value<String>(entity.id),
      companyId: Value<String>(entity.companyId),
      userId: Value<String>(entity.userId),
      title: Value<String>(entity.title),
      body: Value<String?>(entity.body),
      type: Value<String>(entity.type.dbValue),
      relatedEntityType: Value<String?>(entity.relatedEntityType?.dbValue),
      relatedEntityId: Value<String?>(entity.relatedEntityId),
      isRead: Value<bool>(entity.isRead),
      readAt: Value<DateTime?>(entity.readAt),
      createdAt: Value<DateTime>(entity.createdAt),
      syncState: Value<String>(syncState.name),
    );
  }
}
