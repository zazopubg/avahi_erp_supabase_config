import 'package:drift/drift.dart' show Value;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/field_report.dart';
import '../../domain/enums/report_status.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/repositories/i_report_repository.dart';
import '../cloud/supabase/realtime/report_subscription.dart';
import '../dto/field_report_dto.dart';
import '../local/daos/report_dao.dart';
import '../local/local_database.dart' show ReportRow, ReportTableCompanion;
import '../sync/outbox/idempotency_helper.dart';
import '../sync/outbox/outbox_processor.dart' show LocalSyncStateWriter;
import '../sync/outbox/outbox_queue.dart';

/// تنفيذ [IReportRepository] الموحَّد الذي يُحقَن فعلياً في
/// `UseCases` بدءاً من هذه الخطوة. كل قراءة محلية فقط، وكل كتابة
/// (بما فيها `submitReport`) تُنفَّذ محلياً أولاً وتُقفل حالة التعديل
/// فوراً في الواجهة **دون انتظار تأكيد الخادم**؛ إرسال العملية الفعلي
/// للسحابة مؤجَّل بالكامل إلى `sync_engine` (Prompt 09) عبر
/// `outbox_queue`.
///
/// لا تفويض هنا لـ `data/cloud/supabase/repositories/report_repository_impl.dart`
/// (Prompt 07): لا توجد عمليات تتطلب Edge Function أو تحققاً خادمياً
/// فورياً على التقارير — رفع ملف التوقيع نفسه إلى Bucket `signatures`
/// وإحلاله محل المسار المحلي المؤقت (`ReportTable.supervisorSignatureUrl`/
/// `clientSignatureUrl`) مسؤولية `data/sync/` لاحقاً وليست هذه الطبقة.
class ReportRepositoryImpl implements IReportRepository, LocalSyncStateWriter {
  ReportRepositoryImpl({
    required ReportDao dao,
    required OutboxQueue outboxQueue,
    ReportSubscription? subscription,
  })  : _dao = dao,
        _outbox = outboxQueue,
        _subscription = subscription ?? ReportSubscription();

  final ReportDao _dao;
  final OutboxQueue _outbox;
  final ReportSubscription _subscription;

  // ── قراءات (محلية فقط) ──────────────────────────────────────────

  @override
  Future<ResultOf<FieldReport>> getReportById(String reportId) async {
    final ReportRow? row = await _dao.getById(reportId);
    if (row == null) return _notFound(reportId);
    return Right<Failure, FieldReport>(_rowToEntity(row));
  }

  @override
  Future<ResultOf<List<FieldReport>>> getProjectReports(
    String projectId,
  ) async {
    final List<ReportRow> rows = await _dao.getAllForProject(projectId);
    return Right<Failure, List<FieldReport>>(
      rows.map(_rowToEntity).toList(growable: false),
    );
  }

  // ── كتابات (محلي أولاً، ثم outbox) ──────────────────────────────

  @override
  Future<ResultOf<FieldReport>> saveDraft(FieldReport report) async {
    final bool exists = await _dao.getById(report.id) != null;
    await _dao.upsertReport(_toCompanion(report, syncState: SyncState.pending));
    await _outbox.enqueue(
      entityType: ApiConstants.tableFieldReports,
      entityId: report.id,
      operationType:
          exists ? OutboxOperationType.update : OutboxOperationType.insert,
      payload: FieldReportDto.fromEntity(report).toJson(),
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, FieldReport>(report);
  }

  @override
  Future<ResultOf<FieldReport>> submitReport(String reportId) async {
    final ReportRow? row = await _dao.getById(reportId);
    if (row == null) return _notFound(reportId);

    // يقفل التعديل محلياً فوراً (status → submitted) دون انتظار أي
    // استجابة من الخادم — الالتزام الصريح لهذه الخطوة.
    final FieldReport updated = _rowToEntity(row).copyWith(
      status: ReportStatus.submitted,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.upsertReport(_toCompanion(updated, syncState: SyncState.pending));
    await _outbox.enqueue(
      entityType: ApiConstants.tableFieldReports,
      entityId: reportId,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': reportId,
        'status': ReportStatus.submitted.dbValue,
        'updated_at': updated.updatedAt.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
      // أولوية أعلى من المتوسط: التقرير المُقدَّم يفتح دورة اعتماد
      // (وربما إشعار `report-notifications`) على المشرف انتظارها.
      priority: 5,
    );
    return Right<Failure, FieldReport>(updated);
  }

  @override
  Future<ResultOf<FieldReport>> reviewReport({
    required String reportId,
    required bool approve,
    required String reviewerId,
    String? rejectionReason,
  }) async {
    final ReportRow? row = await _dao.getById(reportId);
    if (row == null) return _notFound(reportId);

    final FieldReport updated = _rowToEntity(row).copyWith(
      status: approve ? ReportStatus.reviewed : ReportStatus.rejected,
      reviewedBy: reviewerId,
      reviewedAt: DateTime.now().toUtc(),
      rejectionReason: approve ? null : rejectionReason,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.upsertReport(_toCompanion(updated, syncState: SyncState.pending));
    await _outbox.enqueue(
      entityType: ApiConstants.tableFieldReports,
      entityId: reportId,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': reportId,
        'status': updated.status.dbValue,
        'reviewed_by': reviewerId,
        'reviewed_at': updated.reviewedAt?.toIso8601String(),
        'rejection_reason': updated.rejectionReason,
        'updated_at': updated.updatedAt.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, FieldReport>(updated);
  }

  @override
  Future<ResultOf<FieldReport>> attachSignature({
    required String reportId,
    String? supervisorSignatureUrl,
    String? clientSignatureUrl,
  }) async {
    final ReportRow? row = await _dao.getById(reportId);
    if (row == null) return _notFound(reportId);

    final DateTime now = DateTime.now().toUtc();
    final FieldReport current = _rowToEntity(row);
    final FieldReport updated = FieldReport(
      id: current.id,
      companyId: current.companyId,
      projectId: current.projectId,
      reportDate: current.reportDate,
      status: current.status,
      laborCount: current.laborCount,
      createdAt: current.createdAt,
      updatedAt: now,
      createdBy: current.createdBy,
      weatherCondition: current.weatherCondition,
      temperatureC: current.temperatureC,
      workPerformed: current.workPerformed,
      materialsUsed: current.materialsUsed,
      equipmentUsed: current.equipmentUsed,
      issues: current.issues,
      notes: current.notes,
      supervisorSignatureUrl:
          supervisorSignatureUrl ?? current.supervisorSignatureUrl,
      supervisorSignedAt:
          supervisorSignatureUrl != null ? now : current.supervisorSignedAt,
      clientSignatureUrl: clientSignatureUrl ?? current.clientSignatureUrl,
      clientSignedAt: clientSignatureUrl != null ? now : current.clientSignedAt,
      reviewedBy: current.reviewedBy,
      reviewedAt: current.reviewedAt,
      rejectionReason: current.rejectionReason,
    );
    await _dao.upsertReport(_toCompanion(updated, syncState: SyncState.pending));
    await _outbox.enqueue(
      entityType: ApiConstants.tableFieldReports,
      entityId: reportId,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': reportId,
        'supervisor_signature_url': updated.supervisorSignatureUrl,
        'supervisor_signed_at': updated.supervisorSignedAt?.toIso8601String(),
        'client_signature_url': updated.clientSignatureUrl,
        'client_signed_at': updated.clientSignedAt?.toIso8601String(),
        'updated_at': updated.updatedAt.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, FieldReport>(updated);
  }

  // ── بث لحظي (Realtime) ───────────────────────────────────────────

  /// يفوَّض مباشرة لـ [ReportSubscription] (`data/cloud/supabase/realtime/`)
  /// — يتطلب اتصالاً بطبيعته، بخلاف كل القراءات/الكتابات أعلاه (محلية
  /// أولاً). كل تقرير يصل لحظياً (إنشاء/تحديث) يُحفَظ محلياً فوراً
  /// كـ [SyncState.synced] (مصدره الخادم مباشرة، وليس تعديلاً محلياً
  /// معلَّقاً) قبل بثّه للمستمع، حتى تبقى النسخة المحلية مطابقة لآخر
  /// حالة معروفة من الخادم لعرضها لاحقاً دون اتصال.
  @override
  Stream<FieldReport> watchProjectReports(String projectId) {
    return _subscription.watchProjectReports(projectId).asyncMap((
      FieldReport report,
    ) async {
      await _dao.upsertReport(
        _toCompanion(report, syncState: SyncState.synced),
      );
      return report;
    });
  }

  // ── LocalSyncStateWriter (تُسجَّل لدى `OutboxProcessor` عبر
  //    `core/di/` في Prompt 11 تحت مفتاح `ApiConstants.tableFieldReports`) ──

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
    final FieldReport remote = FieldReportDto.fromJson(remotePayload).toEntity();
    return _dao.upsertReport(
      _toCompanion(remote, syncState: SyncState.synced),
    );
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  Left<Failure, FieldReport> _notFound(String reportId) {
    return const Left<Failure, FieldReport>(
      ValidationFailure(
        message: 'التقرير غير موجود في الذاكرة المحلية.',
        code: 'report.not_found_locally',
      ),
    );
  }

  FieldReport _rowToEntity(ReportRow row) {
    return FieldReportDto.fromJson(<String, dynamic>{
      'id': row.id,
      'company_id': row.companyId,
      'project_id': row.projectId,
      'created_by': row.createdBy,
      'report_date': row.reportDate.toIso8601String(),
      'status': row.status,
      'weather_condition': row.weatherCondition,
      'temperature_c': row.temperatureC,
      'labor_count': row.laborCount,
      'work_performed': row.workPerformed,
      'materials_used': row.materialsUsed,
      'equipment_used': row.equipmentUsed,
      'issues': row.issues,
      'notes': row.notes,
      'supervisor_signature_url': row.supervisorSignatureUrl,
      'supervisor_signed_at': row.supervisorSignedAt?.toIso8601String(),
      'client_signature_url': row.clientSignatureUrl,
      'client_signed_at': row.clientSignedAt?.toIso8601String(),
      'reviewed_by': row.reviewedBy,
      'reviewed_at': row.reviewedAt?.toIso8601String(),
      'rejection_reason': row.rejectionReason,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    }).toEntity();
  }

  ReportTableCompanion _toCompanion(
    FieldReport entity, {
    required SyncState syncState,
  }) {
    return ReportTableCompanion(
      id: Value<String>(entity.id),
      companyId: Value<String>(entity.companyId),
      projectId: Value<String>(entity.projectId),
      createdBy: Value<String?>(entity.createdBy),
      reportDate: Value<DateTime>(entity.reportDate),
      status: Value<String>(entity.status.dbValue),
      weatherCondition: Value<String?>(entity.weatherCondition?.dbValue),
      temperatureC: Value<double?>(entity.temperatureC),
      laborCount: Value<int>(entity.laborCount),
      workPerformed: Value<String?>(entity.workPerformed),
      materialsUsed: Value<String?>(entity.materialsUsed),
      equipmentUsed: Value<String?>(entity.equipmentUsed),
      issues: Value<String?>(entity.issues),
      notes: Value<String?>(entity.notes),
      supervisorSignatureUrl: Value<String?>(entity.supervisorSignatureUrl),
      supervisorSignedAt: Value<DateTime?>(entity.supervisorSignedAt),
      clientSignatureUrl: Value<String?>(entity.clientSignatureUrl),
      clientSignedAt: Value<DateTime?>(entity.clientSignedAt),
      reviewedBy: Value<String?>(entity.reviewedBy),
      reviewedAt: Value<DateTime?>(entity.reviewedAt),
      rejectionReason: Value<String?>(entity.rejectionReason),
      createdAt: Value<DateTime>(entity.createdAt),
      updatedAt: Value<DateTime>(entity.updatedAt),
      syncState: Value<String>(syncState.name),
    );
  }
}
