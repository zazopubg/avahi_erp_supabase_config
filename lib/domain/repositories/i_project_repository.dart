import '../../core/errors/failure.dart';
import '../entities/app_user.dart';
import '../entities/project.dart';
import '../entities/project_member_detail.dart';
import '../entities/project_milestone.dart';

/// عقد الوصول إلى المشاريع (`public.projects`).
///
/// 🆕 (Prompt 20) وُسِّع هذا العقد بثلاث مجموعات إضافية من العمليات
/// لدعم `features/projects/` كاملة، دون المساس بأي توقيع سابق (Prompt
/// 05/06 الأصلي يبقى كما هو حرفياً: [getProjectById]، [getMyProjects]،
/// [getProjectDashboard]، [createProject]، [updateProject]):
/// 1. إدارة فريق المشروع (`public.project_members`) — [getProjectMembers]/
///    [getAvailableCompanyMembers]/[addProjectMember]/[removeProjectMember]،
///    تخدم `project_members.dart`/`member_role_selector.dart`.
/// 2. إدارة المراحل الرئيسية (`public.project_milestones`، جدول جديد
///    بالكامل — انظر `020_create_project_milestones.sql`) —
///    [getProjectMilestones]/[createMilestone]/[updateMilestone]/
///    [deleteMilestone]، تخدم `project_milestones.dart`/`project_overview.dart`.
abstract interface class IProjectRepository {
  /// يجلب معرّف المشروع عبر معرّفه.
  Future<ResultOf<Project>> getProjectById(String projectId);

  /// يجلب مشاريع المستخدم الحالي (المشاريع التي يملك عضوية فيها عبر
  /// `project_members`، أو كل مشاريع الشركة للأدوار الإدارية).
  Future<ResultOf<List<Project>>> getMyProjects(String userId);

  /// يجلب بيانات لوحة تحكّم المشروع المجمّعة (عدد المهام المفتوحة،
  /// نسبة الحضور اليوم، عدد عناصر Punch List المفتوحة...). النوع
  /// المُعاد خفيف الوزن (`Map<String, num>`) بدل تعريف كيان مخصص، لأن
  /// هذه القراءة مجمّعة (Aggregation) ولا تمثّل صفاً في قاعدة البيانات
  /// — التفاصيل النهائية لشكل هذه البيانات تُحسم في `features/projects/`
  /// (Prompt 20).
  Future<ResultOf<Map<String, num>>> getProjectDashboard(String projectId);

  /// ينشئ مشروعاً جديداً.
  Future<ResultOf<Project>> createProject(Project project);

  /// يحدّث مشروعاً قائماً.
  Future<ResultOf<Project>> updateProject(Project project);

  // ── 🆕 إدارة فريق المشروع (Prompt 20) ───────────────────────────

  /// يجلب كل الأعضاء المُسندين لـ [projectId] حالياً (`is_active = true`)
  /// مع بياناتهم الكاملة (اسم، دور...) عبر [ProjectMemberDetail].
  Future<ResultOf<List<ProjectMemberDetail>>> getProjectMembers(
    String projectId,
  );

  /// يجلب أعضاء الشركة النشطين غير المُسندين بعد لـ [projectId] — أساس
  /// قائمة الاختيار في `member_role_selector.dart` عند إضافة عضو جديد.
  Future<ResultOf<List<AppUser>>> getAvailableCompanyMembers({
    required String companyId,
    required String projectId,
  });

  /// يُسند عضو الشركة [userId] إلى [projectId]. يُعيد تفاصيل الإسناد
  /// الجديد كاملة (بما فيها بيانات العضو نفسه) عند النجاح.
  Future<ResultOf<ProjectMemberDetail>> addProjectMember({
    required String projectId,
    required String companyId,
    required String userId,
  });

  /// يزيل إسناد عضو عن مشروع عبر معرّف صف `project_members` نفسه
  /// (وليس `userId`) — انظر توثيق [ProjectMemberDetail.projectMemberId].
  Future<ResultOf<void>> removeProjectMember(String projectMemberId);

  // ── 🆕 إدارة المراحل الرئيسية (Prompt 20) ───────────────────────

  /// يجلب كل مراحل [projectId]، مرتّبة حسب `dueDate` تصاعدياً.
  Future<ResultOf<List<ProjectMilestone>>> getProjectMilestones(
    String projectId,
  );

  /// ينشئ مرحلة رئيسية جديدة.
  Future<ResultOf<ProjectMilestone>> createMilestone(
    ProjectMilestone milestone,
  );

  /// يحدّث مرحلة قائمة (الحالة، نسبة الإنجاز، التاريخ...).
  Future<ResultOf<ProjectMilestone>> updateMilestone(
    ProjectMilestone milestone,
  );

  /// يحذف مرحلة نهائياً.
  Future<ResultOf<void>> deleteMilestone(String milestoneId);
}
