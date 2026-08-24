import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/roles.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/project_member_detail.dart';
import '../../../../domain/entities/project_milestone.dart';
import '../../../../domain/repositories/i_project_repository.dart';
import '../../../dto/app_user_dto.dart';
import '../../../dto/project_dto.dart';
import '../../../dto/project_milestone_dto.dart';
import '../queries/dashboard_queries.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IProjectRepository] فوق جداول `public.projects` /
/// `public.project_members` / `public.project_milestones` (🆕 Prompt
/// 20) عبر Supabase.
///
/// ⚠️ سياسة RLS `projects_select` (انظر `016_rls_policies.sql`) تتيح
/// لكل عضو شركة نشط رؤية **كل** مشاريع شركته (وليس فقط المُسند إليها)
/// — القرار المعماري أن التصفية لـ "مشاريعي" (عامل/رئيس عمال) تكون
/// عبر `project_members`، بينما الأدوار الإدارية (`projectManager`
/// فأعلى) ترى كل مشاريع الشركة مباشرة دون تصفية، تطبيقاً لتعليق
/// [IProjectRepository.getMyProjects] في طبقة الـ domain.
///
/// 🆕 (Prompt 20) [getProjectMembers]/[getAvailableCompanyMembers]
/// تعتمدان استعلامين منفصلين (بدل `join` واحد عبر بنية `select`
/// المتداخلة في PostgREST) بنفس أسلوب [getMyProjects] تماماً (انظر
/// توثيقها أعلى) تفادياً لأي هشاشة محتملة في صياغة الـ join المتداخل،
/// ولأن حجم البيانات هنا (أعضاء مشروع واحد) صغير دائماً عملياً.
class ProjectRepositoryImpl implements IProjectRepository {
  ProjectRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client,
        _dashboardQueries = DashboardQueries(client: client);

  final sb.SupabaseClient _client;
  final DashboardQueries _dashboardQueries;

  @override
  Future<ResultOf<Project>> getProjectById(String projectId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableProjects)
          .select()
          .eq('id', projectId)
          .single();
      return Right<Failure, Project>(ProjectDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Project>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<Project>>> getMyProjects(String userId) async {
    try {
      final Map<String, dynamic>? membership = await _client
          .from(ApiConstants.tableCompanyMembers)
          .select('role')
          .eq('user_id', userId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      final UserRole role = membership == null
          ? UserRole.worker
          : UserRole.fromName(membership['role'] as String);

      final List<Map<String, dynamic>> rows;
      if (role.rank >= UserRole.projectManager.rank) {
        // دور إداري: كل مشاريع الشركة (RLS تُطبّق النطاق تلقائياً).
        rows = await _client
            .from(ApiConstants.tableProjects)
            .select()
            .order('created_at', ascending: false);
      } else {
        // دور تنفيذي: فقط المشاريع المُسند إليها المستخدم عبر
        // project_members.
        final List<Map<String, dynamic>> assignments = await _client
            .from(ApiConstants.tableProjectMembers)
            .select('project_id')
            .eq('user_id', userId)
            .eq('is_active', true);

        final List<String> projectIds = assignments
            .map((Map<String, dynamic> row) => row['project_id'] as String)
            .toList(growable: false);

        if (projectIds.isEmpty) {
          rows = const <Map<String, dynamic>>[];
        } else {
          rows = await _client
              .from(ApiConstants.tableProjects)
              .select()
              .inFilter('id', projectIds)
              .order('created_at', ascending: false);
        }
      }

      return Right<Failure, List<Project>>(
        rows.map((Map<String, dynamic> row) => ProjectDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<Project>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Map<String, num>>> getProjectDashboard(String projectId) {
    return _dashboardQueries.getProjectDashboard(projectId);
  }

  @override
  Future<ResultOf<Project>> createProject(Project project) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableProjects)
          .insert(ProjectDto.fromEntity(project).toInsertJson())
          .select()
          .single();
      return Right<Failure, Project>(ProjectDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Project>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Project>> updateProject(Project project) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableProjects)
          .update(ProjectDto.fromEntity(project).toInsertJson())
          .eq('id', project.id)
          .select()
          .single();
      return Right<Failure, Project>(ProjectDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Project>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  // ── 🆕 إدارة فريق المشروع (Prompt 20) ───────────────────────────

  @override
  Future<ResultOf<List<ProjectMemberDetail>>> getProjectMembers(
    String projectId,
  ) async {
    try {
      final List<Map<String, dynamic>> assignmentRows = await _client
          .from(ApiConstants.tableProjectMembers)
          .select()
          .eq('project_id', projectId)
          .eq('is_active', true)
          .order('assigned_at', ascending: true);

      if (assignmentRows.isEmpty) {
        return const Right<Failure, List<ProjectMemberDetail>>(
          <ProjectMemberDetail>[],
        );
      }

      final List<String> userIds = assignmentRows
          .map((Map<String, dynamic> row) => row['user_id'] as String)
          .toList(growable: false);

      final List<Map<String, dynamic>> memberRows = await _client
          .from(ApiConstants.tableCompanyMembers)
          .select()
          .inFilter('user_id', userIds);

      final Map<String, AppUser> usersByUserId = <String, AppUser>{
        for (final Map<String, dynamic> row in memberRows)
          (row['user_id'] as String): AppUserDto.fromJson(row).toEntity(),
      };

      final List<ProjectMemberDetail> details = assignmentRows
          .map((Map<String, dynamic> row) {
            final String userId = row['user_id'] as String;
            final AppUser? user = usersByUserId[userId];
            if (user == null) return null;
            return ProjectMemberDetail(
              projectMemberId: row['id'] as String,
              projectId: row['project_id'] as String,
              assignedAt: DateTime.parse(row['assigned_at'] as String),
              isActive: row['is_active'] as bool,
              user: user,
            );
          })
          .whereType<ProjectMemberDetail>()
          .toList(growable: false);

      return Right<Failure, List<ProjectMemberDetail>>(details);
    } catch (error, stackTrace) {
      return Left<Failure, List<ProjectMemberDetail>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<AppUser>>> getAvailableCompanyMembers({
    required String companyId,
    required String projectId,
  }) async {
    try {
      final List<Map<String, dynamic>> assignmentRows = await _client
          .from(ApiConstants.tableProjectMembers)
          .select('user_id')
          .eq('project_id', projectId)
          .eq('is_active', true);

      final Set<String> assignedUserIds = assignmentRows
          .map((Map<String, dynamic> row) => row['user_id'] as String)
          .toSet();

      final List<Map<String, dynamic>> memberRows = await _client
          .from(ApiConstants.tableCompanyMembers)
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('full_name', ascending: true);

      final List<AppUser> available = memberRows
          .where(
            (Map<String, dynamic> row) =>
                !assignedUserIds.contains(row['user_id'] as String),
          )
          .map((Map<String, dynamic> row) => AppUserDto.fromJson(row).toEntity())
          .toList(growable: false);

      return Right<Failure, List<AppUser>>(available);
    } catch (error, stackTrace) {
      return Left<Failure, List<AppUser>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<ProjectMemberDetail>> addProjectMember({
    required String projectId,
    required String companyId,
    required String userId,
  }) async {
    try {
      final Map<String, dynamic> assignmentRow = await _client
          .from(ApiConstants.tableProjectMembers)
          .insert(<String, dynamic>{
            'project_id': projectId,
            'company_id': companyId,
            'user_id': userId,
          })
          .select()
          .single();

      final Map<String, dynamic> memberRow = await _client
          .from(ApiConstants.tableCompanyMembers)
          .select()
          .eq('user_id', userId)
          .eq('company_id', companyId)
          .single();

      final AppUser user = AppUserDto.fromJson(memberRow).toEntity();

      return Right<Failure, ProjectMemberDetail>(
        ProjectMemberDetail(
          projectMemberId: assignmentRow['id'] as String,
          projectId: assignmentRow['project_id'] as String,
          assignedAt: DateTime.parse(assignmentRow['assigned_at'] as String),
          isActive: assignmentRow['is_active'] as bool,
          user: user,
        ),
      );
    } catch (error, stackTrace) {
      return Left<Failure, ProjectMemberDetail>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<void>> removeProjectMember(String projectMemberId) async {
    try {
      await _client
          .from(ApiConstants.tableProjectMembers)
          .delete()
          .eq('id', projectMemberId);
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      return Left<Failure, void>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  // ── 🆕 إدارة المراحل الرئيسية (Prompt 20) ───────────────────────

  @override
  Future<ResultOf<List<ProjectMilestone>>> getProjectMilestones(
    String projectId,
  ) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableProjectMilestones)
          .select()
          .eq('project_id', projectId)
          .order('due_date', ascending: true);

      return Right<Failure, List<ProjectMilestone>>(
        rows
            .map(
              (Map<String, dynamic> row) =>
                  ProjectMilestoneDto.fromJson(row).toEntity(),
            )
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<ProjectMilestone>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<ProjectMilestone>> createMilestone(
    ProjectMilestone milestone,
  ) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableProjectMilestones)
          .insert(ProjectMilestoneDto.fromEntity(milestone).toInsertJson())
          .select()
          .single();
      return Right<Failure, ProjectMilestone>(
        ProjectMilestoneDto.fromJson(row).toEntity(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, ProjectMilestone>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<ProjectMilestone>> updateMilestone(
    ProjectMilestone milestone,
  ) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableProjectMilestones)
          .update(ProjectMilestoneDto.fromEntity(milestone).toInsertJson())
          .eq('id', milestone.id)
          .select()
          .single();
      return Right<Failure, ProjectMilestone>(
        ProjectMilestoneDto.fromJson(row).toEntity(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, ProjectMilestone>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<void>> deleteMilestone(String milestoneId) async {
    try {
      await _client
          .from(ApiConstants.tableProjectMilestones)
          .delete()
          .eq('id', milestoneId);
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      return Left<Failure, void>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
