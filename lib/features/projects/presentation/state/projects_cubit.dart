import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/project_member_detail.dart';
import '../../../../domain/entities/project_milestone.dart';
import '../../../../domain/enums/milestone_status.dart';
import '../../../../domain/enums/project_status.dart';
import '../../../../domain/usecases/projects/add_project_member_usecase.dart';
import '../../../../domain/usecases/projects/create_milestone_usecase.dart';
import '../../../../domain/usecases/projects/create_project_usecase.dart';
import '../../../../domain/usecases/projects/delete_milestone_usecase.dart';
import '../../../../domain/usecases/projects/get_available_company_members_usecase.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import '../../../../domain/usecases/projects/get_project_by_id_usecase.dart';
import '../../../../domain/usecases/projects/get_project_dashboard_usecase.dart';
import '../../../../domain/usecases/projects/get_project_members_usecase.dart';
import '../../../../domain/usecases/projects/get_project_milestones_usecase.dart';
import '../../../../domain/usecases/projects/remove_project_member_usecase.dart';
import '../../../../domain/usecases/projects/update_milestone_usecase.dart';
import '../../../../domain/usecases/projects/update_project_usecase.dart';
import 'projects_state.dart';

/// `Cubit` ميزة `features/projects/` (Prompt 20) — يقود كل شاشات الميزة
/// (قائمة "مشاريعي" على الهاتف، جدول إداري على سطح المكتب، نظرة عامة/
/// تفاصيل مشروع محدد، إدارة الفريق، المراحل، الإعدادات) عبر [ProjectsData]
/// واحدة مجمّعة، بنفس فلسفة `PunchCubit`/`TasksCubit` تماماً.
///
/// ⚠️ قرار تصميم: بخلاف `PunchCubit` (يحدّد "المشروع الحالي" تلقائياً
/// عند [loadInitial])، هذه الميزة تعرض *كل* مشاريع المستخدم كقائمة أولاً
/// (`my_projects_screen.dart`/`projects_list.dart`) ثم تنتظر اختياراً
/// صريحاً عبر [selectProject] — منطقي لميزة موضوعها بالذات "المشاريع"
/// نفسها (لا مشروعاً حالياً واحداً مفترضاً كسياق لميزة أخرى).
class ProjectsCubit extends Cubit<ProjectsState> {
  ProjectsCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required GetProjectByIdUsecase getProjectByIdUsecase,
    required GetProjectDashboardUsecase getProjectDashboardUsecase,
    required CreateProjectUsecase createProjectUsecase,
    required UpdateProjectUsecase updateProjectUsecase,
    required GetProjectMembersUsecase getProjectMembersUsecase,
    required GetAvailableCompanyMembersUsecase getAvailableCompanyMembersUsecase,
    required AddProjectMemberUsecase addProjectMemberUsecase,
    required RemoveProjectMemberUsecase removeProjectMemberUsecase,
    required GetProjectMilestonesUsecase getProjectMilestonesUsecase,
    required CreateMilestoneUsecase createMilestoneUsecase,
    required UpdateMilestoneUsecase updateMilestoneUsecase,
    required DeleteMilestoneUsecase deleteMilestoneUsecase,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _getProjectByIdUsecase = getProjectByIdUsecase,
        _getProjectDashboardUsecase = getProjectDashboardUsecase,
        _createProjectUsecase = createProjectUsecase,
        _updateProjectUsecase = updateProjectUsecase,
        _getProjectMembersUsecase = getProjectMembersUsecase,
        _getAvailableCompanyMembersUsecase = getAvailableCompanyMembersUsecase,
        _addProjectMemberUsecase = addProjectMemberUsecase,
        _removeProjectMemberUsecase = removeProjectMemberUsecase,
        _getProjectMilestonesUsecase = getProjectMilestonesUsecase,
        _createMilestoneUsecase = createMilestoneUsecase,
        _updateMilestoneUsecase = updateMilestoneUsecase,
        _deleteMilestoneUsecase = deleteMilestoneUsecase,
        super(const ProjectsLoading());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final GetProjectByIdUsecase _getProjectByIdUsecase;
  final GetProjectDashboardUsecase _getProjectDashboardUsecase;
  final CreateProjectUsecase _createProjectUsecase;
  final UpdateProjectUsecase _updateProjectUsecase;
  final GetProjectMembersUsecase _getProjectMembersUsecase;
  final GetAvailableCompanyMembersUsecase _getAvailableCompanyMembersUsecase;
  final AddProjectMemberUsecase _addProjectMemberUsecase;
  final RemoveProjectMemberUsecase _removeProjectMemberUsecase;
  final GetProjectMilestonesUsecase _getProjectMilestonesUsecase;
  final CreateMilestoneUsecase _createMilestoneUsecase;
  final UpdateMilestoneUsecase _updateMilestoneUsecase;
  final DeleteMilestoneUsecase _deleteMilestoneUsecase;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى مرة واحدة عند دخول `my_projects_screen.dart`/`projects_list.dart`:
  /// يجلب كل مشاريع المستخدم دون تحديد أي مشروع حالياً.
  Future<void> loadInitial(AppUser user) async {
    emit(const ProjectsLoading());

    final ResultOf<List<Project>> result =
        await _getMyProjectsUsecase(user.userId);

    result.fold(
      (Failure failure) => emit(ProjectsError(failure)),
      (List<Project> projects) => emit(
        ProjectsLoaded(ProjectsData(currentUser: user, myProjects: projects)),
      ),
    );
  }

  /// يعيد تحميل [ProjectsData.myProjects] فقط (سحب للتحديث).
  Future<void> refresh() async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return;

    final ResultOf<List<Project>> result =
        await _getMyProjectsUsecase(current.currentUser.userId);

    final ProjectsData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) {},
      (List<Project> projects) =>
          emit(ProjectsLoaded(latest.copyWith(myProjects: projects))),
    );
  }

  // ── تصفية/بحث (`my_projects_screen.dart`/`projects_list.dart`) ──

  void setStatusFilter(ProjectStatus? status) {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      ProjectsLoaded(
        current.copyWith(statusFilter: status, clearStatusFilter: status == null),
      ),
    );
  }

  void setSearchQuery(String query) {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return;
    emit(ProjectsLoaded(current.copyWith(searchQuery: query)));
  }

  void clearFilters() {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return;
    emit(ProjectsLoaded(current.copyWith(clearStatusFilter: true, searchQuery: '')));
  }

  // ── اختيار مشروع (`project_overview.dart`/`project_details.dart`) ─

  /// يختار مشروعاً — يبحث أولاً ضمن [ProjectsData.myProjects] المُحمَّلة
  /// مسبقاً (بلا استدعاء شبكة إضافي)، وعند عدم وجوده هناك (دخول مباشر
  /// عبر رابط عميق لمسار `/projects/:id` قبل تحميل القائمة كاملة) يجلبه
  /// صراحة عبر [GetProjectByIdUsecase]. يمسح كل بيانات المشروع المختار
  /// سابقاً (اللوحة، الأعضاء، المراحل) فوراً قبل التحميل الجديد لتفادي
  /// عرض بيانات مشروع سابق للحظة عابرة.
  Future<void> selectProject(String projectId) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return;

    final Project? cached = current.myProjects
        .where((Project p) => p.id == projectId)
        .cast<Project?>()
        .firstWhere((_) => true, orElse: () => null);

    emit(
      ProjectsLoaded(
        current.copyWith(
          selectedProject: cached,
          clearSelectedProject: cached == null,
          dashboard: const <String, num>{},
          members: const <ProjectMemberDetail>[],
          availableMembers: const <AppUser>[],
          milestones: const <ProjectMilestone>[],
        ),
      ),
    );

    Project? project = cached;
    if (project == null) {
      final ResultOf<Project> result = await _getProjectByIdUsecase(projectId);
      project = result.getOrNull();
      if (project == null) return;
      final ProjectsData latest = state.dataOrNull ?? current;
      emit(ProjectsLoaded(latest.copyWith(selectedProject: project)));
    }

    await Future.wait<void>(<Future<void>>[
      loadDashboard(projectId),
      loadMembers(projectId),
      loadMilestones(projectId),
    ]);
  }

  Future<void> loadDashboard(String projectId) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return;

    emit(ProjectsLoaded(current.copyWith(isDashboardLoading: true)));
    final ResultOf<Map<String, num>> result =
        await _getProjectDashboardUsecase(projectId);
    final ProjectsData latest = state.dataOrNull ?? current;
    emit(
      ProjectsLoaded(
        latest.copyWith(
          dashboard: result.fold((Failure _) => const <String, num>{}, (m) => m),
          isDashboardLoading: false,
        ),
      ),
    );
  }

  // ── إنشاء/تحديث مشروع (`project_settings.dart`) ─────────────────

  /// ينشئ مشروعاً جديداً ضمن شركة المستخدم الحالي. يُعيد المشروع
  /// المُنشأ عند النجاح، أو `null` عند الفشل.
  Future<Project?> createProject({
    required String name,
    String? nameAr,
    String? code,
    String? clientName,
    String? address,
    double? latitude,
    double? longitude,
    double geofenceRadiusMeters = 150,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return null;

    emit(ProjectsLoaded(current.copyWith(isSubmitting: true)));

    final DateTime now = DateTime.now().toUtc();
    final Project project = Project(
      id: IdGenerator.v4(),
      companyId: current.currentUser.companyId,
      name: name.trim(),
      nameAr: (nameAr == null || nameAr.trim().isEmpty) ? null : nameAr.trim(),
      code: (code == null || code.trim().isEmpty) ? null : code.trim(),
      clientName:
          (clientName == null || clientName.trim().isEmpty) ? null : clientName.trim(),
      address: (address == null || address.trim().isEmpty) ? null : address.trim(),
      latitude: latitude,
      longitude: longitude,
      geofenceRadiusMeters: geofenceRadiusMeters,
      startDate: startDate,
      endDate: endDate,
      status: ProjectStatus.active,
      description:
          (description == null || description.trim().isEmpty) ? null : description.trim(),
      createdBy: current.currentUser.userId,
      createdAt: now,
      updatedAt: now,
    );

    final ResultOf<Project> result = await _createProjectUsecase(project);
    final ProjectsData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(ProjectsLoaded(latest.copyWith(isSubmitting: false)));
        return null;
      },
      (Project created) {
        emit(
          ProjectsLoaded(
            latest.copyWith(
              myProjects: <Project>[created, ...latest.myProjects],
              isSubmitting: false,
            ),
          ),
        );
        return created;
      },
    );
  }

  /// يحدّث [ProjectsData.selectedProject] الحالي — `project_settings.dart`.
  Future<bool> updateSelectedProject(Project updated) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return false;

    emit(ProjectsLoaded(current.copyWith(isSubmitting: true)));
    final ResultOf<Project> result = await _updateProjectUsecase(updated);
    final ProjectsData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(ProjectsLoaded(latest.copyWith(isSubmitting: false)));
        return false;
      },
      (Project saved) {
        emit(
          ProjectsLoaded(
            latest.copyWith(
              selectedProject: saved,
              myProjects: latest.myProjects
                  .map((Project p) => p.id == saved.id ? saved : p)
                  .toList(growable: false),
              isSubmitting: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── إدارة الفريق (`project_members.dart`/`member_role_selector.dart`) ─

  Future<void> loadMembers(String projectId) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return;

    emit(ProjectsLoaded(current.copyWith(isMembersLoading: true)));
    final ResultOf<List<ProjectMemberDetail>> result =
        await _getProjectMembersUsecase(projectId);
    final ProjectsData latest = state.dataOrNull ?? current;
    emit(
      ProjectsLoaded(
        latest.copyWith(
          members: result.fold((Failure _) => const <ProjectMemberDetail>[], (m) => m),
          isMembersLoading: false,
        ),
      ),
    );
  }

  /// يجلب أعضاء الشركة القابلين للإضافة — يُستدعى عند فتح
  /// `member_role_selector.dart`.
  Future<void> loadAvailableMembers(String projectId) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return;

    emit(ProjectsLoaded(current.copyWith(isAvailableMembersLoading: true)));
    final ResultOf<List<AppUser>> result = await _getAvailableCompanyMembersUsecase(
      companyId: current.currentUser.companyId,
      projectId: projectId,
    );
    final ProjectsData latest = state.dataOrNull ?? current;
    emit(
      ProjectsLoaded(
        latest.copyWith(
          availableMembers: result.fold((Failure _) => const <AppUser>[], (m) => m),
          isAvailableMembersLoading: false,
        ),
      ),
    );
  }

  Future<bool> addMember({required String projectId, required String userId}) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return false;

    emit(ProjectsLoaded(current.copyWith(isMemberActionInProgress: true)));
    final ResultOf<ProjectMemberDetail> result = await _addProjectMemberUsecase(
      projectId: projectId,
      companyId: current.currentUser.companyId,
      userId: userId,
    );
    final ProjectsData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(ProjectsLoaded(latest.copyWith(isMemberActionInProgress: false)));
        return false;
      },
      (ProjectMemberDetail added) {
        emit(
          ProjectsLoaded(
            latest.copyWith(
              members: <ProjectMemberDetail>[...latest.members, added],
              availableMembers: latest.availableMembers
                  .where((AppUser u) => u.userId != added.user.userId)
                  .toList(growable: false),
              isMemberActionInProgress: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  Future<bool> removeMember(ProjectMemberDetail member) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return false;

    emit(ProjectsLoaded(current.copyWith(isMemberActionInProgress: true)));
    final ResultOf<void> result =
        await _removeProjectMemberUsecase(member.projectMemberId);
    final ProjectsData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(ProjectsLoaded(latest.copyWith(isMemberActionInProgress: false)));
        return false;
      },
      (_) {
        emit(
          ProjectsLoaded(
            latest.copyWith(
              members: latest.members
                  .where(
                    (ProjectMemberDetail m) =>
                        m.projectMemberId != member.projectMemberId,
                  )
                  .toList(growable: false),
              availableMembers: <AppUser>[...latest.availableMembers, member.user],
              isMemberActionInProgress: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── إدارة المراحل (`project_milestones.dart`) ────────────────────

  Future<void> loadMilestones(String projectId) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return;

    emit(ProjectsLoaded(current.copyWith(isMilestonesLoading: true)));
    final ResultOf<List<ProjectMilestone>> result =
        await _getProjectMilestonesUsecase(projectId);
    final ProjectsData latest = state.dataOrNull ?? current;
    emit(
      ProjectsLoaded(
        latest.copyWith(
          milestones: result.fold((Failure _) => const <ProjectMilestone>[], (m) => m),
          isMilestonesLoading: false,
        ),
      ),
    );
  }

  Future<bool> createMilestone({
    required String projectId,
    required String title,
    String? titleAr,
    String? description,
    DateTime? dueDate,
  }) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return false;

    emit(ProjectsLoaded(current.copyWith(isMilestoneActionInProgress: true)));

    final DateTime now = DateTime.now().toUtc();
    final ProjectMilestone milestone = ProjectMilestone(
      id: IdGenerator.v4(),
      companyId: current.currentUser.companyId,
      projectId: projectId,
      title: title.trim(),
      titleAr: (titleAr == null || titleAr.trim().isEmpty) ? null : titleAr.trim(),
      description:
          (description == null || description.trim().isEmpty) ? null : description.trim(),
      dueDate: dueDate,
      status: MilestoneStatus.pending,
      progressPercent: 0,
      createdBy: current.currentUser.userId,
      createdAt: now,
      updatedAt: now,
    );

    final ResultOf<ProjectMilestone> result = await _createMilestoneUsecase(milestone);
    final ProjectsData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(ProjectsLoaded(latest.copyWith(isMilestoneActionInProgress: false)));
        return false;
      },
      (ProjectMilestone created) {
        emit(
          ProjectsLoaded(
            latest.copyWith(
              milestones: <ProjectMilestone>[...latest.milestones, created],
              isMilestoneActionInProgress: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  /// يحدّث حالة/نسبة إنجاز مرحلة قائمة — عند تمرير
  /// [MilestoneStatus.completed] يُحدَّد [ProjectMilestone.completedAt]
  /// تلقائياً إلى الوقت الحالي، وتُرفع النسبة إلى 100% إن لم تكن كذلك.
  Future<bool> updateMilestoneProgress({
    required ProjectMilestone milestone,
    MilestoneStatus? status,
    int? progressPercent,
  }) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return false;

    emit(ProjectsLoaded(current.copyWith(isMilestoneActionInProgress: true)));

    final bool completing = status == MilestoneStatus.completed;
    final ProjectMilestone updated = milestone.copyWith(
      status: status ?? milestone.status,
      progressPercent: completing ? 100 : (progressPercent ?? milestone.progressPercent),
      completedAt: completing ? DateTime.now().toUtc() : milestone.completedAt,
      updatedAt: DateTime.now().toUtc(),
    );

    final ResultOf<ProjectMilestone> result = await _updateMilestoneUsecase(updated);
    final ProjectsData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(ProjectsLoaded(latest.copyWith(isMilestoneActionInProgress: false)));
        return false;
      },
      (ProjectMilestone saved) {
        emit(
          ProjectsLoaded(
            latest.copyWith(
              milestones: latest.milestones
                  .map((ProjectMilestone m) => m.id == saved.id ? saved : m)
                  .toList(growable: false),
              isMilestoneActionInProgress: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  Future<bool> deleteMilestone(String milestoneId) async {
    final ProjectsData? current = state.dataOrNull;
    if (current == null) return false;

    emit(ProjectsLoaded(current.copyWith(isMilestoneActionInProgress: true)));
    final ResultOf<void> result = await _deleteMilestoneUsecase(milestoneId);
    final ProjectsData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(ProjectsLoaded(latest.copyWith(isMilestoneActionInProgress: false)));
        return false;
      },
      (_) {
        emit(
          ProjectsLoaded(
            latest.copyWith(
              milestones: latest.milestones
                  .where((ProjectMilestone m) => m.id != milestoneId)
                  .toList(growable: false),
              isMilestoneActionInProgress: false,
            ),
          ),
        );
        return true;
      },
    );
  }
}
