/// ملف تجميعي (Barrel File) لميزة `features/users/` كاملة 🆕 (Prompt
/// 26) — يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى باستيراد
/// كل شاشات وودجات وحالة هذه الميزة عبر سطر واحد، بنفس نمط
/// `features/analytics/analytics_feature.dart`/
/// `features/leave_requests/leave_requests_feature.dart` تماماً.
///
/// ⚠️ ملاحظة نطاق: هذه الميزة تصدّر شاشة واحدة فقط يستهلكها
/// `app_router.dart` مباشرة كنقطة `go_router` وحيدة — [UsersListScreen]
/// (`/users`، بلا أي مسار فرعي إضافي — بنفس منطق
/// `AnalyticsDashboard`). [UserDetailsPanel]/[UserRolesEditDialog]/
/// [InviteUserDialog] داخلية بالكامل (تُستهلَك حصراً من
/// [UsersListScreen] نفسها) لكنها مُصدَّرة أيضاً لتسهيل اختبارها بمعزل
/// لاحقاً في `test/` (Prompt 29)، بنفس منطق
/// `EquipmentDetailsPanel`/`AssignEquipmentDialog` في
/// `equipment_feature.dart`.
library;

export 'presentation/screens/desktop/invite_user.dart';
export 'presentation/screens/desktop/user_details.dart';
export 'presentation/screens/desktop/user_roles_edit.dart';
export 'presentation/screens/desktop/users_list.dart';
export 'presentation/state/users_cubit.dart';
export 'presentation/state/users_state.dart';
export 'presentation/widgets/permissions_matrix.dart';
export 'presentation/widgets/role_badge.dart';
export 'presentation/widgets/user_card.dart';
