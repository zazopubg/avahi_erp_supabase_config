import 'package:equatable/equatable.dart';

import 'app_user.dart';

/// 🆕 (Prompt 20) دمج [ProjectMember] (صف إسناد خام من
/// `public.project_members`) مع [AppUser] (بيانات عضوية الشركة
/// الكاملة: الاسم، الدور، الصورة الرمزية...) — كيان عرض مخصص لطبقة
/// `features/projects/` فقط (`project_members.dart`،
/// `member_role_selector.dart`)، وليس صفاً مباشراً في قاعدة البيانات.
///
/// ⚠️ قرار تصميم: [IProjectRepository.getProjectMembers] يحتاج عملياً
/// عرض اسم/دور كل عضو مُسند لا معرّف `userId` مجرداً فقط — بدل تضخيم
/// [ProjectMember] نفسه (الذي يطابق الجدول حرفياً، `project_member.dart`)
/// بحقول عرض لا تخصّه، هذا الكيان المركّب المنفصل يحمل [projectMemberId]
/// (صف `project_members.id`، ضروري لعملية [IProjectRepository.removeProjectMember])
/// مع [user] (`AppUser` الكاملة) معاً.
class ProjectMemberDetail extends Equatable {
  const ProjectMemberDetail({
    required this.projectMemberId,
    required this.projectId,
    required this.assignedAt,
    required this.isActive,
    required this.user,
  });

  /// معرّف صف `public.project_members` نفسه (لا `userId`) — يُستخدم
  /// حصراً عند استدعاء [IProjectRepository.removeProjectMember].
  final String projectMemberId;

  final String projectId;
  final DateTime assignedAt;
  final bool isActive;

  /// بيانات عضوية الشركة الكاملة للمستخدم المُسند (الاسم، الدور،
  /// الصورة الرمزية، رقم الهاتف...).
  final AppUser user;

  @override
  List<Object?> get props => <Object?>[
        projectMemberId,
        projectId,
        assignedAt,
        isActive,
        user,
      ];
}
