import 'package:drift/drift.dart';

import '../local_database.dart';
import '../tables/notification_table.dart';

part 'notification_dao.g.dart';

/// عمليات الوصول لجدول [NotificationTable] المحلي
/// (`local_notifications`). 🆕
@DriftAccessor(tables: <Type>[NotificationTable])
class NotificationDao extends DatabaseAccessor<LocalDatabase>
    with _$NotificationDaoMixin {
  NotificationDao(super.db);

  Future<List<NotificationRow>> getAllForUser(String userId) {
    return (select(notificationTable)
          ..where((NotificationTable t) => t.userId.equals(userId))
          ..orderBy(<OrderingTerm Function(NotificationTable)>[
            (NotificationTable t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Stream<List<NotificationRow>> watchAllForUser(String userId) {
    return (select(notificationTable)
          ..where((NotificationTable t) => t.userId.equals(userId))
          ..orderBy(<OrderingTerm Function(NotificationTable)>[
            (NotificationTable t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// بث حي لعدد الإشعارات غير المقروءة — لشارة الجرس في الشريط
  /// العلوي.
  Stream<int> watchUnreadCount(String userId) {
    final Expression<int> countExp = notificationTable.id.count();
    return (selectOnly(notificationTable)
          ..addColumns(<Expression<Object>>[countExp])
          ..where(
            notificationTable.userId.equals(userId) &
                notificationTable.isRead.equals(false),
          ))
        .map((TypedResult row) => row.read(countExp) ?? 0)
        .watchSingle();
  }

  /// إشعار واحد عبر معرّفه — يدعم `NotificationRepositoryImpl.markAsRead`
  /// (`data/repositories_impl/`، Prompt 10) الذي يستقبل `notificationId`
  /// فقط (بلا `userId`) بحسب توقيع `INotificationRepository` الأصلي.
  /// ⚠️ [Prompt 10] ترقيع: أُضيفت هذه الدالة هنا (لم تكن موجودة ضمن
  /// مخرجات Prompt 08 الأصلية).
  Future<NotificationRow?> getById(String id) {
    return (select(notificationTable)
          ..where((NotificationTable t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<NotificationRow>> getPendingSync() {
    return (select(notificationTable)
          ..where(
            (NotificationTable t) => t.syncState.equals('synced').not(),
          ))
        .get();
  }

  Future<void> upsertNotification(NotificationTableCompanion entry) {
    return into(notificationTable).insertOnConflictUpdate(entry);
  }

  /// يعلّم إشعاراً كمقروء محلياً فوراً (استجابة فورية للمستخدم)
  /// وينتظر مزامنة الحقل مع السحابة.
  Future<void> markRead(String id) {
    return (update(notificationTable)
          ..where((NotificationTable t) => t.id.equals(id)))
        .write(
      NotificationTableCompanion(
        isRead: const Value<bool>(true),
        readAt: Value<DateTime?>(DateTime.now().toUtc()),
        syncState: const Value<String>('pending'),
      ),
    );
  }

  Future<void> markAllReadForUser(String userId) {
    return (update(notificationTable)
          ..where((NotificationTable t) => t.userId.equals(userId))
          ..where((NotificationTable t) => t.isRead.equals(false)))
        .write(
      NotificationTableCompanion(
        isRead: const Value<bool>(true),
        readAt: Value<DateTime?>(DateTime.now().toUtc()),
        syncState: const Value<String>('pending'),
      ),
    );
  }

  Future<void> markSyncState(String id, String syncState) {
    return (update(notificationTable)
          ..where((NotificationTable t) => t.id.equals(id)))
        .write(
      NotificationTableCompanion(syncState: Value<String>(syncState)),
    );
  }
}
