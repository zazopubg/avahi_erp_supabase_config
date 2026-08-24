import 'package:drift/drift.dart' show Value;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/enums/leave_status.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/repositories/i_leave_repository.dart';
import '../dto/leave_request_dto.dart';
import '../local/daos/leave_dao.dart';
import '../local/local_database.dart'
    show LeaveRequestRow, LeaveRequestTableCompanion;
import '../sync/outbox/idempotency_helper.dart';
import '../sync/outbox/outbox_processor.dart' show LocalSyncStateWriter;
import '../sync/outbox/outbox_queue.dart';

/// تنفيذ [ILeaveRepository] الموحَّد الذي يُحقَن فعلياً في
/// `UseCases` بدءاً من هذه الخطوة. 🆕 نفس نمط `TaskRepositoryImpl`
/// حرفياً: قراءة محلية فقط، كتابة محلية أولاً ثم `outbox_queue`.
class LeaveRepositoryImpl implements ILeaveRepository, LocalSyncStateWriter {
  LeaveRepositoryImpl({
    required LeaveDao dao,
    required OutboxQueue outboxQueue,
  })  : _dao = dao,
        _outbox = outboxQueue;

  final LeaveDao _dao;
  final OutboxQueue _outbox;

  // ── قراءات (محلية فقط) ──────────────────────────────────────────

  @override
  Future<ResultOf<LeaveRequest>> getLeaveRequestById(
    String leaveRequestId,
  ) async {
    final LeaveRequestRow? row = await _dao.getById(leaveRequestId);
    if (row == null) return _notFound(leaveRequestId);
    return Right<Failure, LeaveRequest>(_rowToEntity(row));
  }

  @override
  Future<ResultOf<List<LeaveRequest>>> getUserLeaveRequests(
    String userId,
  ) async {
    final List<LeaveRequestRow> rows = await _dao.getAllForUser(userId);
    return Right<Failure, List<LeaveRequest>>(
      rows.map(_rowToEntity).toList(growable: false),
    );
  }

  @override
  Future<ResultOf<List<LeaveRequest>>> getOverlappingLeaveRequests({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final List<LeaveRequestRow> rows = await _dao.getOverlappingForUser(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    return Right<Failure, List<LeaveRequest>>(
      rows.map(_rowToEntity).toList(growable: false),
    );
  }

  @override
  Future<ResultOf<List<LeaveRequest>>> getCompanyLeaveRequests(
    String companyId,
  ) async {
    final List<LeaveRequestRow> rows = await _dao.getAllForCompany(companyId);
    return Right<Failure, List<LeaveRequest>>(
      rows.map(_rowToEntity).toList(growable: false),
    );
  }

  // ── كتابات (محلي أولاً، ثم outbox) ──────────────────────────────

  @override
  Future<ResultOf<LeaveRequest>> requestLeave(LeaveRequest request) async {
    await _dao.upsertLeaveRequest(
      _toCompanion(request, syncState: SyncState.pending),
    );
    await _outbox.enqueue(
      entityType: ApiConstants.tableLeaveRequests,
      entityId: request.id,
      operationType: OutboxOperationType.insert,
      payload: LeaveRequestDto.fromEntity(request).toJson(),
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, LeaveRequest>(request);
  }

  @override
  Future<ResultOf<LeaveRequest>> reviewLeave({
    required String leaveRequestId,
    required bool approve,
    required String reviewerId,
    String? reviewNote,
  }) async {
    final LeaveRequestRow? row = await _dao.getById(leaveRequestId);
    if (row == null) return _notFound(leaveRequestId);

    final LeaveRequest updated = _rowToEntity(row).copyWith(
      status: approve ? LeaveStatus.approved : LeaveStatus.rejected,
      reviewedBy: reviewerId,
      reviewedAt: DateTime.now().toUtc(),
      reviewNote: reviewNote,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.upsertLeaveRequest(
      _toCompanion(updated, syncState: SyncState.pending),
    );
    await _outbox.enqueue(
      entityType: ApiConstants.tableLeaveRequests,
      entityId: leaveRequestId,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': leaveRequestId,
        'status': updated.status.dbValue,
        'reviewed_by': reviewerId,
        'reviewed_at': updated.reviewedAt?.toIso8601String(),
        'review_note': reviewNote,
        'updated_at': updated.updatedAt.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, LeaveRequest>(updated);
  }

  // ── LocalSyncStateWriter (تُسجَّل لدى `OutboxProcessor` عبر
  //    `core/di/` في Prompt 11 تحت مفتاح `ApiConstants.tableLeaveRequests`) ──

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
    final LeaveRequest remote = LeaveRequestDto.fromJson(remotePayload).toEntity();
    return _dao.upsertLeaveRequest(
      _toCompanion(remote, syncState: SyncState.synced),
    );
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  Left<Failure, LeaveRequest> _notFound(String leaveRequestId) {
    return const Left<Failure, LeaveRequest>(
      ValidationFailure(
        message: 'طلب الإجازة غير موجود في الذاكرة المحلية.',
        code: 'leave.not_found_locally',
      ),
    );
  }

  LeaveRequest _rowToEntity(LeaveRequestRow row) {
    return LeaveRequestDto.fromJson(<String, dynamic>{
      'id': row.id,
      'company_id': row.companyId,
      'user_id': row.userId,
      'leave_type': row.leaveType,
      'start_date': row.startDate.toIso8601String(),
      'end_date': row.endDate.toIso8601String(),
      'reason': row.reason,
      'status': row.status,
      'reviewed_by': row.reviewedBy,
      'reviewed_at': row.reviewedAt?.toIso8601String(),
      'review_note': row.reviewNote,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    }).toEntity();
  }

  LeaveRequestTableCompanion _toCompanion(
    LeaveRequest entity, {
    required SyncState syncState,
  }) {
    return LeaveRequestTableCompanion(
      id: Value<String>(entity.id),
      companyId: Value<String>(entity.companyId),
      userId: Value<String>(entity.userId),
      leaveType: Value<String>(entity.leaveType.dbValue),
      startDate: Value<DateTime>(entity.startDate),
      endDate: Value<DateTime>(entity.endDate),
      reason: Value<String?>(entity.reason),
      status: Value<String>(entity.status.dbValue),
      reviewedBy: Value<String?>(entity.reviewedBy),
      reviewedAt: Value<DateTime?>(entity.reviewedAt),
      reviewNote: Value<String?>(entity.reviewNote),
      createdAt: Value<DateTime>(entity.createdAt),
      updatedAt: Value<DateTime>(entity.updatedAt),
      syncState: Value<String>(syncState.name),
    );
  }
}
