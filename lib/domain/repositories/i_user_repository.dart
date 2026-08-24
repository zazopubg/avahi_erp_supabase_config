import '../../core/errors/failure.dart';
import '../entities/app_user.dart';
import '../enums/user_role.dart';

/// عقد إدارة أعضاء الشركة (`public.company_members`) والصلاحيات —
/// أساس `features/users/` (Prompt 26): إدارة المستخدمين والأدوار،
/// محصور فعلياً بالأدوار الإدارية عبر `Permission.usersView`/
/// `usersInvite`/`usersEditRoles`/`usersDeactivate`
/// (`core/constants/permissions.dart`)، تُفرَض دائماً أيضاً عبر RLS
/// في Supabase وليس هنا فقط. 🆕
///
/// ⚠️ قرار تصميم مهم (بلا `getMemberById`/`watchCompanyMembers`):
/// بخلاف `ILeaveRepository`/`IEquipmentRepository`، هذا العقد لا يحمل
/// جالباً لعضو واحد بمعرّفه (`users_list.dart` يعرض/يحدّث دائماً من
/// نفس قائمة [getCompanyMembers] المحمَّلة أصلاً — لا شاشة "تفاصيل
/// عضو" مستقلة عبر مسار خاص بها، انظر `user_details.dart`)، ولا
/// اشتراكاً لحظياً (تغييرات الأدوار/الحالة نادرة نسبياً وتُحدَّث محلياً
/// فوراً بعد نجاح كل استدعاء، بنفس قرار `ILeaveRepository` الموثّق في
/// `LeaveCubit`).
abstract interface class IUserRepository {
  /// يجلب **كل** أعضاء [companyId] (كل الأدوار والحالات معاً) —
  /// أساس `users_list.dart`. التصفية حسب الدور/الحالة/نص البحث تُطبَّق
  /// لاحقاً ضمن `UsersData` نفسها وليس هنا، بنفس منطق
  /// `LeaveData.filteredCompanyRequests`.
  Future<ResultOf<List<AppUser>>> getCompanyMembers(String companyId);

  /// يحدّث دور عضوية [membershipId] إلى [role] — `user_roles_edit.dart`،
  /// محصور بصلاحية [Permission.usersEditRoles] (admin فقط، انظر
  /// `core/constants/permissions.dart`). هذا التحديث نفسه (UPDATE على
  /// `company_members`) هو ما يُفعِّل تلقائياً Database Webhook دالة
  /// `sync-user-claims` على الخادم — انظر توثيق القرار الكامل حول عدم
  /// استدعائها مباشرة من العميل في `UpdateMemberRoleUsecase`.
  Future<ResultOf<AppUser>> updateMemberRole({
    required String membershipId,
    required UserRole role,
  });

  /// يفعّل/يعطّل عضوية [membershipId] — `user_details.dart`، محصور
  /// بصلاحية [Permission.usersDeactivate]. تعطيل العضوية لا يحذف صف
  /// `company_members` (يُبقي السجل التاريخي كاملاً لأغراض التدقيق)،
  /// بل يضبط `is_active = false` فقط — نفس أثره على الوصول الفعلي عبر
  /// RLS كحذف العضوية تماماً (كل سياسات RLS تتحقق من `is_active`).
  Future<ResultOf<AppUser>> updateMemberStatus({
    required String membershipId,
    required bool isActive,
  });

  /// يدعو مستخدماً جديداً بالبريد [email] إلى [companyId] بدور [role] —
  /// `invite_user.dart`، عبر Edge Function مخصّصة (`invite-user`،
  /// `backend/supabase/functions/invite-user/`) وليس عبر إدراج مباشر
  /// على `company_members`/`auth.users`: إنشاء مستخدم Supabase Auth
  /// جديد (أو دعوته بالبريد) يتطلب صلاحية `service_role` غير متاحة
  /// للعميل مطلقاً — بنفس منطق `AttendanceRepositoryImpl` (Edge
  /// Function بدل منطق مكرَّر على العميل)، لكن هنا للأمان لا لتعقيد
  /// حسابي.
  Future<ResultOf<AppUser>> inviteUser({
    required String companyId,
    required String email,
    required String fullName,
    required UserRole role,
    String? jobTitle,
    String? phone,
  });
}
