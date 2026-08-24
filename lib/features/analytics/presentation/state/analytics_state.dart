import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/attendance_record.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/enums/equipment_status.dart';
import '../../../../domain/enums/task_status.dart';

/// نوع عملية التصدير الجارية حالياً — يميّز [AnalyticsExporting] بين
/// تصدير لوحة كاملة كملف PDF (`export_analytics_screen.dart` عبر
/// `Printing.layoutPdf`، انظر `AnalyticsCubit.exportDashboardAsPdf`)
/// وتصدير التقاط صورة (PNG) لقسم مرئي واحد ضمن اللوحة (عبر
/// `RenderRepaintBoundary` في الشاشة نفسها، ثم تنزيل مباشر في
/// المتصفح — انظر `AnalyticsCubit.exportSectionAsImage`).
enum AnalyticsExportKind { pdf, image }

/// نقطة بيانات واحدة ضمن اتجاه الحضور اليومي — أساس
/// `attendance_trend_chart.dart` (رسم بياني خطي لآخر 30 يوماً
/// افتراضياً، أو أي مدى تاريخي آخر يختاره المستخدم عبر
/// `date_range_filter.dart`).
class AttendanceTrendPoint {
  const AttendanceTrendPoint({
    required this.date,
    required this.presentCount,
  });

  /// يوم واحد (بلا مكوّن وقت — `DateTime` بمنتصف الليل محلياً).
  final DateTime date;

  /// عدد سجلات الحضور (تسجيلات دخول فريدة) المسجَّلة خلال هذا اليوم.
  final int presentCount;
}

/// حزمة مؤشرات مجمّعة لمشروع واحد — مبنية من ثلاثة مصادر مجمَّعة معاً
/// (`getProjectDashboard` + `getProjectTasks` + `getCompanyEquipment`
/// المصفّاة حسب المشروع)، وتُخزَّن ضمن
/// [AnalyticsData.projectSummaries] بدل إعادة حساب هذه القيم في كل
/// مرة تُطلَب فيها (`kpi_summary_row.dart`/`project_progress_chart.dart`/
/// `project_analytics.dart` تستهلكها معاً).
///
/// ⚠️ قرار تصميم مهم (نسبة الإنجاز مُشتقّة، لا مخزَّنة): عقد
/// `IProjectRepository.getProjectDashboard` (Prompt 06/10) لا يُعيد
/// أي حقل "نسبة إنجاز" جاهزة — فقط `openTasksCount`/`openPunchItemsCount`/
/// `projectMembersCount`/`todayAttendanceCount`/`todayAttendanceRate`
/// (انظر `data/cloud/supabase/queries/dashboard_queries.dart`). لذا
/// [progressPercent] هنا محسوبة محلياً في `AnalyticsCubit.loadInitial`
/// من نسبة المهام المكتملة ([TaskStatus.done]) إلى إجمالي مهام
/// المشروع (`GetProjectTasksUsecase`) — توسيع طبقة `data/` لإضافة
/// حقل جاهز خارج نطاق Prompt 25 هذا، بنفس منطق قيود `EquipmentData`
/// الموثَّقة في Prompt 22 (`usageLogByEquipmentId`).
class ProjectAnalyticsSummary {
  const ProjectAnalyticsSummary({
    required this.project,
    required this.openTasksCount,
    required this.completedTasksCount,
    required this.totalTasksCount,
    required this.openPunchItemsCount,
    required this.projectMembersCount,
    required this.todayAttendanceCount,
    required this.todayAttendanceRate,
  });

  final Project project;
  final int openTasksCount;
  final int completedTasksCount;
  final int totalTasksCount;
  final int openPunchItemsCount;
  final int projectMembersCount;
  final int todayAttendanceCount;

  /// نسبة (0.0–1.0) مأخوذة مباشرة من `dashboard['todayAttendanceRate']`.
  final double todayAttendanceRate;

  /// نسبة إنجاز المشروع (0–100) — انظر توثيق القرار الكامل أعلى الصنف.
  double get progressPercent {
    if (totalTasksCount == 0) return 0;
    return (completedTasksCount / totalTasksCount) * 100;
  }
}

/// حالة `AnalyticsCubit` الكاملة — Union Type مكتوب يدوياً (`sealed
/// class` + تفريغ أنماط `switch`)، بنفس نمط `ProjectsState`/
/// `EquipmentState` تماماً (بلا `freezed`)، لكن بخمس حالات بدل ثلاث
/// (بنفس سابقة `AuthState`، `features/auth/`): [AnalyticsInitial] /
/// [AnalyticsLoading] / [AnalyticsLoaded] / [AnalyticsError] /
/// [AnalyticsExporting].
///
/// ⚠️ قرار تصميم (`AnalyticsExporting` حالة مستقلة، لا علماً بوليانياً
/// ضمن [AnalyticsData]): بخلاف أعلام "عملية جارية" المعتادة
/// (`ProjectsData.isSubmitting`، `EquipmentData.isAssigning`...)، عملية
/// التصدير هنا حالة تنقّل واجهة مستقلة بذاتها (تعرض شاشة/حوار تقدّم
/// مخصّص فوق لوحة التحليلات كاملة، وليس مجرد تعطيل زر واحد) — الأمر
/// الذي يبرر رفعها لمستوى [AnalyticsState] العلوي مباشرة، بنفس تبرير
/// `AuthNeedsCompanySelection` (حالة تنقّل مستقلة أيضاً) في
/// `features/auth/`. تحمل [AnalyticsExporting] نسخة [AnalyticsData]
/// نفسها (لا تُفرَّغ الشاشة أثناء التصدير) بالإضافة إلى
/// [AnalyticsExportKind] المحدِّد لنوع العملية الجارية.
sealed class AnalyticsState {
  const AnalyticsState();

  /// تفريغ أنماط شامل (Exhaustive) — كل الحالات الخمس إلزامية.
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(AnalyticsData data) loaded,
    required T Function(Failure failure) error,
    required T Function(AnalyticsData data, AnalyticsExportKind kind)
        exporting,
  }) {
    final AnalyticsState state = this;
    return switch (state) {
      AnalyticsInitial() => initial(),
      AnalyticsLoading() => loading(),
      AnalyticsLoaded(:final data) => loaded(data),
      AnalyticsError(:final failure) => error(failure),
      AnalyticsExporting(:final data, :final kind) => exporting(data, kind),
    };
  }

  /// تفريغ أنماط جزئي — كل الحالات اختيارية، مع [orElse] إلزامي.
  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(AnalyticsData data)? loaded,
    T Function(Failure failure)? error,
    T Function(AnalyticsData data, AnalyticsExportKind kind)? exporting,
  }) {
    return when<T>(
      initial: initial ?? orElse,
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
      exporting: exporting ?? (_, __) => orElse(),
    );
  }

  /// [AnalyticsData] الحالية إن كانت الحالة [AnalyticsLoaded] أو
  /// [AnalyticsExporting] (كلتاهما تحملان بيانات جاهزة للعرض)، أو
  /// `null` خلاف ذلك — مختصر مفيد للشاشات، بنفس نمط
  /// `ProjectsState.dataOrNull`.
  AnalyticsData? get dataOrNull => maybeWhen<AnalyticsData?>(
        orElse: () => null,
        loaded: (AnalyticsData d) => d,
        exporting: (AnalyticsData d, AnalyticsExportKind _) => d,
      );

  /// صحيح فقط أثناء [AnalyticsExporting] — مختصر لتعطيل أزرار التصدير
  /// وعرض مؤشر تقدّم دون الحاجة لتفريغ الحالة بالكامل في كل شاشة.
  bool get isExporting => this is AnalyticsExporting;
}

/// الحالة الأولية قبل أي استدعاء لـ [AnalyticsCubit.loadInitial] —
/// بنفس سابقة `AuthInitial` (`features/auth/`)، بخلاف بقية Cubits
/// الميزات (`ProjectsCubit`/`EquipmentCubit`...) التي تبدأ مباشرة من
/// حالة `Loading` مكافئة؛ [AnalyticsCubit] يُنشَأ مبكراً عبر `sl<...>()`
/// من `analytics_dashboard.dart` وقد يمر لحظة عابرة قبل استدعاء
/// `loadHome`/`loadInitial(user)` الفعلي من `initState`.
final class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

/// جارٍ التحميل الأولي الكامل (مشاريع الشركة + لوحات تحكّم كل مشروع +
/// مهامه + حضوره ضمن المدى الافتراضي + معدات الشركة).
final class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

/// جاهزة لعرض كل شاشات الميزة (`analytics_dashboard.dart`،
/// `project_analytics.dart`، `attendance_analytics.dart`،
/// `export_analytics_screen.dart`) — الفرق بينها بصري بحت، بنفس فلسفة
/// `ProjectsCubit`/`EquipmentCubit`.
final class AnalyticsLoaded extends AnalyticsState {
  const AnalyticsLoaded(this.data);

  final AnalyticsData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً — يعتمد `Retry` في الشاشة
/// لإعادة `AnalyticsCubit.loadInitial`.
final class AnalyticsError extends AnalyticsState {
  const AnalyticsError(this.failure);

  final Failure failure;
}

/// عملية تصدير جارية حالياً (PDF أو صورة قسم واحد) — انظر توثيق
/// القرار الكامل أعلى [AnalyticsState].
final class AnalyticsExporting extends AnalyticsState {
  const AnalyticsExporting(this.data, this.kind);

  final AnalyticsData data;
  final AnalyticsExportKind kind;
}

/// حزمة بيانات ميزة التحليلات المجمّعة — يحملها [AnalyticsLoaded]/
/// [AnalyticsExporting] معاً.
///
/// ⚠️ قرار تصميم (بيانات خام + دوال اشتقاق، لا حقول مُحسَبة مخزَّنة):
/// بنفس فلسفة `EquipmentData.filteredEquipment`/`maintenanceDueEquipment`
/// (Prompt 22) — تُخزَّن هنا فقط البيانات الخام المجلوبة من الشبكة
/// ([companyProjects]/[projectSummaries]/[attendanceByProjectId]/
/// [companyEquipment])، وكل ما تحتاجه الودجات (KPIs المجمّعة، توزيع
/// حالات المهام، سلسلة اتجاه الحضور الزمنية...) يُشتقّ عند الطلب عبر
/// Getters/دوال على هذا الصنف — يتجنّب ذلك الحاجة لإعادة مزامنة نسختين
/// من نفس الرقم (خام ومُجمَّع) عند أي تحديث جزئي لاحق.
class AnalyticsData {
  const AnalyticsData({
    required this.currentUser,
    required this.rangeFrom,
    required this.rangeTo,
    this.companyProjects = const <Project>[],
    this.projectSummaries = const <String, ProjectAnalyticsSummary>{},
    this.tasksByProjectId = const <String, List<Task>>{},
    this.attendanceByProjectId = const <String, List<AttendanceRecord>>{},
    this.companyEquipment = const <Equipment>[],
    this.selectedProjectId,
    this.isRefreshingRange = false,
  });

  final AppUser currentUser;

  /// كل مشاريع الشركة (`GetMyProjectsUsecase` تُعيد نطاقاً كاملاً
  /// للأدوار الإدارية — انظر توثيق `IProjectRepository.getMyProjects`)
  /// — أساس كل شاشات الميزة.
  final List<Project> companyProjects;

  /// مؤشرات كل مشروع مجمّعة مسبقاً — مفتاح الخريطة هو [Project.id].
  final Map<String, ProjectAnalyticsSummary> projectSummaries;

  /// مهام كل مشروع خام (المصدر الذي يُبنى منه توزيع حالات المهام،
  /// إجمالياً عبر [taskStatusDistribution] أو لمشروع واحد عبر
  /// [taskStatusDistributionFor]) — مفتاح الخريطة [Project.id].
  final Map<String, List<Task>> tasksByProjectId;

  /// سجلات حضور كل مشروع ضمن [rangeFrom]–[rangeTo] الحالي (تُعاد
  /// مزامنتها عند [AnalyticsCubit.setDateRange] فقط، دون بقية
  /// البيانات) — مفتاح الخريطة [Project.id].
  final Map<String, List<AttendanceRecord>> attendanceByProjectId;

  /// معدات الشركة الكاملة (بلا فلترة مشروع — `GetCompanyEquipmentUsecase()`
  /// بلا `projectId`) — أساس مؤشر "معدات قيد الصيانة" وتوزيع المعدات
  /// حسب المشروع عبر [equipmentForProject].
  final List<Equipment> companyEquipment;

  /// مدى التاريخ الحالي المعروض في `date_range_filter.dart` وسلاسل
  /// `attendance_trend_chart.dart` — 30 يوماً افتراضياً عند
  /// [AnalyticsCubit.loadInitial].
  final DateTime rangeFrom;
  final DateTime rangeTo;

  /// المشروع المختار حالياً ضمن `project_analytics.dart` — تصفية
  /// عرض بحتة (بلا استدعاء شبكة إضافي، كل البيانات محمَّلة مسبقاً
  /// ضمن [projectSummaries]/[tasksByProjectId]/[attendanceByProjectId]).
  final String? selectedProjectId;

  /// صحيح فقط أثناء إعادة تحميل سجلات الحضور بعد تغيير المدى الزمني
  /// (`AnalyticsCubit.setDateRange`) — لا يُغيّر [AnalyticsState]
  /// العلوية (يبقى `AnalyticsLoaded`) لأن كل بيانات اللوحة الأخرى
  /// (المشاريع، المهام، المعدات) تبقى معروضة بلا انقطاع أثناء هذه
  /// العملية الجزئية.
  final bool isRefreshingRange;

  Project? get selectedProject {
    final String? id = selectedProjectId;
    if (id == null) return null;
    for (final Project p in companyProjects) {
      if (p.id == id) return p;
    }
    return null;
  }

  ProjectAnalyticsSummary? get selectedProjectSummary =>
      selectedProjectId == null ? null : projectSummaries[selectedProjectId];

  List<Project> get activeProjects => companyProjects
      .where((Project p) => p.status.isActive)
      .toList(growable: false);

  int get activeProjectsCount =>
      companyProjects.where((Project p) => p.status.isActive).length;

  /// متوسط نسبة إنجاز كل مشاريع الشركة — `kpi_summary_row.dart`.
  double get averageProgressPercent {
    if (projectSummaries.isEmpty) return 0;
    final double sum = projectSummaries.values
        .fold<double>(0, (double acc, ProjectAnalyticsSummary s) => acc + s.progressPercent);
    return sum / projectSummaries.length;
  }

  int get totalOpenTasksCount => projectSummaries.values
      .fold<int>(0, (int acc, ProjectAnalyticsSummary s) => acc + s.openTasksCount);

  int get totalOpenPunchItemsCount => projectSummaries.values.fold<int>(
        0,
        (int acc, ProjectAnalyticsSummary s) => acc + s.openPunchItemsCount,
      );

  int get totalTeamMembersCount => projectSummaries.values.fold<int>(
        0,
        (int acc, ProjectAnalyticsSummary s) => acc + s.projectMembersCount,
      );

  int get totalTodayAttendanceCount => projectSummaries.values.fold<int>(
        0,
        (int acc, ProjectAnalyticsSummary s) => acc + s.todayAttendanceCount,
      );

  /// متوسط بسيط لنسب حضور اليوم عبر كل المشاريع (0.0–1.0) —
  /// `kpi_summary_row.dart`.
  double get averageTodayAttendanceRate {
    if (projectSummaries.isEmpty) return 0;
    final double sum = projectSummaries.values.fold<double>(
      0,
      (double acc, ProjectAnalyticsSummary s) => acc + s.todayAttendanceRate,
    );
    return sum / projectSummaries.length;
  }

  int get equipmentInMaintenanceCount => companyEquipment
      .where((Equipment e) => e.status == EquipmentStatus.maintenance)
      .length;

  int get equipmentInUseCount => companyEquipment
      .where((Equipment e) => e.status == EquipmentStatus.inUse)
      .length;

  List<Equipment> equipmentForProject(String projectId) => companyEquipment
      .where((Equipment e) => e.projectId == projectId)
      .toList(growable: false);

  /// قائمة (اسم المشروع، نسبة الإنجاز) مرتَّبة تنازلياً — أساس
  /// `project_progress_chart.dart` (BarChart).
  List<MapEntry<Project, double>> get projectProgressList {
    final List<MapEntry<Project, double>> entries = companyProjects
        .map(
          (Project p) => MapEntry<Project, double>(
            p,
            projectSummaries[p.id]?.progressPercent ?? 0,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// توزيع حالات المهام عبر **كل** مشاريع الشركة معاً — أساس
  /// `task_distribution_chart.dart` (PieChart) في `analytics_dashboard.dart`.
  Map<TaskStatus, int> get taskStatusDistribution =>
      taskStatusDistributionFor(null);

  /// توزيع حالات المهام لمشروع واحد محدَّد ([projectId]) أو لكل
  /// المشاريع معاً عند تمرير `null` — يُستخدم من `project_analytics.dart`
  /// (لوحة تفصيلية لمشروع واحد) و`analytics_dashboard.dart` (عام) معاً
  /// عبر نفس الدالة، بدل حقلين منفصلين مكرَّرين.
  Map<TaskStatus, int> taskStatusDistributionFor(String? projectId) {
    final Map<TaskStatus, int> distribution = <TaskStatus, int>{
      for (final TaskStatus status in TaskStatus.values) status: 0,
    };

    final Iterable<List<Task>> sources = projectId == null
        ? tasksByProjectId.values
        : <List<Task>>[tasksByProjectId[projectId] ?? const <Task>[]];

    for (final List<Task> tasks in sources) {
      for (final Task task in tasks) {
        distribution[task.status] = (distribution[task.status] ?? 0) + 1;
      }
    }
    return distribution;
  }

  /// سلسلة اتجاه الحضور اليومي عبر **كل** المشاريع معاً ضمن
  /// [rangeFrom]–[rangeTo] الحالي — أساس `attendance_trend_chart.dart`
  /// في `analytics_dashboard.dart`/`attendance_analytics.dart`.
  List<AttendanceTrendPoint> get attendanceTrend =>
      attendanceTrendFor(null);

  /// نفس [attendanceTrend] لكن لمشروع واحد محدَّد فقط عند تمرير
  /// [projectId] — `project_analytics.dart`.
  List<AttendanceTrendPoint> attendanceTrendFor(String? projectId) {
    final Iterable<List<AttendanceRecord>> sources = projectId == null
        ? attendanceByProjectId.values
        : <List<AttendanceRecord>>[
            attendanceByProjectId[projectId] ?? const <AttendanceRecord>[],
          ];

    final Map<DateTime, int> countsByDay = <DateTime, int>{};
    for (final List<AttendanceRecord> records in sources) {
      for (final AttendanceRecord record in records) {
        final DateTime local = record.checkInAt.toLocal();
        final DateTime day = DateTime(local.year, local.month, local.day);
        countsByDay[day] = (countsByDay[day] ?? 0) + 1;
      }
    }

    final DateTime fromDay =
        DateTime(rangeFrom.year, rangeFrom.month, rangeFrom.day);
    final DateTime toDay = DateTime(rangeTo.year, rangeTo.month, rangeTo.day);
    final int dayCount = toDay.difference(fromDay).inDays;

    return <AttendanceTrendPoint>[
      for (int i = 0; i <= dayCount; i++)
        AttendanceTrendPoint(
          date: fromDay.add(Duration(days: i)),
          presentCount: countsByDay[fromDay.add(Duration(days: i))] ?? 0,
        ),
    ];
  }

  AnalyticsData copyWith({
    AppUser? currentUser,
    List<Project>? companyProjects,
    Map<String, ProjectAnalyticsSummary>? projectSummaries,
    Map<String, List<Task>>? tasksByProjectId,
    Map<String, List<AttendanceRecord>>? attendanceByProjectId,
    List<Equipment>? companyEquipment,
    DateTime? rangeFrom,
    DateTime? rangeTo,
    String? selectedProjectId,
    bool clearSelectedProjectId = false,
    bool? isRefreshingRange,
  }) {
    return AnalyticsData(
      currentUser: currentUser ?? this.currentUser,
      companyProjects: companyProjects ?? this.companyProjects,
      projectSummaries: projectSummaries ?? this.projectSummaries,
      tasksByProjectId: tasksByProjectId ?? this.tasksByProjectId,
      attendanceByProjectId:
          attendanceByProjectId ?? this.attendanceByProjectId,
      companyEquipment: companyEquipment ?? this.companyEquipment,
      rangeFrom: rangeFrom ?? this.rangeFrom,
      rangeTo: rangeTo ?? this.rangeTo,
      selectedProjectId: clearSelectedProjectId
          ? null
          : (selectedProjectId ?? this.selectedProjectId),
      isRefreshingRange: isRefreshingRange ?? this.isRefreshingRange,
    );
  }
}
