import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/punch_item.dart';
import '../../../../domain/enums/punch_status.dart';

/// حالة `PunchCubit` الكاملة — Union Type مكتوب يدوياً (`sealed class`
/// + تفريغ أنماط `switch`)، بنفس نمط `tasks_state.dart`/`attendance_state.dart`
/// تماماً (بلا `freezed`). ثلاث حالات فقط بنفس فلسفة [TasksState]:
/// `PunchLoading` / `PunchLoaded` / `PunchError`.
sealed class PunchState {
  const PunchState();

  /// تفريغ أنماط شامل (Exhaustive) — كل الحالات الثلاث إلزامية.
  T when<T>({
    required T Function() loading,
    required T Function(PunchData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final PunchState state = this;
    return switch (state) {
      PunchLoading() => loading(),
      PunchLoaded(:final data) => loaded(data),
      PunchError(:final failure) => error(failure),
    };
  }

  /// تفريغ أنماط جزئي — كل الحالات اختيارية، مع [orElse] إلزامي.
  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(PunchData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [PunchData] الحالية إن كانت الحالة [PunchLoaded]، أو `null` —
  /// مختصر مفيد للشاشات التي تحتاج قراءة آخر بيانات معروفة دون تفريغ
  /// أنماط كامل في كل مكان.
  PunchData? get dataOrNull =>
      maybeWhen<PunchData?>(orElse: () => null, loaded: (PunchData d) => d);
}

/// جارٍ التحميل الأولي (تحديد المشروع الحالي + جلب عناصر Punch List
/// الخاصة به).
final class PunchLoading extends PunchState {
  const PunchLoading();
}

/// جاهزة لعرض كل شاشات الميزة — تفصيل التحميلات الجزئية اللاحقة (لوحة
/// المتابعة على سطح المكتب عبر كل المشاريع...) داخل [PunchData] نفسها.
final class PunchLoaded extends PunchState {
  const PunchLoaded(this.data);

  final PunchData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً (مثال: فشل تحديد المشروع
/// الحالي أو جلب عناصر المشروع). يعتمد `Retry` في الشاشة لإعادة
/// [PunchCubit.loadInitial].
final class PunchError extends PunchState {
  const PunchError(this.failure);

  final Failure failure;
}

/// حزمة بيانات ميزة قوائم الملاحظات المجمّعة — يحملها [PunchLoaded]
/// وحدها، بنفس نمط `TasksData`/`AttendanceData`.
class PunchData {
  const PunchData({
    required this.currentUser,
    this.project,
    this.items = const <PunchItem>[],
    this.isItemsLoading = false,
    this.myProjects = const <Project>[],
    this.projectsById = const <String, Project>{},
    this.dashboardItems = const <PunchItem>[],
    this.isDashboardLoading = false,
    this.statusFilter,
    this.searchQuery = '',
    this.isSubmitting = false,
    this.isClosing = false,
  });

  final AppUser currentUser;

  /// المشروع الحالي (أول مشروع نشط ضمن مشاريع المستخدم — نفس منطق
  /// `AttendanceCubit.loadInitial`/`TasksCubit.loadInitial`)، أو
  /// `null` إن لم يملك المستخدم أي مشروع بعد.
  final Project? project;

  /// عناصر Punch List الخاصة بـ [project] فقط (`GetProjectPunchItemsUsecase`)
  /// — `punch_list_screen.dart` (الهاتف) و`punch_item_manage.dart`
  /// (سطح المكتب، عند اختيار مشروع واحد للإدارة).
  final List<PunchItem> items;
  final bool isItemsLoading;

  /// كل مشاريع المستخدم — تُجلب مرة واحدة فقط عبر [PunchCubit.loadDashboard]
  /// لتغذية `punch_dashboard.dart` (سطح المكتب) التي تحتاج عرض عيوب
  /// *كل* المشاريع معاً وليس مشروعاً واحداً فقط، بخلاف بقية شاشات
  /// الميزة. [projectsById] يرافقها لعرض اسم المشروع أمام كل صف في
  /// اللوحة دون بحث خطي متكرر.
  final List<Project> myProjects;
  final Map<String, Project> projectsById;

  /// عيوب مفتوحة (`!status.isClosed`) عبر كل [myProjects] معاً، مُجمَّعة
  /// ومرتّبة زمنياً من الأقدم للأحدث (`createdAt` تصاعدياً) — أساس
  /// `punch_dashboard.dart` مباشرة. فارغة حتى يُستدعى
  /// [PunchCubit.loadDashboard] صراحة (تحميل كسول، بنفس نمط
  /// `AttendanceCubit.loadMonitor`/`TasksCubit.loadBoard`).
  final List<PunchItem> dashboardItems;
  final bool isDashboardLoading;

  // ── تصفية (`punch_status_filter.dart`) ──────────────────────────
  final PunchStatus? statusFilter;
  final String searchQuery;

  /// عملية إنشاء عنصر جديد جارية حالياً — `punch_item_create.dart`.
  final bool isSubmitting;

  /// عملية إغلاق عنصر جارية حالياً — `punch_close_form.dart`.
  final bool isClosing;

  bool get hasActiveFilters =>
      statusFilter != null || searchQuery.trim().isNotEmpty;

  List<PunchItem> _applyFilters(List<PunchItem> source) {
    final String query = searchQuery.trim().toLowerCase();
    return source.where((PunchItem item) {
      if (statusFilter != null && item.status != statusFilter) return false;
      if (query.isNotEmpty &&
          !item.title.toLowerCase().contains(query) &&
          !(item.description?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// [items] بعد تطبيق التصفية الحالية — `punch_list_screen.dart`.
  List<PunchItem> get filteredItems => _applyFilters(items);

  int get openCount =>
      items.where((PunchItem i) => i.status == PunchStatus.open).length;
  int get inProgressCount =>
      items.where((PunchItem i) => i.status == PunchStatus.inProgress).length;
  int get closedCount =>
      items.where((PunchItem i) => i.status.isClosed).length;

  /// عدد العيوب المفتوحة عبر كل المشاريع المتأخرة عن `dueDate` —
  /// مؤشر أداء ضمن بطاقات `punch_dashboard.dart` العلوية.
  int get overdueDashboardCount {
    final DateTime now = DateTime.now();
    return dashboardItems
        .where((PunchItem i) => i.dueDate != null && i.dueDate!.isBefore(now))
        .length;
  }

  PunchData copyWith({
    AppUser? currentUser,
    Project? project,
    bool clearProject = false,
    List<PunchItem>? items,
    bool? isItemsLoading,
    List<Project>? myProjects,
    Map<String, Project>? projectsById,
    List<PunchItem>? dashboardItems,
    bool? isDashboardLoading,
    PunchStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    bool? isSubmitting,
    bool? isClosing,
  }) {
    return PunchData(
      currentUser: currentUser ?? this.currentUser,
      project: clearProject ? null : (project ?? this.project),
      items: items ?? this.items,
      isItemsLoading: isItemsLoading ?? this.isItemsLoading,
      myProjects: myProjects ?? this.myProjects,
      projectsById: projectsById ?? this.projectsById,
      dashboardItems: dashboardItems ?? this.dashboardItems,
      isDashboardLoading: isDashboardLoading ?? this.isDashboardLoading,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isClosing: isClosing ?? this.isClosing,
    );
  }
}
