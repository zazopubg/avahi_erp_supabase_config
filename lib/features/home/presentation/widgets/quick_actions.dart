import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/permissions.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../navigation/route_names.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// تعريف بيانات بحت لإجراء سريع واحد ضمن الشبكة — [requiredPermission]
/// `null` يعني إجراءً متاحاً لكل الأدوار (لا يوجد حالياً أي إجراء
/// كهذا في [QuickActions._all]، لكن الحقل يبقى اختيارياً اتساقاً مع
/// نفس نمط `NavDestination.requiredPermission` في `navigation/nav_destinations.dart`).
@immutable
class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.routeName,
    this.requiredPermission,
  });

  final String label;
  final IconData icon;
  final String routeName;
  final Permission? requiredPermission;
}

/// شبكة أزرار الإجراءات السريعة أعلى الشاشة الرئيسية — نفس منطق
/// التصفية حسب الدور المعتمد أصلاً في `AppNavDestinations.visibleFor`
/// (`navigation/nav_destinations.dart`)، لكن كمجموعة إجراءات مباشرة
/// (وليس وجهات تنقل كاملة) مرتّبة حسب الأولوية اليومية الفعلية بدل
/// الترتيب الهرمي للقائمة الجانبية.
///
/// مكوّن عرض بحت — يعتمد فقط على [role] الممرَّر من الشاشة الأب (بلا
/// أي اشتراك بـ `HomeCubit`/`AuthCubit` مباشرة هنا).
class QuickActions extends StatelessWidget {
  const QuickActions({required this.role, super.key});

  final UserRole role;

  static const List<_QuickAction> _all = <_QuickAction>[
    _QuickAction(
      label: 'تسجيل حضور',
      icon: Icons.fingerprint,
      routeName: RouteNames.attendance,
      requiredPermission: Permission.attendanceCheckInSelf,
    ),
    _QuickAction(
      label: 'مهامي',
      icon: Icons.checklist,
      routeName: RouteNames.tasks,
      requiredPermission: Permission.tasksViewAssigned,
    ),
    _QuickAction(
      label: 'تقرير ميداني',
      icon: Icons.description_outlined,
      routeName: RouteNames.fieldReports,
      requiredPermission: Permission.fieldReportsCreate,
    ),
    // 🆕 (Prompt 19) يفتح `/punch-list/create` مباشرة (تسجيل عيب سريع)
    // بدل `/punch-list` (تصفّح القائمة) — الإجراء السريع هنا مقصود
    // كاختصار "تسجيل" فوري، بنفس منطق "تقرير ميداني" أعلاه الذي يفتح
    // `/field-reports` (شاشة الإنشاء الافتراضية للعامل الميداني) لا
    // شاشة أرشيف. تصفّح القائمة الكاملة يبقى متاحاً عبر وجهة التنقل
    // الرئيسية `/punch-list` نفسها (`AppNavDestinations`).
    _QuickAction(
      label: 'تسجيل عيب',
      icon: Icons.fact_check_outlined,
      routeName: RouteNames.punchListCreate,
      requiredPermission: Permission.punchListCreate,
    ),
    _QuickAction(
      label: 'طلب إجازة',
      icon: Icons.event_busy_outlined,
      routeName: RouteNames.leaveRequests,
      requiredPermission: Permission.leaveRequestSubmit,
    ),
    _QuickAction(
      label: 'اعتماد الحضور',
      icon: Icons.approval_outlined,
      routeName: RouteNames.attendance,
      requiredPermission: Permission.attendanceApproveTeam,
    ),
    _QuickAction(
      label: 'المعدات',
      icon: Icons.construction_outlined,
      routeName: RouteNames.equipment,
      requiredPermission: Permission.equipmentManage,
    ),
    _QuickAction(
      label: 'المستخدمون',
      icon: Icons.people_outline,
      routeName: RouteNames.users,
      requiredPermission: Permission.usersView,
    ),
    _QuickAction(
      label: 'التحليلات',
      icon: Icons.analytics_outlined,
      routeName: RouteNames.analytics,
      requiredPermission: Permission.analyticsViewTeam,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<_QuickAction> visible = _all.where((_QuickAction action) {
      final Permission? permission = action.requiredPermission;
      if (permission == null) return true;
      return RolePermissions.has(role, permission);
    }).toList(growable: false);

    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AvahiSpacing.sm,
      runSpacing: AvahiSpacing.sm,
      children: visible
          .map((_QuickAction action) => _QuickActionTile(action: action))
          .toList(growable: false),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.goNamed(action.routeName),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(
          vertical: AvahiSpacing.sm,
          horizontal: AvahiSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(action.icon, color: context.colors.primary),
            const SizedBox(height: AvahiSpacing.xxs),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
