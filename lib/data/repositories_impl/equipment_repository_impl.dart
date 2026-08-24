import 'package:drift/drift.dart' show Value;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failure.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/enums/equipment_status.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/repositories/i_equipment_repository.dart';
import '../dto/equipment_dto.dart';
import '../local/daos/equipment_dao.dart';
import '../local/local_database.dart' show EquipmentRow, EquipmentTableCompanion;
import '../sync/outbox/idempotency_helper.dart';
import '../sync/outbox/outbox_processor.dart' show LocalSyncStateWriter;
import '../sync/outbox/outbox_queue.dart';

/// تنفيذ [IEquipmentRepository] الموحَّد الذي يُحقَن فعلياً في
/// `UseCases` بدءاً من هذه الخطوة. 🆕 يتّبع نفس نمط `TaskRepositoryImpl`
/// حرفياً: قراءة محلية فقط، كتابة محلية أولاً ثم `outbox_queue`.
///
/// ⚠️ [IEquipmentRepository.getCompanyEquipment] لا يستقبل `companyId`
/// (التنفيذ السحابي، Prompt 07، يعتمد على RLS لتحديد نطاق الشركة
/// تلقائياً من جلسة المستخدم). محلياً لا وجود لـ RLS، لذا يُستخدم
/// [SessionService.readActiveTenantId] (`core/services/`، Prompt 02)
/// لتحديد الشركة الحالية بدلاً من ذلك.
class EquipmentRepositoryImpl
    implements IEquipmentRepository, LocalSyncStateWriter {
  EquipmentRepositoryImpl({
    required EquipmentDao dao,
    required OutboxQueue outboxQueue,
    required SessionService sessionService,
  })  : _dao = dao,
        _outbox = outboxQueue,
        _session = sessionService;

  final EquipmentDao _dao;
  final OutboxQueue _outbox;
  final SessionService _session;

  // ── قراءات (محلية فقط) ──────────────────────────────────────────

  @override
  Future<ResultOf<Equipment>> getEquipmentById(String equipmentId) async {
    final EquipmentRow? row = await _dao.getById(equipmentId);
    if (row == null) return _notFound(equipmentId);
    return Right<Failure, Equipment>(_rowToEntity(row));
  }

  @override
  Future<ResultOf<List<Equipment>>> getCompanyEquipment({
    String? projectId,
  }) async {
    final String? companyId = await _session.readActiveTenantId();
    if (companyId == null) {
      return const Left<Failure, List<Equipment>>(
        AuthFailure(
          message: 'لا توجد شركة نشطة ضمن الجلسة الحالية.',
          code: 'equipment.no_active_tenant',
        ),
      );
    }

    final List<EquipmentRow> rows = await _dao.getAllForCompany(companyId);
    final Iterable<EquipmentRow> filtered = projectId == null
        ? rows
        : rows.where((EquipmentRow r) => r.projectId == projectId);
    return Right<Failure, List<Equipment>>(
      filtered.map(_rowToEntity).toList(growable: false),
    );
  }

  // ── كتابات (محلي أولاً، ثم outbox) ──────────────────────────────

  @override
  Future<ResultOf<Equipment>> assignEquipment({
    required String equipmentId,
    String? assignedTo,
    String? projectId,
  }) async {
    final EquipmentRow? row = await _dao.getById(equipmentId);
    if (row == null) return _notFound(equipmentId);

    final Equipment updated = _rowToEntity(row).copyWith(
      assignedTo: assignedTo,
      projectId: projectId,
      status:
          assignedTo == null ? EquipmentStatus.available : EquipmentStatus.inUse,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.upsertEquipment(
      _toCompanion(updated, syncState: SyncState.pending),
    );
    await _outbox.enqueue(
      entityType: ApiConstants.tableEquipment,
      entityId: equipmentId,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': equipmentId,
        'assigned_to': assignedTo,
        'project_id': projectId,
        'status': updated.status.dbValue,
        'updated_at': updated.updatedAt.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, Equipment>(updated);
  }

  @override
  Future<ResultOf<Equipment>> updateUsageHours({
    required String equipmentId,
    required double newUsageHours,
  }) async {
    final EquipmentRow? row = await _dao.getById(equipmentId);
    if (row == null) return _notFound(equipmentId);

    final Equipment updated = _rowToEntity(row).copyWith(
      usageHours: newUsageHours,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.upsertEquipment(
      _toCompanion(updated, syncState: SyncState.pending),
    );
    await _outbox.enqueue(
      entityType: ApiConstants.tableEquipment,
      entityId: equipmentId,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': equipmentId,
        'usage_hours': newUsageHours,
        'updated_at': updated.updatedAt.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, Equipment>(updated);
  }

  @override
  Future<ResultOf<Equipment>> updateStatus({
    required String equipmentId,
    required String statusDbValue,
  }) async {
    final EquipmentRow? row = await _dao.getById(equipmentId);
    if (row == null) return _notFound(equipmentId);

    final Equipment updated = _rowToEntity(row).copyWith(
      status: EquipmentStatus.fromDbValue(statusDbValue),
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.upsertEquipment(
      _toCompanion(updated, syncState: SyncState.pending),
    );
    await _outbox.enqueue(
      entityType: ApiConstants.tableEquipment,
      entityId: equipmentId,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': equipmentId,
        'status': statusDbValue,
        'updated_at': updated.updatedAt.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, Equipment>(updated);
  }

  // ── LocalSyncStateWriter (تُسجَّل لدى `OutboxProcessor` عبر
  //    `core/di/` في Prompt 11 تحت مفتاح `ApiConstants.tableEquipment`) ──

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
    final Equipment remote = EquipmentDto.fromJson(remotePayload).toEntity();
    return _dao.upsertEquipment(
      _toCompanion(remote, syncState: SyncState.synced),
    );
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  Left<Failure, Equipment> _notFound(String equipmentId) {
    return const Left<Failure, Equipment>(
      ValidationFailure(
        message: 'المعدة غير موجودة في الذاكرة المحلية.',
        code: 'equipment.not_found_locally',
      ),
    );
  }

  Equipment _rowToEntity(EquipmentRow row) {
    return EquipmentDto.fromJson(<String, dynamic>{
      'id': row.id,
      'company_id': row.companyId,
      'project_id': row.projectId,
      'name': row.name,
      'name_ar': row.nameAr,
      'type': row.type,
      'serial_number': row.serialNumber,
      'status': row.status,
      'assigned_to': row.assignedTo,
      'usage_hours': row.usageHours,
      'purchase_date': row.purchaseDate?.toIso8601String(),
      'last_maintenance_date': row.lastMaintenanceDate?.toIso8601String(),
      'next_maintenance_due': row.nextMaintenanceDue?.toIso8601String(),
      'notes': row.notes,
      'created_by': row.createdBy,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    }).toEntity();
  }

  EquipmentTableCompanion _toCompanion(
    Equipment entity, {
    required SyncState syncState,
  }) {
    return EquipmentTableCompanion(
      id: Value<String>(entity.id),
      companyId: Value<String>(entity.companyId),
      projectId: Value<String?>(entity.projectId),
      name: Value<String>(entity.name),
      nameAr: Value<String?>(entity.nameAr),
      type: Value<String>(entity.type),
      serialNumber: Value<String?>(entity.serialNumber),
      status: Value<String>(entity.status.dbValue),
      assignedTo: Value<String?>(entity.assignedTo),
      usageHours: Value<double>(entity.usageHours),
      purchaseDate: Value<DateTime?>(entity.purchaseDate),
      lastMaintenanceDate: Value<DateTime?>(entity.lastMaintenanceDate),
      nextMaintenanceDue: Value<DateTime?>(entity.nextMaintenanceDue),
      notes: Value<String?>(entity.notes),
      createdBy: Value<String?>(entity.createdBy),
      createdAt: Value<DateTime>(entity.createdAt),
      updatedAt: Value<DateTime>(entity.updatedAt),
      syncState: Value<String>(syncState.name),
    );
  }
}
