import 'package:flutter/material.dart';

import '../../../../domain/enums/user_role.dart';
import '../../../../navigation/role_labels.dart';
import '../../../../ui/widgets/common/status_badge.dart';

/// يحوّل [UserRole] إلى لون دلالي وأيقونة مناسبة — منطق مشترك بين
/// [RoleBadge] و`permissions_matrix.dart`، بنفس نمط
/// `equipmentStatusVisuals` (`features/equipment/presentation/widgets/equipment_status_badge.dart`).
///
/// الألوان مرتّبة تصاعدياً حسب [UserRole.rank]: محايد للأدوار
/// الميدانية (worker/foreman)، معلوماتي للأدوار الفنية/الإدارية
/// الوسطى (engineer/projectManager)، وتحذيري للأدوار الإدارية
/// الكاملة (admin/platformOwner) — إشارة بصرية سريعة لمستوى الصلاحية
/// دون قراءة النص.
(AvahiStatus, IconData) userRoleVisuals(UserRole role) {
  switch (role) {
    case UserRole.worker:
      return (AvahiStatus.neutral, Icons.construction_outlined);
    case UserRole.foreman:
      return (AvahiStatus.neutral, Icons.groups_outlined);
    case UserRole.engineer:
      return (AvahiStatus.info, Icons.engineering_outlined);
    case UserRole.projectManager:
      return (AvahiStatus.info, Icons.badge_outlined);
    case UserRole.admin:
      return (AvahiStatus.warning, Icons.admin_panel_settings_outlined);
    case UserRole.platformOwner:
      return (AvahiStatus.danger, Icons.workspace_premium_outlined);
  }
}

/// شارة دور موحّدة — غلاف رفيع فوق [StatusBadge] العام بتسمية
/// [UserRoleLabelX.displayLabel] ولون [userRoleVisuals] المناسبين —
/// مستخدَمة عبر `user_card.dart`/`users_list.dart`/`user_details.dart`/
/// `permissions_matrix.dart`.
///
/// مكوّن عرض بحت — لا يحمل أي منطق تحديد صلاحيات فعلي.
class RoleBadge extends StatelessWidget {
  const RoleBadge({required this.role, super.key, this.dense = false});

  final UserRole role;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (AvahiStatus status, IconData icon) = userRoleVisuals(role);
    return StatusBadge(
      label: role.displayLabel,
      status: status,
      icon: icon,
      dense: dense,
    );
  }
}
