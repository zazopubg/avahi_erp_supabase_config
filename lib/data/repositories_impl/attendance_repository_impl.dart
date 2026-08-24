import 'package:drift/drift.dart' show Value;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/enums/attendance_type.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import '../cloud/supabase/repositories/attendance_repository_impl.dart'
    as cloud;
import '../dto/attendance_dto.dart';
import '../local/daos/attendance_dao.dart';
import '../local/local_database.dart' show AttendanceRow, AttendanceTableCompanion;
import '../sync/connectivity/network_monitor.dart';
import '../sync/outbox/idempotency_helper.dart';
import '../sync/outbox/outbox_processor.dart' show LocalSyncStateWriter;
import '../sync/outbox/outbox_queue.dart';

/// تنفيذ [IAttendanceRepository] الموحَّد (محلي + سحابي) الذي يُحقَن
/// فعلياً في `UseCases` بدءاً من هذه الخطوة — يحلّ محل الحقن المباشر
/// لـ `data/cloud/supabase/repositories/attendance_repository_impl.dart`
/// (Prompt 07)، والذي أصبح الآن تفصيلاً داخلياً يُستدعى من هنا فقط.
///
/// ⚠️ قرار معماري خاص بالحضور (يختلف عن بقية مستودعات هذه الخطوة):
/// `checkIn`/`checkOut` **لا يمكن** أن يتّبعا نمط outbox العام دون
/// تحفّظ، لأن Edge Function `attendance-guard` (Prompt 04/07) تطبّق
/// تحققاً جغرافياً (Haversine) وإعادة إرسال آمنة (Idempotent Replay)
/// يمكن بأمان) تكراره على العميل. لذا:
/// - أثناء الاتصال: يُكتب سجل متفائل محلياً فوراً (لتحديث الواجهة دون
///   إبطاء)، ثم يُستدعى `attendance-guard` مباشرة عبر التنفيذ السحابي
///   ([cloud.AttendanceRepositoryImpl])؛ النتيجة الرسمية تستبدل السجل
///   المتفائل عند النجاح.
/// - أثناء انقطاع الاتصال (أو فشل عابر أثناء الاتصال): يبقى السجل
///   المتفائل محلياً ويُضاف إلى `outbox_queue` لإعادة المحاولة لاحقاً
///   عبر `SupabaseOutboxRemoteWriter` العام (Prompt 09) — علماً أن هذا
///   المسار الاحتياطي يتجاوز التحقق الجغرافي الخادمي مؤقتاً؛ سيُعتمد
///   على `geofenceValid` المحسوب محلياً (إن توفر عبر `LocationService`،
///   Prompt 02) إلى حين تأكيد الخادم لاحقاً بعد استعادة الاتصال.
/// - `resolveProjectFromQrCode`: تحقق بحت بلا أي كتابة محلية، يُفوَّض
///   مباشرة للتنفيذ السحابي (يتطلب اتصالاً بطبيعته).
/// - `reviewAttendance`: عملية إدارية على سجل قد يخصّ مستخدماً آخر.
///   أثناء الاتصال تُفوَّض مباشرة للسحابة (لضمان تطبيق RLS/الصلاحيات
///   فوراً) مع تحديث الذاكرة المحلية بالنتيجة؛ عند الانقطاع تُطبَّق
///   محلياً فقط إن كان السجل موجوداً مسبقاً في الذاكرة المؤقتة.
class AttendanceRepositoryImpl
    implements IAttendanceRepository, LocalSyncStateWriter {
  AttendanceRepositoryImpl({
    required AttendanceDao dao,
    required OutboxQueue outboxQueue,
    required NetworkMonitor networkMonitor,
    cloud.AttendanceRepositoryImpl? cloudRepository,
  })  : _dao = dao,
        _outbox = outboxQueue,
        _network = networkMonitor,
        _cloud = cloudRepository ?? cloud.AttendanceRepositoryImpl();

  final AttendanceDao _dao;
  final OutboxQueue _outbox;
  final NetworkMonitor _network;
  final cloud.AttendanceRepositoryImpl _cloud;

  // ── قراءات (محلية فقط) ──────────────────────────────────────────

  @override
  Future<ResultOf<AttendanceRecord?>> getTodayAttendance({
    required String userId,
    required String projectId,
  }) async {
    final AttendanceRow? row = await _dao.getTodayRecordForUser(userId);
    if (row == null || row.projectId != projectId) {
      return const Right<Failure, AttendanceRecord?>(null);
    }
    return Right<Failure, AttendanceRecord?>(_rowToEntity(row));
  }

  // ── كتابات (محلي أولاً، ثم خادم/outbox بحسب الحالة) ─────────────

  @override
  Future<ResultOf<AttendanceRecord>> checkIn(AttendanceRecord record) async {
    await _dao.upsertAttendance(
      _toCompanion(record, syncState: SyncState.pending),
    );

    if (!_network.isOnline) {
      await _enqueue(record, IdempotencyHelper.newMutationId());
      return Right<Failure, AttendanceRecord>(record);
    }

    final ResultOf<AttendanceRecord> remote = await _cloud.checkIn(record);
    return remote.fold<Future<ResultOf<AttendanceRecord>>>(
      (Failure failure) async {
        await _enqueue(record, IdempotencyHelper.newMutationId());
        return Left<Failure, AttendanceRecord>(failure);
      },
      (AttendanceRecord confirmed) async {
        await _dao.upsertAttendance(
          _toCompanion(confirmed, syncState: SyncState.synced),
        );
        return Right<Failure, AttendanceRecord>(confirmed);
      },
    );
  }

  @override
  Future<ResultOf<AttendanceRecord>> checkOut({
    required String attendanceId,
    required DateTime checkOutAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
  }) async {
    final AttendanceRow? existingRow = await _dao.getById(attendanceId);
    if (existingRow == null) {
      return const Left<Failure, AttendanceRecord>(
        ValidationFailure(
          message: 'لا يوجد سجل حضور محلي مطابق لتسجيل الانصراف.',
          code: 'attendance.checkout_record_not_found',
        ),
      );
    }

    final AttendanceRecord updated = _rowToEntity(existingRow).copyWith(
      checkOutAt: checkOutAt,
      checkOutLatitude: checkOutLatitude,
      checkOutLongitude: checkOutLongitude,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.upsertAttendance(
      _toCompanion(updated, syncState: SyncState.pending),
    );

    if (!_network.isOnline) {
      await _enqueue(updated, IdempotencyHelper.newMutationId());
      return Right<Failure, AttendanceRecord>(updated);
    }

    final ResultOf<AttendanceRecord> remote = await _cloud.checkOut(
      attendanceId: attendanceId,
      checkOutAt: checkOutAt,
      checkOutLatitude: checkOutLatitude,
      checkOutLongitude: checkOutLongitude,
    );
    return remote.fold<Future<ResultOf<AttendanceRecord>>>(
      (Failure failure) async {
        await _enqueue(updated, IdempotencyHelper.newMutationId());
        return Left<Failure, AttendanceRecord>(failure);
      },
      (AttendanceRecord confirmed) async {
        await _dao.upsertAttendance(
          _toCompanion(confirmed, syncState: SyncState.synced),
        );
        return Right<Failure, AttendanceRecord>(confirmed);
      },
    );
  }

  @override
  Future<ResultOf<String>> resolveProjectFromQrCode(String qrCodeId) {
    return _cloud.resolveProjectFromQrCode(qrCodeId);
  }

  @override
  Future<ResultOf<AttendanceRecord>> reviewAttendance({
    required String attendanceId,
    required bool approve,
    required String reviewerId,
  }) async {
    if (_network.isOnline) {
      final ResultOf<AttendanceRecord> remote = await _cloud.reviewAttendance(
        attendanceId: attendanceId,
        approve: approve,
        reviewerId: reviewerId,
      );
      await remote.fold(
        (Failure _) async {},
        (AttendanceRecord confirmed) => _dao.upsertAttendance(
          _toCompanion(confirmed, syncState: SyncState.synced),
        ),
      );
      return remote;
    }

    final AttendanceRow? existingRow = await _dao.getById(attendanceId);
    if (existingRow == null) {
      return const Left<Failure, AttendanceRecord>(
        NetworkFailure(
          message: 'اعتماد الحضور بلا اتصال يتطلب وجود السجل مسبقاً محلياً.',
          code: 'attendance.review_requires_connectivity',
        ),
      );
    }

    final AttendanceRecord updated = _rowToEntity(existingRow).copyWith(
      status: approve ? AttendanceType.approved : AttendanceType.rejected,
      approvedBy: reviewerId,
      approvedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.upsertAttendance(
      _toCompanion(updated, syncState: SyncState.pending),
    );
    await _enqueue(updated, IdempotencyHelper.newMutationId());
    return Right<Failure, AttendanceRecord>(updated);
  }

  // ── قراءات تاريخية/إدارية 🆕 ──────────────────────────────────────

  @override
  Future<ResultOf<List<AttendanceRecord>>> getMyHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final List<AttendanceRow> rows = await _dao.getRecordsForUserInRange(
      userId,
      from,
      to,
    );
    return Right<Failure, List<AttendanceRecord>>(
      rows.map(_rowToEntity).toList(growable: false),
    );
  }

  @override
  Future<ResultOf<List<AttendanceRecord>>> getProjectAttendance({
    required String projectId,
    required DateTime from,
    required DateTime to,
  }) async {
    if (_network.isOnline) {
      final ResultOf<List<AttendanceRecord>> remote =
          await _cloud.getProjectAttendance(
        projectId: projectId,
        from: from,
        to: to,
      );
      if (remote.isRight) return remote;
      // فشل عابر رغم توفر الاتصال (مثال: انقطاع مؤقت) — يُكمَل بالنسخة
      // المحلية المخبّأة أدناه بدل إفشال الشاشة كاملة.
    }

    final List<AttendanceRow> rows = await _dao.getRecordsForProjectInRange(
      projectId,
      from,
      to,
    );
    return Right<Failure, List<AttendanceRecord>>(
      rows.map(_rowToEntity).toList(growable: false),
    );
  }

  @override
  Stream<AttendanceRecord> watchProjectAttendance(String projectId) {
    return _cloud.watchProjectAttendance(projectId);
  }

  // ── LocalSyncStateWriter (تُسجَّل لدى `OutboxProcessor` عبر
  //    `core/di/` في Prompt 11 تحت مفتاح `ApiConstants.tableAttendance`) ──

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
    final AttendanceRecord remote = AttendanceDto.fromJson(remotePayload).toEntity();
    return _dao.upsertAttendance(
      _toCompanion(remote, syncState: SyncState.synced),
    );
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  Future<void> _enqueue(AttendanceRecord record, String mutationId) {
    return _outbox.enqueue(
      entityType: ApiConstants.tableAttendance,
      entityId: record.id,
      operationType: record.checkOutAt == null
          ? OutboxOperationType.insert
          : OutboxOperationType.update,
      payload: AttendanceDto.fromEntity(record).toJson(),
      clientMutationId: record.clientMutationId,
      // أولوية عليا: الحضور حسّاس زمنياً وقد يترتب عليه أثر قانوني
      // (استحقاق أجر/غياب)، فيُعطى أولوية على بقية الكيانات في الطابور.
      priority: 10,
    );
  }

  AttendanceRecord _rowToEntity(AttendanceRow row) {
    return AttendanceDto.fromJson(<String, dynamic>{
      'id': row.id,
      'company_id': row.companyId,
      'project_id': row.projectId,
      'user_id': row.userId,
      'client_mutation_id': row.clientMutationId,
      'check_in_at': row.checkInAt.toIso8601String(),
      'check_out_at': row.checkOutAt?.toIso8601String(),
      'check_in_latitude': row.checkInLatitude,
      'check_in_longitude': row.checkInLongitude,
      'check_out_latitude': row.checkOutLatitude,
      'check_out_longitude': row.checkOutLongitude,
      'geofence_valid': row.geofenceValid,
      'distance_meters': row.distanceMeters,
      'check_method': row.checkMethod,
      'qr_code_id': row.qrCodeId,
      'status': row.status,
      'notes': row.notes,
      'approved_by': row.approvedBy,
      'approved_at': row.approvedAt?.toIso8601String(),
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    }).toEntity();
  }

  AttendanceTableCompanion _toCompanion(
    AttendanceRecord entity, {
    required SyncState syncState,
  }) {
    return AttendanceTableCompanion(
      id: Value<String>(entity.id),
      companyId: Value<String>(entity.companyId),
      projectId: Value<String>(entity.projectId),
      userId: Value<String>(entity.userId),
      clientMutationId: Value<String>(entity.clientMutationId),
      checkInAt: Value<DateTime>(entity.checkInAt),
      checkOutAt: Value<DateTime?>(entity.checkOutAt),
      checkInLatitude: Value<double?>(entity.checkInLatitude),
      checkInLongitude: Value<double?>(entity.checkInLongitude),
      checkOutLatitude: Value<double?>(entity.checkOutLatitude),
      checkOutLongitude: Value<double?>(entity.checkOutLongitude),
      geofenceValid: Value<bool>(entity.geofenceValid),
      distanceMeters: Value<double?>(entity.distanceMeters),
      checkMethod: Value<String>(entity.checkMethod.dbValue),
      qrCodeId: Value<String?>(entity.qrCodeId),
      status: Value<String>(entity.status.dbValue),
      notes: Value<String?>(entity.notes),
      approvedBy: Value<String?>(entity.approvedBy),
      approvedAt: Value<DateTime?>(entity.approvedAt),
      createdAt: Value<DateTime>(entity.createdAt),
      updatedAt: Value<DateTime>(entity.updatedAt),
      syncState: Value<String>(syncState.name),
    );
  }
}
