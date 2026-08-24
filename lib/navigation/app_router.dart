import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/errors/failure.dart';
import '../core/platform/shell_mode.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/repositories.dart';
import '../features/analytics/analytics_feature.dart';
import '../features/attendance/attendance_feature.dart';
import '../features/auth/auth_feature.dart';
import '../features/documents/documents_feature.dart';
import '../features/equipment/equipment_feature.dart';
import '../features/field_reports/field_reports_feature.dart';
import '../features/home/home_feature.dart';
import '../features/leave_requests/leave_requests_feature.dart';
import '../features/notifications/notifications_feature.dart';
import '../features/photos/photos_feature.dart';
import '../features/platform_admin/platform_admin_feature.dart';
import '../features/projects/projects_feature.dart';
import '../features/punch_list/punch_list_feature.dart';
import '../features/settings/settings_feature.dart';
import '../features/tasks/tasks_feature.dart';
import '../features/users/users_feature.dart';
import 'guards/auth_guard.dart';
import 'guards/platform_guard.dart';
import 'guards/role_guard.dart';
import 'guards/subscription_guard.dart';
import 'nav_destinations.dart';
import 'placeholder_screens.dart';
import 'route_names.dart';
import 'route_paths.dart';
import 'shells/adaptive_shell.dart';
import 'transitions/custom_page_transitions.dart';

/// نقطة التجميع النهائية لكامل شجرة التنقل — يُنشأ **مرة واحدة فقط**
/// (انظر `app.dart`) بحقن [IAuthRepository] المُسجَّل مسبقاً في حاوية
/// حقن التبعيات (`core/di/data_module.dart`)، ويُفكَّك عبر [dispose]
/// عند إزالة `AvahiApp` من الشجرة (عملياً لا يحدث فعلياً في عمر تطبيق
/// ويب من صفحة واحدة، لكن التزاماً بصحة إدارة الموارد).
///
/// يجمع أربعة مسؤوليات منفصلة عمداً في ملفات مستقلة (`guards/`،
/// `shells/`، `transitions/`) بدل خلطها هنا جميعاً:
/// 1. تعريف كل [GoRoute] (المسار ↔ الاسم ↔ الصفحة/الانتقال).
/// 2. تجميع `ShellRoute` واحد يلفّ كل وجهات [AppNavDestinations] عبر
///    [AdaptiveShell].
/// 3. تنفيذ سلسلة الحراس الأربعة بترتيب ثابت داخل [_redirect]:
///    [AuthGuard] → [RoleGuard] → [PlatformGuard] → [SubscriptionGuard]
///    — أول حارس يُعيد مساراً غير `null` يفوز فوراً (لا داعي لتقييم ما
///    تبقّى)، والترتيب نفسه مقصود: لا معنى للتحقق من صلاحية دور مستخدم
///    غير مسجّل دخوله أصلاً، ولا من قيد عرض/اشتراك على مسار سيُعاد
///    توجيهه بالفعل لتسجيل الدخول.
/// 4. إعادة تقييم [_redirect] تلقائياً عند أي تغيّر في حالة المصادقة
///    عبر [_GoRouterRefreshStream] (يلفّ `IAuthRepository.watchAuthState()`)
///    الممرّر كـ `refreshListenable` — بدونه، تسجيل الخروج مثلاً لن
///    يُعيد توجيه المستخدم فعلياً إلا عند محاولة تنقّل يدوي جديدة.
class AppRouter {
  AppRouter({required IAuthRepository authRepository})
      : _authRepository = authRepository,
        _refreshListenable =
            _GoRouterRefreshStream(authRepository.watchAuthState());

  final IAuthRepository _authRepository;
  final _GoRouterRefreshStream _refreshListenable;

  static const AuthGuard _authGuard = AuthGuard();
  static const RoleGuard _roleGuard = RoleGuard();
  static const PlatformGuard _platformGuard = PlatformGuard();
  static const SubscriptionGuard _subscriptionGuard = SubscriptionGuard();

  /// كائن `GoRouter` الفعلي المُمرَّر لـ `MaterialApp.router` في
  /// `app.dart` عبر `routerConfig:`. `late final` عمداً: يُبنى مرة
  /// واحدة فقط عند إنشاء [AppRouter] نفسه، وليس عند كل وصول له.
  late final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: _refreshListenable,
    redirect: _redirect,
    routes: <RouteBase>[
      // ── تدفّق الدخول (خارج AdaptiveShell) ─────────────────────────
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        pageBuilder: (context, state) => AvahiPageTransitions.none(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        pageBuilder: (context, state) => AvahiPageTransitions.none(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.pin,
        name: RouteNames.pin,
        pageBuilder: (context, state) => AvahiPageTransitions.none(
          key: state.pageKey,
          child: const PinScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.companySelect,
        name: RouteNames.companySelect,
        pageBuilder: (context, state) => AvahiPageTransitions.none(
          key: state.pageKey,
          child: const CompanySelectScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        pageBuilder: (context, state) => AvahiPageTransitions.none(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),

      // ── AdaptiveShell — كل وجهات AppNavDestinations ────────────────
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveShell(state: state, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // ✅ Prompt 14: شاشة `features/home/` الفعلية — تستبدل
              // `HomePlaceholderScreen` المؤقتة (`placeholder_screens.dart`،
              // Prompt 12/13). تُفوّض [HomeScreen] داخلياً حسب
              // `UserRole` إلى `WorkerHome`/`SupervisorHome`/`ManagerHome`.
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.attendance,
            name: RouteNames.attendance,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // ✅ Prompt 15: شاشة `features/attendance/` الفعلية —
              // تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد يخدم كل
              // شاشات الميزة (GPS/QR، سجل شخصي، مراقبة/تقرير إدارية)
              // عبر تنقّل محلي داخل [AttendanceScreen] — انظر توثيق
              // القرار الكامل في `attendance_cubit.dart`.
              child: const AttendanceScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.tasks,
            name: RouteNames.tasks,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // ✅ Prompt 16: شاشة `features/tasks/` الفعلية — تستبدل
              // `ComingSoonScreen` المؤقتة. مسار وحيد يخدم قائمة "مهامي"
              // (الهاتف) وجدول/لوحة سطح المكتب، بنفس نمط `AttendanceScreen`
              // — انظر توثيق القرار الكامل في `tasks_screen.dart`.
              child: const TasksScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.fieldReports,
            name: RouteNames.fieldReports,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // ✅ Prompt 17: شاشة `features/field_reports/` الفعلية —
              // تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد يخدم كل
              // شاشات الميزة (نموذج/توقيع للعامل الميداني، وارد لحظي/
              // مراجعة/أرشيف/تصدير للإدارة) عبر تنقّل محلي داخل
              // [FieldReportsScreen] — انظر توثيق القرار الكامل في
              // `field_reports_screen.dart`.
              child: const FieldReportsScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.photos,
            name: RouteNames.photos,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // ✅ Prompt 18: شاشة `features/photos/` الفعلية — تستبدل
              // `ComingSoonScreen` المؤقتة. مسار وحيد يخدم صور المستخدم
              // (الهاتف) ومعرض المشروع الكامل مع لوحة تفاصيل (سطح
              // المكتب)، بنفس نمط `TasksScreen`/`AttendanceScreen` —
              // انظر توثيق القرار الكامل في `photos_screen.dart`.
              // تدفّق الالتقاط/الربط نفسه (`/photos/camera`،
              // `/photos/attach`) مسارات مستقلة تماماً خارج
              // `ShellRoute` هذه — انظر أسفل هذه القائمة.
              child: const PhotosScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.punchList,
            name: RouteNames.punchList,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // ✅ Prompt 19: شاشة `features/punch_list/` الفعلية —
              // تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد يخدم قائمة
              // العيوب (الهاتف) ولوحة المتابعة عبر كل المشاريع (سطح
              // المكتب)، بنفس نمط `TasksScreen`/`PhotosScreen` —
              // انظر توثيق القرار الكامل في `punch_list_screen.dart`.
              // مساري الإنشاء/التفاصيل (`/punch-list/create`،
              // `/punch-list/details`) مسارات مستقلة تماماً خارج
              // `ShellRoute` هذه — انظر أسفل هذه القائمة.
              child: const PunchListScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.projects,
            name: RouteNames.projects,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // ✅ Prompt 20: شاشة `features/projects/` الفعلية —
              // تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد يخدم قائمة
              // "مشاريعي" (الهاتف) وجدول إداري شامل (سطح المكتب)، بنفس
              // نمط `PunchListScreen` — انظر توثيق القرار الكامل في
              // `my_projects_screen.dart`. مسارات `/projects/:id`
              // وفروعها (`members`/`milestones`/`settings`) مسارات
              // مستقلة داخل نفس `ShellRoute` — انظر أسفل هذه القائمة،
              // بنفس منطق `RoutePaths.tasksBoard`.
              child: const MyProjectsScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.documents,
            name: RouteNames.documents,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // ✅ Prompt 21: شاشة `features/documents/` الفعلية —
              // تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد يخدم قائمة
              // المستندات للعرض فقط (الهاتف) وإدارة كاملة (رفع/تصنيف/
              // بحث/أرشفة) على سطح المكتب، بنفس نمط `PunchListScreen`/
              // `MyProjectsScreen` — انظر توثيق القرار الكامل في
              // `documents_list.dart`. مسار `/documents/:id` مسار
              // مستقل داخل نفس `ShellRoute` — انظر أسفل هذه القائمة،
              // بنفس منطق `RoutePaths.projectDetails`.
              child: const DocumentsListScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.equipment,
            name: RouteNames.equipment,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // 🆕 (Prompt 22): شاشة `features/equipment/` الفعلية —
              // تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد يخدم
              // قائمة "معداتي" (الهاتف) وسجل معدات كامل مع جدول صيانة
              // (سطح المكتب)، بنفس نمط `DocumentsListScreen`/
              // `PunchListScreen` — انظر توثيق القرار الكامل في
              // `my_equipment_screen.dart`. مسار `/equipment/log-usage`
              // مسار مستقل تماماً خارج `ShellRoute` هذه — انظر أسفل
              // هذه القائمة، بنفس منطق `RoutePaths.punchListCreate`.
              child: const MyEquipmentScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.leaveRequests,
            name: RouteNames.leaveRequests,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // 🆕 (Prompt 24): شاشة `features/leave_requests/`
              // الفعلية — تستبدل `ComingSoonScreen` المؤقتة. مسار
              // وحيد يخدم سجل طلبات الإجازة الشخصية (الهاتف) ووارد
              // اعتماد/رفض لفريق مشرف/مدير (سطح المكتب)، بنفس نمط
              // `MyEquipmentScreen`/`DocumentsListScreen` — انظر
              // توثيق القرار الكامل في `my_leave_requests_screen.dart`.
              // شاشتا الإنشاء/المراجعة (`create_leave_request_screen.dart`،
              // `leave_request_review.dart`) لوحتان/`Navigator.push`
              // داخليتان بالكامل ضمن نفس نسخة `LeaveCubit` — بلا أي
              // مسار `go_router` منفصل لأيّهما، بخلاف
              // `RoutePaths.punchListCreate`/`punchListDetails`.
              child: const MyLeaveRequestsScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.analytics,
            name: RouteNames.analytics,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // 🆕 (Prompt 25): شاشة `features/analytics/` الفعلية —
              // تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد يخدم كل
              // ألسنة اللوحة الأربعة معاً (نظرة عامة/المشاريع/الحضور/
              // التصدير) — بنفس نمط `MyEquipmentScreen`/
              // `MyLeaveRequestsScreen`، لكن بلا أي مسار فرعي إضافي —
              // انظر توثيق القرار الكامل في `analytics_dashboard.dart`.
              // مُعلَّمة `isDesktopOnly: true` ضمن
              // `AppNavDestinations.analytics` (`nav_destinations.dart`)
              // — [PlatformGuard] يتولى المنع/التوجيه تلقائياً عند
              // `ShellMode.mobile`، بنفس منطق `RouteNames.platformAdmin`.
              child: const AnalyticsDashboard(),
            ),
          ),
          GoRoute(
            path: RoutePaths.users,
            name: RouteNames.users,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // 🆕 (Prompt 26): شاشة `features/users/` الفعلية —
              // تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد يخدم إدارة
              // أعضاء الشركة والأدوار معاً (قائمة + لوحة تفاصيل +
              // تعديل دور + دعوة عضو جديد)، بنفس نمط
              // `AnalyticsDashboard` — انظر توثيق القرار الكامل في
              // `users_list.dart`. مُعلَّمة `isDesktopOnly: true` ضمن
              // `AppNavDestinations.users` (`nav_destinations.dart`) —
              // [PlatformGuard] يتولى المنع/التوجيه تلقائياً عند
              // `ShellMode.mobile`، بنفس منطق `RouteNames.analytics`.
              child: const UsersListScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settings,
            name: RouteNames.settings,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // 🆕 (Prompt 27): شاشة `features/settings/` الفعلية —
              // تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد يخدم
              // القائمة الرئيسية فقط (`SettingsScreen`) — بقية الشاشات
              // السبع الفرعية (`ProfileScreen`/`GloveModeSettings`/
              // `DisplaySettings`/`LanguageSettings`/`SyncSettings`/
              // `NotificationSettings`/`AboutScreen`) تُفتح عبر
              // `Navigator.push` مباشرة من `SettingsScreen` نفسها
              // (`MaterialPageRoute`، وليس مسارات `go_router` منفصلة) —
              // انظر توثيق القرار الكامل في `settings_screen.dart` حول
              // سبب عدم تسجيلها كمسارات فرعية مستقلة (بخلاف
              // `RoutePaths.projectDetails` مثلاً): لا شاشة فرعية هنا
              // تحتاج رابطاً مباشراً قابلاً للمشاركة/التنقّل العميق
              // (Deep Link) بذاتها، وكلها تُغلق دوماً بالعودة لنفس
              // القائمة الرئيسية.
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.platformAdmin,
            name: RouteNames.platformAdmin,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              // 🆕 (Prompt 28): شاشة `features/platform_admin/`
              // الفعلية — تستبدل `ComingSoonScreen` المؤقتة. مسار وحيد
              // يخدم كل ألسنة اللوحة السبعة معاً (نظرة عامة/المستأجرون/
              // الاشتراكات/الفوترة/المراقبة/الأخطاء/سجل التدقيق)، بنفس
              // نمط `AnalyticsDashboard`/`UsersListScreen` تماماً —
              // انظر توثيق القرار الكامل في `admin_dashboard.dart`.
              // شاشات `tenant_details.dart`/`tenant_create.dart`/
              // `tenant_data_export.dart` الثلاث لوحات/`Navigator.push`
              // داخلية بالكامل ضمن نفس نسخة `PlatformAdminCubit` —
              // بنفس قرار `settings_screen.dart` (Prompt 27)، لا مسار
              // `go_router` منفصل لأيّها. مُعلَّمة `isDesktopOnly: true`
              // ضمن `AppNavDestinations.platformAdmin`
              // (`nav_destinations.dart`) — [PlatformGuard] يتولى
              // المنع/التوجيه تلقائياً عند `ShellMode.mobile`، تماماً
              // كبقية اللوحات الإدارية أعلاه. الحصر بدور
              // [UserRole.platformOwner] وحده مفروض عبر [RoleGuard] +
              // `Permission.platformManageTenants`
              // (`AppNavDestinations.platformAdmin.requiredPermission`)
              // — وليس هنا.
              child: const PlatformAdminDashboard(),
            ),
          ),
          // بقية الوجهات (...) — شاشة موحّدة
          // مؤقتة [ComingSoonScreen] الآن، يستبدلها كل Prompt لاحق
          // بشاشته الفعلية عبر تعديل `pageBuilder:` هذا فقط لمساره.
          for (final NavDestination destination in AppNavDestinations.all)
            if (destination.routeName != RouteNames.home &&
                destination.routeName != RouteNames.attendance &&
                destination.routeName != RouteNames.tasks &&
                destination.routeName != RouteNames.fieldReports &&
                destination.routeName != RouteNames.photos &&
                destination.routeName != RouteNames.punchList &&
                destination.routeName != RouteNames.projects &&
                destination.routeName != RouteNames.documents &&
                destination.routeName != RouteNames.equipment &&
                destination.routeName != RouteNames.leaveRequests &&
                destination.routeName != RouteNames.analytics &&
                destination.routeName != RouteNames.users &&
                destination.routeName != RouteNames.settings &&
                destination.routeName != RouteNames.platformAdmin)
              GoRoute(
                path: destination.routePath,
                name: destination.routeName,
                pageBuilder: (context, state) => AvahiPageTransitions.fade(
                  key: state.pageKey,
                  child: ComingSoonScreen(title: destination.label),
                ),
              ),
          // ✅ Prompt 16: مسار فرعي مستقل خارج حلقة [AppNavDestinations.all]
          // أعلاه عمداً (ليس وجهة تنقّل رئيسية) — انظر توثيق القرار
          // الكامل في `RouteNames.tasksBoard`/`guards/platform_guard.dart`.
          GoRoute(
            path: RoutePaths.tasksBoard,
            name: RouteNames.tasksBoard,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              child: const TasksBoardScreen(),
            ),
          ),
          // 🆕 (Prompt 23) مسار فرعي مستقل خارج حلقة
          // [AppNavDestinations.all] أعلاه عمداً (ليس وجهة تنقّل
          // رئيسية — لا عنصر جرس ضمن الشريط السفلي/القائمة الجانبية،
          // بل زر جرس مخصّص في `shells/desktop/topbar.dart` فقط)،
          // بنفس منطق `RoutePaths.tasksBoard` تماماً: مسار مستوٍ
          // داخل `ShellRoute` (يحتفظ بحواف التنقّل الثابتة) بلا
          // `extra:` — انظر توثيق القرار الكامل في
          // `RouteNames.notifications`/`notifications_screen.dart`.
          GoRoute(
            path: RoutePaths.notifications,
            name: RouteNames.notifications,
            pageBuilder: (context, state) => AvahiPageTransitions.fade(
              key: state.pageKey,
              child: const NotificationsScreen(),
            ),
          ),
          // 🆕 (Prompt 20) أربعة مسارات فرعية مستقلة تحت `/projects/:id`
          // — داخل نفس `ShellRoute` (تحتفظ بحواف التنقّل الثابتة)، بنفس
          // منطق `RoutePaths.tasksBoard` أعلاه بالضبط: ليست وجهات تنقّل
          // رئيسية ضمن [AppNavDestinations]، لكنها تحتاج شجرة `context`
          // نفسها (`AuthCubit`، إلخ). تستقبل [ProjectRouteArgs] إلزامياً
          // عبر `extra:` (بنفس قيد `RouteNames.punchListDetails` — انظر
          // توثيقه أعلاه، ونفس القيد المقبول أصلاً في `PunchItemDetailsScreen`)
          // — الدخول المباشر (Deep Link) بلا `extra:` غير مدعوم في هذه
          // الخطوة، ويعيد المستخدم إلى `/projects` عبر `errorBuilder`
          // القياسي إن حدث (`state.extra` فارغة تُسبّب استثناء `!`
          // ملتقطاً هناك).
          GoRoute(
            path: RoutePaths.projectDetails,
            name: RouteNames.projectDetails,
            pageBuilder: (context, state) {
              final ProjectRouteArgs args = state.extra! as ProjectRouteArgs;
              return AvahiPageTransitions.fade(
                key: state.pageKey,
                child: ProjectOverviewScreen(args: args),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.projectMembers,
            name: RouteNames.projectMembers,
            pageBuilder: (context, state) {
              final ProjectRouteArgs args = state.extra! as ProjectRouteArgs;
              return AvahiPageTransitions.fade(
                key: state.pageKey,
                child: ProjectMembersScreen(args: args),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.projectMilestones,
            name: RouteNames.projectMilestones,
            pageBuilder: (context, state) {
              final ProjectRouteArgs args = state.extra! as ProjectRouteArgs;
              return AvahiPageTransitions.fade(
                key: state.pageKey,
                child: ProjectMilestonesScreen(args: args),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.projectSettings,
            name: RouteNames.projectSettings,
            pageBuilder: (context, state) {
              final ProjectRouteArgs args = state.extra! as ProjectRouteArgs;
              return AvahiPageTransitions.fade(
                key: state.pageKey,
                child: ProjectSettingsScreen(args: args),
              );
            },
          ),
          // 🆕 (Prompt 21) مسار فرعي مستقل تحت `/documents/:id` — داخل
          // نفس `ShellRoute` (تحتفظ بحواف التنقّل الثابتة)، بنفس منطق
          // `RoutePaths.projectDetails` أعلاه بالضبط: ليس وجهة تنقّل
          // رئيسية ضمن [AppNavDestinations]، لكنه يحتاج شجرة `context`
          // نفسها (`AuthCubit`، إلخ). يستقبل [DocumentRouteArgs] إلزامياً
          // عبر `extra:` (بنفس قيد `RouteNames.projectDetails` أعلاه) —
          // الدخول المباشر (Deep Link) بلا `extra:` غير مدعوم في هذه
          // الخطوة، ويعيد المستخدم إلى `/documents` عبر `errorBuilder`
          // القياسي إن حدث (`state.extra` فارغة تُسبّب استثناء `!`
          // ملتقطاً هناك) — تماماً كما هو الحال بالفعل مع
          // `RoutePaths.projectDetails` وبقية مسارات `/projects/:id`.
          GoRoute(
            path: RoutePaths.documentDetails,
            name: RouteNames.documentDetails,
            pageBuilder: (context, state) {
              final DocumentRouteArgs args = state.extra! as DocumentRouteArgs;
              return AvahiPageTransitions.fade(
                key: state.pageKey,
                child: DocumentViewerScreen(args: args),
              );
            },
          ),
        ],
      ),
      // ✅ Prompt 18: مساران خارج `ShellRoute` عمداً (بنفس منطق `/login`/
      // `/pin` أعلاه) — تدفّق التقاط/ربط صورة يحتاج شاشة كاملة بلا
      // حواف تنقّل ثابتة (شريط سفلي/قائمة جانبية)، ويحتاجان تمرير حالة
      // معقّدة بين الشاشتين (نسخة [PhotosCubit] نفسها + `CapturedImage`)
      // عبر `extra:` في `go_router.push` — غير ممكن بنظافة عبر مسار
      // `ShellRoute` القياسي (`child` مُمرَّر جاهزاً من الشجرة العليا
      // بلا وصول لـ `extra` الخاص بكل GoRoute فرعي بنفس السهولة). انظر
      // توثيق القرار الكامل في `RoutePaths.photosCamera`/`photosAttach`.
      GoRoute(
        path: RoutePaths.photosCamera,
        name: RouteNames.photosCamera,
        pageBuilder: (context, state) {
          final PhotosCubit cubit = state.extra! as PhotosCubit;
          return AvahiPageTransitions.fade(
            key: state.pageKey,
            child: BlocProvider<PhotosCubit>.value(
              value: cubit,
              child: const CameraScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.photosAttach,
        name: RouteNames.photosAttach,
        pageBuilder: (context, state) {
          final PhotoAttachRouteArgs args = state.extra! as PhotoAttachRouteArgs;
          return AvahiPageTransitions.fade(
            key: state.pageKey,
            child: PhotoAttachScreen(args: args),
          );
        },
      ),
      // ✅ Prompt 19: مساران خارج `ShellRoute` عمداً، بنفس منطق
      // `/photos/camera`/`/photos/attach` أعلاه — لكن لسببين مختلفين
      // لكل منهما (انظر توثيق القرار الكامل في `PunchItemCreateScreen`/
      // `PunchItemDetailsRouteArgs`، `features/punch_list/`):
      // `punchListCreate` نقطة دخول *مستقلة* تماماً (نسخة [PunchCubit]
      // خاصة بها، بلا `extra:` إطلاقاً) قد تُفتح مباشرة من الإجراء
      // السريع "تسجيل عيب" في الصفحة الرئيسية دون المرور بـ
      // `/punch-list` أصلاً — تماماً كـ `RouteNames.tasksBoard`.
      // `punchListDetails` بالمقابل تحتاج تمرير حالة حيّة بين شاشتين
      // (نسخة [PunchCubit] الحالية نفسها + [PunchItem] المُختار) عبر
      // `extra:` — تماماً كـ `RoutePaths.photosAttach`.
      GoRoute(
        path: RoutePaths.punchListCreate,
        name: RouteNames.punchListCreate,
        pageBuilder: (context, state) => AvahiPageTransitions.fade(
          key: state.pageKey,
          child: const PunchItemCreateScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.punchListDetails,
        name: RouteNames.punchListDetails,
        pageBuilder: (context, state) {
          final PunchItemDetailsRouteArgs args =
              state.extra! as PunchItemDetailsRouteArgs;
          return AvahiPageTransitions.fade(
            key: state.pageKey,
            child: BlocProvider<PunchCubit>.value(
              value: args.cubit,
              child: PunchItemDetailsScreen(item: args.item),
            ),
          );
        },
      ),
      // 🆕 (Prompt 22): مسار خارج `ShellRoute` عمداً، بنفس منطق
      // `punchListDetails` أعلاه تماماً — يحتاج تمرير حالة حيّة بين
      // شاشتين (نسخة [EquipmentCubit] الحالية نفسها + [Equipment]
      // المُختارة) عبر `extra:` — انظر توثيق القرار الكامل في
      // `RouteNames.equipmentLogUsage`/`log_usage_screen.dart`.
      GoRoute(
        path: RoutePaths.equipmentLogUsage,
        name: RouteNames.equipmentLogUsage,
        pageBuilder: (context, state) {
          final LogUsageRouteArgs args = state.extra! as LogUsageRouteArgs;
          return AvahiPageTransitions.fade(
            key: state.pageKey,
            child: LogUsageScreen(args: args),
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        _NotFoundScreen(location: state.uri.toString()),
  );

  /// سلسلة الحراس الموحّدة — انظر توثيق الترتيب أعلى الصنف. يجلب
  /// المستخدم الحالي **مرة واحدة فقط** هنا (وليس داخل كل حارس على حدة)
  /// عبر `GetCurrentUserUsecase`... تحديداً `IAuthRepository.getCurrentUser()`
  /// مباشرة (الحارس هنا طبقة تنقّل وليس Cubit، فلا حاجة لعبور طبقة
  /// UseCase إضافية لعملية قراءة بسيطة) ويُمرَّر الناتج لكل حارس كقيمة
  /// جاهزة، تفادياً لأربعة استدعاءات شبكة/تخزين محلي متكررة لكل تقييم
  /// مسار واحد.
  Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    // يُقرَأ عرض الشاشة *قبل* أي `await` عمداً: استخدام [context] بعد
    // نقطة تعليق غير متزامنة (Async Gap) غير آمن إن أصبح غير مثبَّت
    // (`!context.mounted`) أثناء الانتظار.
    final ShellMode currentShellMode = ShellMode.fromWidth(
      MediaQuery.sizeOf(context).width,
    );

    final ResultOf<AppUser?> result = await _authRepository.getCurrentUser();
    final AppUser? currentUser = result.fold(
      (Failure _) => null,
      (AppUser? user) => user,
    );

    final String? authRedirect = _authGuard.redirect(
      currentRouteName: state.name,
      currentUser: currentUser,
    );
    if (authRedirect != null) return authRedirect;

    final String? roleRedirect = _roleGuard.redirect(
      currentRouteName: state.name,
      currentUser: currentUser,
    );
    if (roleRedirect != null) return roleRedirect;

    final String? platformRedirect = _platformGuard.redirect(
      currentRouteName: state.name,
      currentShellMode: currentShellMode,
    );
    if (platformRedirect != null) return platformRedirect;

    final String? subscriptionRedirect = _subscriptionGuard.redirect(
      currentRouteName: state.name,
      currentUser: currentUser,
    );
    if (subscriptionRedirect != null) return subscriptionRedirect;

    return null;
  }

  /// يُستدعى من `app.dart` عند إزالة `AvahiApp` (لا يحدث فعلياً على
  /// الويب اليوم، لكن يبقى صحيحاً إدارة الموارد دائماً) — يُلغي اشتراك
  /// [_GoRouterRefreshStream] بـ `watchAuthState()` لتفادي أي تسريب.
  void dispose() {
    _refreshListenable.dispose();
  }
}

/// يحوّل أي `Stream` (هنا `IAuthRepository.watchAuthState()`) إلى
/// `Listenable` يفهمها `GoRouter.refreshListenable` — نمط قياسي موثَّق
/// رسمياً من حزمة `go_router` نفسها لدمجها مع أي مصدر بث حالة خارجي.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    // تقييم فوري عند الإنشاء (بدل الانتظار حتى أول حدث من [stream])
    // بحيث يُقيَّم `initialLocation` مباشرة مقابل حالة المصادقة الحالية
    // فور بناء [GoRouter] نفسه.
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// صفحة 404 بسيطة — تُعرض عند أي مسار غير معرَّف في [AppRouter.router]
/// (`errorBuilder`)، مع زر عودة صريح للرئيسية بدل ترك المستخدم في
/// طريق مسدود.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.search_off, size: 48),
              const SizedBox(height: 16),
              Text(
                'الصفحة غير موجودة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                location,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.goNamed(RouteNames.home),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
