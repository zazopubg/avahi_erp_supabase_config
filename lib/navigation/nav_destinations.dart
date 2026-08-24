import 'package:flutter/material.dart';

import '../core/constants/permissions.dart';
import '../domain/enums/user_role.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// تمثيل موحّد لوجهة تنقل رئيسية واحدة ضمن `AdaptiveShell` (الرئيسية،
/// المهام، الحضور...). كائن بيانات بحت — لا يحمل أي منطق تنقل فعلي.
@immutable
class NavDestination {
  const NavDestination({
    required this.routeName,
    required this.routePath,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.requiredPermission,
    this.isDesktopOnly = false,
  });

  final String routeName;
  final String routePath;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// الصلاحية المطلوبة لإظهار هذه الوجهة/الوصول إليها، أو `null` إن
  /// كانت متاحة لكل مستخدم مسجّل دخوله بغض النظر عن دوره (مثال:
  /// `home`). يعتمدها [RoleGuard] (`guards/role_guard.dart`) وكل
  /// قوالب التنقل (`shells/`) معاً من نفس المصدر لتفادي أي تعارض بين
  /// "ما يُعرض في القائمة" و"ما يُسمح فعلياً بالوصول إليه".
  final Permission? requiredPermission;

  /// صحيح للوجهات التي لا معنى لعرضها على شاشة هاتف ضيقة (مثال:
  /// `platformAdmin`) — يعتمدها [PlatformGuard]
  /// (`guards/platform_guard.dart`) لمنع الوصول المباشر عبر الرابط،
  /// بينما تتولى قوالب `shells/mobile/` إخفاءها من القوائم أصلاً.
  final bool isDesktopOnly;
}

/// القائمة الكاملة والمرتّبة لكل وجهات التنقل الرئيسية في التطبيق —
/// مصدر حقيقة واحد يُستهلك من `shells/mobile/bottom_nav_bar.dart`
/// و`shells/mobile/mobile_drawer.dart` و`shells/desktop/sidebar.dart`
/// معاً، بدل تكرار نفس القائمة (بأيقونات/تسميات قد تتباعد) في كل ملف.
///
/// ⚠️ كل وجهة هنا تُبنى الآن فوق شاشة مؤقتة موحّدة
/// (`_ComingSoonScreen` في `placeholder_screens.dart`) بانتظار ميزتها
/// الفعلية (Prompt 14 وما بعده) — إضافة الوجهة هنا الآن (بدل تأجيلها)
/// تسمح باختبار كامل نظام التنقل/الأدوار/الاستجابة للعرض من هذه
/// الخطوة مباشرة، ثم كل Prompt لاحق يستبدل `builder:` المسار المعني
/// فقط في `app_router.dart` دون أي تعديل هنا أو في القوالب نفسها.
abstract final class AppNavDestinations {
  static const NavDestination home = NavDestination(
    routeName: RouteNames.home,
    routePath: RoutePaths.home,
    label: 'الرئيسية',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  );

  static const NavDestination tasks = NavDestination(
    routeName: RouteNames.tasks,
    routePath: RoutePaths.tasks,
    label: 'مهامي',
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
    requiredPermission: Permission.tasksViewAssigned,
  );

  static const NavDestination attendance = NavDestination(
    routeName: RouteNames.attendance,
    routePath: RoutePaths.attendance,
    label: 'الحضور',
    icon: Icons.fingerprint_outlined,
    selectedIcon: Icons.fingerprint,
    requiredPermission: Permission.attendanceCheckInSelf,
  );

  static const NavDestination fieldReports = NavDestination(
    routeName: RouteNames.fieldReports,
    routePath: RoutePaths.fieldReports,
    label: 'التقارير',
    icon: Icons.description_outlined,
    selectedIcon: Icons.description,
    requiredPermission: Permission.fieldReportsCreate,
  );

  static const NavDestination photos = NavDestination(
    routeName: RouteNames.photos,
    routePath: RoutePaths.photos,
    label: 'الصور',
    icon: Icons.photo_library_outlined,
    selectedIcon: Icons.photo_library,
    requiredPermission: Permission.photosUpload,
  );

  static const NavDestination punchList = NavDestination(
    routeName: RouteNames.punchList,
    routePath: RoutePaths.punchList,
    label: 'قوائم الملاحظات',
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check,
    requiredPermission: Permission.punchListCreate,
  );

  static const NavDestination projects = NavDestination(
    routeName: RouteNames.projects,
    routePath: RoutePaths.projects,
    label: 'المشاريع',
    icon: Icons.apartment_outlined,
    selectedIcon: Icons.apartment,
    requiredPermission: Permission.projectsView,
  );

  static const NavDestination documents = NavDestination(
    routeName: RouteNames.documents,
    routePath: RoutePaths.documents,
    label: 'المستندات',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    requiredPermission: Permission.documentsView,
  );

  /// 🆕 (Prompt 22)
  ///
  /// ⚠️ قرار تصميم (أيقونة Material قياسية، لا أصل SVG مخصّص): كل
  /// وجهة ضمن [AppNavDestinations] — بلا استثناء واحد منذ `home` وحتى
  /// `documents` — تستخدم حصراً `IconData` من حزمة Material القياسية
  /// (انظر تعريف [NavDestination.icon] أعلاه: `final IconData icon`،
  /// لا `String assetPath`)؛ لا يوجد أي مجلد `assets/images/icons/`
  /// بأصول SVG مخصّصة في المشروع أصلاً. إضافة أيقونة `crane.svg`
  /// حقيقية تتطلب أولاً توسيع [NavDestination] نفسها لدعم أصول SVG
  /// (تغيير جذري يمسّ كل الوجهات العشرين الأخرى دفعة واحدة، خارج نطاق
  /// Prompt 22 هذا) **و** توفير ملف SVG فعلي غير متوفر لديّ. لذا
  /// اعتُمدت `Icons.construction_outlined`/`Icons.construction`
  /// (الرافعة/ورشة الإنشاء) بنفس منطق ورمزية "الرافعة" المطلوبة، بلا
  /// أي تغيير على نموذج [NavDestination] القائم.
  static const NavDestination equipment = NavDestination(
    routeName: RouteNames.equipment,
    routePath: RoutePaths.equipment,
    label: 'المعدات',
    icon: Icons.construction_outlined,
    selectedIcon: Icons.construction,
    requiredPermission: Permission.equipmentView,
  );

  static const NavDestination leaveRequests = NavDestination(
    routeName: RouteNames.leaveRequests,
    routePath: RoutePaths.leaveRequests,
    label: 'الإجازات',
    icon: Icons.event_busy_outlined,
    selectedIcon: Icons.event_busy,
    requiredPermission: Permission.leaveRequestSubmit,
  );

  /// 🆕 (Prompt 25) — مُعلَّمة `isDesktopOnly: true` بنفس منطق
  /// `platformAdmin` أدناه بالضبط: لوحة تحليلات تنفيذية مبنية على
  /// رسوم بيانية (`fl_chart`) وجداول (`DataGridRtl`) عريضة لا معنى
  /// لعرضها ضمن شاشة هاتف ضيقة — [PlatformGuard]
  /// (`guards/platform_guard.dart`) يمنع الوصول المباشر عبر الرابط
  /// تلقائياً عند [ShellMode.mobile] ويُعيد التوجيه لـ `RoutePaths.home`.
  static const NavDestination analytics = NavDestination(
    routeName: RouteNames.analytics,
    routePath: RoutePaths.analytics,
    label: 'التحليلات',
    icon: Icons.analytics_outlined,
    selectedIcon: Icons.analytics,
    requiredPermission: Permission.analyticsViewTeam,
    isDesktopOnly: true,
  );

  /// 🆕 (Prompt 26) — إدارة أعضاء الشركة/الأدوار (`users_list.dart`)
  /// وجدول الصلاحيات المرافق `permissions_matrix.dart` عمل إداري
  /// بطبيعته يُقرأ أفضل على شاشة عريضة (جداول أعمدة متعددة) — بنفس
  /// قرار `analytics` أعلاه تماماً؛ [PlatformGuard] يمنع الوصول عند
  /// [ShellMode.mobile] ويُعيد التوجيه لـ `RoutePaths.home`.
  static const NavDestination users = NavDestination(
    routeName: RouteNames.users,
    routePath: RoutePaths.users,
    label: 'المستخدمون',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    requiredPermission: Permission.usersView,
    isDesktopOnly: true,
  );

  static const NavDestination settings = NavDestination(
    routeName: RouteNames.settings,
    routePath: RoutePaths.settings,
    label: 'الإعدادات',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  static const NavDestination platformAdmin = NavDestination(
    routeName: RouteNames.platformAdmin,
    routePath: RoutePaths.platformAdmin,
    label: 'إدارة المنصّة',
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings,
    requiredPermission: Permission.platformManageTenants,
    isDesktopOnly: true,
  );

  /// كل الوجهات مرتّبة كما تُعرض في القائمة الجانبية الكاملة لسطح
  /// المكتب (`shells/desktop/sidebar.dart`) — "كل الميزات حسب الدور".
  static const List<NavDestination> all = <NavDestination>[
    home,
    attendance,
    tasks,
    fieldReports,
    photos,
    punchList,
    projects,
    documents,
    equipment,
    leaveRequests,
    analytics,
    users,
    settings,
    platformAdmin,
  ];

  /// الوجهات الأربع الأساسية للشريط السفلي على الهاتف
  /// (`shells/mobile/bottom_nav_bar.dart`) — عنصر خامس ثابت "المزيد"
  /// يُضاف من الودجة نفسها (ليس وجهة تنقل فعلية، بل يفتح
  /// [MobileDrawer]).
  static const List<NavDestination> mobilePrimary = <NavDestination>[
    home,
    tasks,
    attendance,
    fieldReports,
  ];

  /// يُصفّي [all] حسب صلاحيات [role]، مع استبعاد الوجهات التي تتطلب
  /// صلاحية غير ممنوحة له. الوجهات بلا [NavDestination.requiredPermission]
  /// (مثل `home`، `settings`) تبقى دائماً ظاهرة لأي دور.
  static List<NavDestination> visibleFor(UserRole role) {
    return all.where((NavDestination d) {
      final Permission? permission = d.requiredPermission;
      if (permission == null) return true;
      return RolePermissions.has(role, permission);
    }).toList(growable: false);
  }
}
