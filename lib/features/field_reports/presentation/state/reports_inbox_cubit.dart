import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/field_report.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/enums/report_status.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import '../../../../domain/usecases/reports/get_project_reports_usecase.dart';
import '../../../../domain/usecases/reports/review_report_usecase.dart';
import '../../../../domain/usecases/reports/watch_project_reports_usecase.dart';
import 'reports_inbox_state.dart';

/// `Cubit` جانب "الإدارة" الكامل من ميزة التقارير — يقود
/// `reports_inbox.dart` (وارد حي)، `report_review_screen.dart`
/// (اعتماد/رفض)، `reports_archive.dart` (أرشيف)، و`report_export_screen.dart`
/// (تصدير) معاً عبر [ReportsInboxData] واحدة مجمّعة، بنفس فلسفة
/// `AttendanceCubit` (تحميل أولي + اشتراك لحظي مدمج بنفس القائمة).
class ReportsInboxCubit extends Cubit<ReportsInboxState> {
  ReportsInboxCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required GetProjectReportsUsecase getProjectReportsUsecase,
    required WatchProjectReportsUsecase watchProjectReportsUsecase,
    required ReviewReportUsecase reviewReportUsecase,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _getProjectReportsUsecase = getProjectReportsUsecase,
        _watchProjectReportsUsecase = watchProjectReportsUsecase,
        _reviewReportUsecase = reviewReportUsecase,
        super(const ReportsInboxLoading());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final GetProjectReportsUsecase _getProjectReportsUsecase;
  final WatchProjectReportsUsecase _watchProjectReportsUsecase;
  final ReviewReportUsecase _reviewReportUsecase;

  StreamSubscription<FieldReport>? _subscription;

  /// يحدّد "المشروع الحالي" (نفس منطق `AttendanceCubit.loadInitial`)،
  /// يجلب كل تقاريره أولياً، ثم يبدأ اشتراكاً لحظياً يدمج أي تحديث/
  /// إنشاء وارد ضمن نفس القائمة فوراً (استبدال حسب `id` أو إضافة في
  /// المقدمة) — `field_reports_screen.dart` عند فتح الفرع الإداري
  /// (سطح المكتب). يضبط [ReportsInboxData.statusFilter] افتراضياً على
  /// [ReportStatus.submitted] (تبويب "الوارد").
  Future<void> loadInitial(AppUser user) async {
    emit(const ReportsInboxLoading());

    final ResultOf<List<Project>> projectsResult = await _getMyProjectsUsecase(user.userId);

    final Project? project = projectsResult.fold(
      (Failure _) => null,
      (List<Project> projects) {
        if (projects.isEmpty) return null;
        return projects.firstWhere(
          (Project p) => p.status.isActive,
          orElse: () => projects.first,
        );
      },
    );

    if (project == null) {
      emit(
        const ReportsInboxError(
          ValidationFailure(
            message: 'لا يوجد مشروع نشط مرتبط بحسابك لعرض تقاريره.',
            code: 'field_reports.no_project',
          ),
        ),
      );
      return;
    }

    final ResultOf<List<FieldReport>> result = await _getProjectReportsUsecase(project.id);

    result.fold(
      (Failure failure) => emit(ReportsInboxError(failure)),
      (List<FieldReport> reports) {
        emit(
          ReportsInboxReady(
            ReportsInboxData(
              currentUser: user,
              project: project,
              reports: reports,
              statusFilter: ReportStatus.submitted,
            ),
          ),
        );
        _subscribeToRealtime(project.id);
      },
    );
  }

  void _subscribeToRealtime(String projectId) {
    _subscription?.cancel();
    _subscription = _watchProjectReportsUsecase(projectId).listen((FieldReport incoming) {
      final ReportsInboxData? current = state.dataOrNull;
      if (current == null) return;

      final int existingIndex =
          current.reports.indexWhere((FieldReport r) => r.id == incoming.id);
      final List<FieldReport> updated = List<FieldReport>.of(current.reports);
      if (existingIndex >= 0) {
        updated[existingIndex] = incoming;
      } else {
        updated.insert(0, incoming);
      }

      final FieldReport? selected = current.selectedReport;
      emit(
        ReportsInboxReady(
          current.copyWith(
            reports: updated,
            selectedReport: (selected != null && selected.id == incoming.id)
                ? incoming
                : selected,
          ),
        ),
      );
    });
  }

  // ── تصفية وتنقّل ──────────────────────────────────────────────────

  /// `null` يزيل التصفية بالكامل (كل الحالات) — `reports_archive.dart`
  /// يستدعيها بلا وسيط عند اختيار تبويب "كل السجلات".
  void setStatusFilter(ReportStatus? status) {
    final ReportsInboxData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      ReportsInboxReady(
        status == null
            ? current.copyWith(clearStatusFilter: true)
            : current.copyWith(statusFilter: status),
      ),
    );
  }

  void setSearchQuery(String query) {
    final ReportsInboxData? current = state.dataOrNull;
    if (current == null) return;
    emit(ReportsInboxReady(current.copyWith(searchQuery: query)));
  }

  /// يفتح تقريراً في لوحة/شاشة المراجعة التفصيلية —
  /// `reports_inbox.dart`/`reports_archive.dart` عند اختيار سطر.
  void selectReport(FieldReport report) {
    final ReportsInboxData? current = state.dataOrNull;
    if (current == null) return;
    emit(ReportsInboxReady(current.copyWith(selectedReport: report)));
  }

  void clearSelection() {
    final ReportsInboxData? current = state.dataOrNull;
    if (current == null) return;
    emit(ReportsInboxReady(current.copyWith(clearSelectedReport: true)));
  }

  /// نطاق تاريخي للتصدير — `report_export_screen.dart`.
  void setExportRange({DateTime? from, DateTime? to}) {
    final ReportsInboxData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      ReportsInboxReady(
        current.copyWith(
          exportFrom: from,
          clearExportFrom: from == null,
          exportTo: to,
          clearExportTo: to == null,
        ),
      ),
    );
  }

  // ── اعتماد / رفض ─────────────────────────────────────────────────

  /// يعتمد أو يرفض [report] — `report_approval_actions.dart` ضمن
  /// `report_review_screen.dart`. يُحدَّث السجل محلياً فور نجاح
  /// الاستدعاء (إضافة للانتظار حتى وصول التحديث اللحظي المطابق أيضاً،
  /// لتفادي وميض واجهة أثناء زمن انتقال الشبكة).
  Future<bool> review({
    required FieldReport report,
    required bool approve,
    required String reviewerId,
    String? rejectionReason,
  }) async {
    final ReportsInboxData? current = state.dataOrNull;
    if (current == null) return false;

    emit(ReportsInboxReady(current.copyWith(isReviewing: true)));

    final ResultOf<FieldReport> result = await _reviewReportUsecase(
      report: report,
      approve: approve,
      reviewerId: reviewerId,
      rejectionReason: rejectionReason,
    );

    final ReportsInboxData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(ReportsInboxReady(latest.copyWith(isReviewing: false)));
        return false;
      },
      (FieldReport reviewed) {
        final List<FieldReport> updated = latest.reports
            .map((FieldReport r) => r.id == reviewed.id ? reviewed : r)
            .toList(growable: false);
        emit(
          ReportsInboxReady(
            latest.copyWith(
              reports: updated,
              selectedReport: reviewed,
              isReviewing: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
