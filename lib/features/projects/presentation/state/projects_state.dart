import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/project_member_detail.dart';
import '../../../../domain/entities/project_milestone.dart';
import '../../../../domain/enums/project_status.dart';

/// حالة `ProjectsCubit` الكاملة — Union Type مكتوب يدوياً (`sealed class`
/// + تفريغ أنماط `switch`)، بنفس نمط `punch_state.dart`/`tasks_state.dart`
/// تماماً (بلا `freezed`). ثلاث حالات: `ProjectsLoading` / `ProjectsLoaded`
/// / `ProjectsError`.
sealed class ProjectsState {
  const ProjectsState();

  /// تفريغ أنماط شامل (Exhaustive) — كل الحالات الثلاث إلزامية.
  T when<T>({
    required T Function() loading,
    required T Function(ProjectsData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final ProjectsState state = this;
    return switch (state) {
      ProjectsLoading() => loading(),
      ProjectsLoaded(:final data) => loaded(data),
      ProjectsError(:final failure) => error(failure),
    };
  }

  /// تفريغ أنماط جزئي — كل الحالات اختيارية، مع [orElse] إلزامي.
  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(ProjectsData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [ProjectsData] الحالية إن كانت الحالة [ProjectsLoaded]، أو `null`.
  ProjectsData? get dataOrNull => maybeWhen<ProjectsData?>(
        orElse: () => null,
        loaded: (ProjectsData d) => d,
      );
}

/// جارٍ التحميل الأولي (مشاريع المستخدم الحالي).
final class ProjectsLoading extends ProjectsState {
  const ProjectsLoading();
}

/// جاهزة لعرض كل شاشات الميزة (قائمة الهاتف، جدول سطح المكتب، نظرة
/// عامة/تفاصيل مشروع محدد، الأعضاء، المراحل، الإعدادات) — تفصيل
/// التحميلات الجزئية اللاحقة داخل [ProjectsData] نفسها.
final class ProjectsLoaded extends ProjectsState {
  const ProjectsLoaded(this.data);

  final ProjectsData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً (مثال: فشل جلب مشاريع
/// المستخدم). يعتمد `Retry` في الشاشة لإعادة [ProjectsCubit.loadInitial].
final class ProjectsError extends ProjectsState {
  const ProjectsError(this.failure);

  final Failure failure;
}

/// حزمة بيانات ميزة المشاريع المجمّعة — يحملها [ProjectsLoaded] وحدها،
/// بنفس نمط `PunchData`/`TasksData`.
class ProjectsData {
  const ProjectsData({
    required this.currentUser,
    this.myProjects = const <Project>[],
    this.selectedProject,
    this.dashboard = const <String, num>{},
    this.isDashboardLoading = false,
    this.members = const <ProjectMemberDetail>[],
    this.isMembersLoading = false,
    this.availableMembers = const <AppUser>[],
    this.isAvailableMembersLoading = false,
    this.milestones = const <ProjectMilestone>[],
    this.isMilestonesLoading = false,
    this.searchQuery = '',
    this.statusFilter,
    this.isSubmitting = false,
    this.isMemberActionInProgress = false,
    this.isMilestoneActionInProgress = false,
  });

  final AppUser currentUser;

  /// كل مشاريع المستخدم — أساس `my_projects_screen.dart` (الهاتف)
  /// و`projects_list.dart` (سطح المكتب) معاً.
  final List<Project> myProjects;

  /// المشروع المُختار حالياً — `project_overview.dart` (الهاتف)،
  /// `project_details.dart`/`project_members.dart`/`project_milestones.dart`/
  /// `project_settings.dart` (سطح المكتب) كلها تعتمد عليه.
  final Project? selectedProject;

  /// بيانات لوحة تحكّم [selectedProject] المجمّعة
  /// (`IProjectRepository.getProjectDashboard`) — `project_overview.dart`/
  /// `project_details.dart`.
  final Map<String, num> dashboard;
  final bool isDashboardLoading;

  /// فريق عمل [selectedProject] — `project_members.dart`.
  final List<ProjectMemberDetail> members;
  final bool isMembersLoading;

  /// أعضاء الشركة القابلين للإضافة لـ [selectedProject] (غير مُسندين
  /// بعد) — `member_role_selector.dart`.
  final List<AppUser> availableMembers;
  final bool isAvailableMembersLoading;

  /// مراحل [selectedProject] الرئيسية — `project_milestones.dart`/
  /// `project_overview.dart`.
  final List<ProjectMilestone> milestones;
  final bool isMilestonesLoading;

  // ── تصفية/بحث `my_projects_screen.dart`/`projects_list.dart` ────
  final String searchQuery;
  final ProjectStatus? statusFilter;

  /// عملية إنشاء/تحديث مشروع جارية حالياً — `project_settings.dart`.
  final bool isSubmitting;

  /// عملية إضافة/إزالة عضو جارية حالياً — `project_members.dart`.
  final bool isMemberActionInProgress;

  /// عملية إنشاء/تحديث/حذف مرحلة جارية حالياً — `project_milestones.dart`.
  final bool isMilestoneActionInProgress;

  bool get hasActiveFilters =>
      statusFilter != null || searchQuery.trim().isNotEmpty;

  List<Project> _applyFilters(List<Project> source) {
    final String query = searchQuery.trim().toLowerCase();
    return source.where((Project p) {
      if (statusFilter != null && p.status != statusFilter) return false;
      if (query.isNotEmpty &&
          !p.name.toLowerCase().contains(query) &&
          !(p.code?.toLowerCase().contains(query) ?? false) &&
          !(p.clientName?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// [myProjects] بعد تطبيق التصفية/البحث الحالية — `my_projects_screen.dart`/
  /// `projects_list.dart`.
  List<Project> get filteredProjects => _applyFilters(myProjects);

  int get activeProjectsCount =>
      myProjects.where((Project p) => p.status.isActive).length;

  /// المراحل القادمة غير المكتملة لـ [selectedProject]، مرتّبة زمنياً
  /// — `project_overview.dart` (الهاتف).
  List<ProjectMilestone> get upcomingMilestones {
    final List<ProjectMilestone> incomplete = milestones
        .where((ProjectMilestone m) => !m.status.isCompleted)
        .toList(growable: false)
      ..sort((ProjectMilestone a, ProjectMilestone b) {
        final DateTime aDate = a.dueDate ?? DateTime(9999);
        final DateTime bDate = b.dueDate ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
    return incomplete;
  }

  ProjectsData copyWith({
    AppUser? currentUser,
    List<Project>? myProjects,
    Project? selectedProject,
    bool clearSelectedProject = false,
    Map<String, num>? dashboard,
    bool? isDashboardLoading,
    List<ProjectMemberDetail>? members,
    bool? isMembersLoading,
    List<AppUser>? availableMembers,
    bool? isAvailableMembersLoading,
    List<ProjectMilestone>? milestones,
    bool? isMilestonesLoading,
    String? searchQuery,
    ProjectStatus? statusFilter,
    bool clearStatusFilter = false,
    bool? isSubmitting,
    bool? isMemberActionInProgress,
    bool? isMilestoneActionInProgress,
  }) {
    return ProjectsData(
      currentUser: currentUser ?? this.currentUser,
      myProjects: myProjects ?? this.myProjects,
      selectedProject: clearSelectedProject
          ? null
          : (selectedProject ?? this.selectedProject),
      dashboard: dashboard ?? this.dashboard,
      isDashboardLoading: isDashboardLoading ?? this.isDashboardLoading,
      members: members ?? this.members,
      isMembersLoading: isMembersLoading ?? this.isMembersLoading,
      availableMembers: availableMembers ?? this.availableMembers,
      isAvailableMembersLoading:
          isAvailableMembersLoading ?? this.isAvailableMembersLoading,
      milestones: milestones ?? this.milestones,
      isMilestonesLoading: isMilestonesLoading ?? this.isMilestonesLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isMemberActionInProgress:
          isMemberActionInProgress ?? this.isMemberActionInProgress,
      isMilestoneActionInProgress:
          isMilestoneActionInProgress ?? this.isMilestoneActionInProgress,
    );
  }
}
