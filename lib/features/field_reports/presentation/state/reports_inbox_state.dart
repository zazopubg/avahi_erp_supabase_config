import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/field_report.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/enums/report_status.dart';

/// حالة `ReportsInboxCubit` الكاملة — Union Type مكتوب يدوياً، بنفس
/// نمط `ReportFormState`/`TasksState`.
///
/// يقود هذا الـ Cubit كل شاشات جانب "الإدارة" من الميزة (سطح المكتب):
/// الوارد اللحظي (`reports_inbox.dart`)، مراجعة تقرير واحد
/// (`report_review_screen.dart`)، الأرشيف (`reports_archive.dart`)،
/// والتصدير (`report_export_screen.dart`) — الأربعة تشترك نفس نسخة
/// [ReportsInboxCubit] (`BlocProvider` واحد على مستوى الفرع الإداري من
/// `field_reports_screen.dart`)، وتُفرَّق فقط عبر [ReportsInboxData]
/// المصفَّاة بحسب `statusFilter`/`searchQuery`/مدى تاريخي — بنفس فلسفة
/// `AttendanceCubit` (مراقبة لحظية + تقرير شهري بنفس الكائن المجمّع).
sealed class ReportsInboxState {
  const ReportsInboxState();

  T when<T>({
    required T Function() loading,
    required T Function(ReportsInboxData data) ready,
    required T Function(Failure failure) error,
  }) {
    final ReportsInboxState state = this;
    return switch (state) {
      ReportsInboxLoading() => loading(),
      ReportsInboxReady(:final data) => ready(data),
      ReportsInboxError(:final failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(ReportsInboxData data)? ready,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      ready: ready ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  ReportsInboxData? get dataOrNull =>
      maybeWhen<ReportsInboxData?>(orElse: () => null, ready: (ReportsInboxData d) => d);
}

final class ReportsInboxLoading extends ReportsInboxState {
  const ReportsInboxLoading();
}

final class ReportsInboxReady extends ReportsInboxState {
  const ReportsInboxReady(this.data);

  final ReportsInboxData data;
}

final class ReportsInboxError extends ReportsInboxState {
  const ReportsInboxError(this.failure);

  final Failure failure;
}

/// حزمة بيانات الجانب الإداري المجمّعة — يحملها [ReportsInboxReady] وحدها.
class ReportsInboxData {
  const ReportsInboxData({
    required this.currentUser,
    required this.project,
    this.reports = const <FieldReport>[],
    this.selectedReport,
    this.statusFilter,
    this.searchQuery = '',
    this.exportFrom,
    this.exportTo,
    this.isReviewing = false,
  });

  final AppUser currentUser;
  final Project project;

  /// كل تقارير [project] — تُحدَّث أولياً عبر `GetProjectReportsUsecase`
  /// ثم لحظياً عبر `WatchProjectReportsUsecase` (`reports_inbox.dart`).
  final List<FieldReport> reports;

  /// التقرير المفتوح حالياً للمراجعة التفصيلية — `report_review_screen.dart`.
  final FieldReport? selectedReport;

  /// تصفية حسب الحالة — `null` يعني "كل الحالات". `reports_inbox.dart`
  /// يضبطها افتراضياً على [ReportStatus.submitted] (الوارد الفعلي بحاجة
  /// مراجعة)، بينما `reports_archive.dart` يضبطها على `reviewed`/`rejected`.
  final ReportStatus? statusFilter;

  final String searchQuery;

  /// مدى تاريخي اختياري للتصدير — `report_export_screen.dart`. `null`
  /// يعني بلا حد أدنى/أقصى (كل التقارير المطابقة للتصفية الأخرى).
  final DateTime? exportFrom;
  final DateTime? exportTo;

  final bool isReviewing;

  /// [reports] بعد تطبيق [statusFilter]/[searchQuery] معاً — يعتمدها
  /// `reports_inbox.dart` و`reports_archive.dart` كلاهما (بتصفية حالة
  /// مختلفة مضبوطة من الشاشة نفسها عبر `setStatusFilter`).
  List<FieldReport> get filteredReports {
    final String query = searchQuery.trim().toLowerCase();
    return reports.where((FieldReport r) {
      if (statusFilter != null && r.status != statusFilter) return false;
      if (query.isNotEmpty) {
        final bool matches =
            (r.workPerformed?.toLowerCase().contains(query) ?? false) ||
                (r.notes?.toLowerCase().contains(query) ?? false);
        if (!matches) return false;
      }
      return true;
    }).toList(growable: false)
      ..sort((FieldReport a, FieldReport b) => b.reportDate.compareTo(a.reportDate));
  }

  /// التقارير المُقدَّمة بانتظار اعتماد — عدّاد شارة "الوارد" بغض النظر
  /// عن [statusFilter] الحالي في الشاشة.
  List<FieldReport> get pendingReview =>
      reports.where((FieldReport r) => r.status.isSubmitted).toList(growable: false);

  /// [reports] ضمن [exportFrom]/[exportTo] (إن حُدِّدا) — `report_export_screen.dart`.
  List<FieldReport> get reportsInExportRange {
    return reports.where((FieldReport r) {
      if (exportFrom != null && r.reportDate.isBefore(exportFrom!)) return false;
      if (exportTo != null && r.reportDate.isAfter(exportTo!)) return false;
      return true;
    }).toList(growable: false)
      ..sort((FieldReport a, FieldReport b) => a.reportDate.compareTo(b.reportDate));
  }

  ReportsInboxData copyWith({
    AppUser? currentUser,
    Project? project,
    List<FieldReport>? reports,
    FieldReport? selectedReport,
    bool clearSelectedReport = false,
    ReportStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    DateTime? exportFrom,
    bool clearExportFrom = false,
    DateTime? exportTo,
    bool clearExportTo = false,
    bool? isReviewing,
  }) {
    return ReportsInboxData(
      currentUser: currentUser ?? this.currentUser,
      project: project ?? this.project,
      reports: reports ?? this.reports,
      selectedReport:
          clearSelectedReport ? null : (selectedReport ?? this.selectedReport),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      exportFrom: clearExportFrom ? null : (exportFrom ?? this.exportFrom),
      exportTo: clearExportTo ? null : (exportTo ?? this.exportTo),
      isReviewing: isReviewing ?? this.isReviewing,
    );
  }
}
