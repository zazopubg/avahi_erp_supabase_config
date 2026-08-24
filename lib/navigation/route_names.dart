/// أسماء المسارات (Route Names) المستخدمة مع `go_router` — تُمرَّر
/// كخاصية `name:` لكل `GoRoute` وتُستخدم للتنقل الآمن عبر
/// `context.goNamed(RouteNames.home)` بدل الاعتماد على نصوص مسارات
/// خام (`context.go('/home')`) المعرَّضة لأخطاء كتابة صامتة.
///
/// ⚠️ مصدر الحقيقة الوحيد لأسماء المسارات في التطبيق كاملاً. أي حارس
/// (`guards/`) أو قالب (`shells/`) يحتاج مقارنة الموقع الحالي يعتمد
/// على هذه الثوابت حصراً بدل سلاسل نصية حرة، لتجنّب أخطاء الطباعة
/// وتسهيل إعادة التسمية لاحقاً عبر بحث/استبدال واحد.
///
/// مُقسَّمة إلى مجموعتين:
/// 1. مسارات خارج القالب الرئيسي (Auth Flow): `splash`, `login`, `pin`,
///    `companySelect` — تُبنى فعلياً في `features/auth/` (Prompt 13).
/// 2. مسارات داخل `AdaptiveShell` (وجهات التنقل الرئيسية): `home` وبقية
///    الميزات — كل ميزة تستبدل شاشتها المؤقتة (`placeholder_screens.dart`)
///    بشاشتها الحقيقية عند بنائها (Prompt 14 وما بعده) دون أي تعديل على
///    هذا الملف أو على `app_router.dart` نفسه (فقط استبدال `builder:`
///    للمسار المعني).
abstract final class RouteNames {
  // ── تدفّق الدخول (Auth Flow) — خارج AdaptiveShell ────────────────
  static const String splash = 'splash';
  static const String login = 'login';
  static const String pin = 'pin';
  static const String companySelect = 'companySelect';
  static const String forgotPassword = 'forgotPassword';

  // ── وجهات AdaptiveShell الرئيسية ─────────────────────────────────
  static const String home = 'home';
  static const String attendance = 'attendance';
  static const String tasks = 'tasks';

  /// ✅ Prompt 16: مسار فرعي (وليس وجهة تنقّل رئيسية) — لوحة Kanban
  /// الكاملة لسطح المكتب فقط، تُفتح من زر داخل `tasks_list_screen.dart`
  /// (`RouteNames.tasks`)، محمي بـ [PlatformGuard] (انظر
  /// `_additionalDesktopOnlyRoutes` في `guards/platform_guard.dart`)
  /// بدل [AppNavDestinations] عمداً — انظر توثيق القرار هناك.
  static const String tasksBoard = 'tasksBoard';
  static const String fieldReports = 'fieldReports';
  static const String photos = 'photos';

  /// ✅ Prompt 18: انظر توثيق القرار الكامل في
  /// `RoutePaths.photosCamera`/`RoutePaths.photosAttach`.
  static const String photosCamera = 'photosCamera';
  static const String photosAttach = 'photosAttach';

  static const String punchList = 'punchList';

  /// 🆕 (Prompt 19) مساران فرعيان تحت `/punch-list` (وليسا وجهتي
  /// تنقّل رئيسيتين ضمن [AppNavDestinations] — بنفس منطق
  /// `RouteNames.tasksBoard`/`photosCamera`/`photosAttach` أعلاه):
  /// `punchListCreate` نقطة دخول مستقلة تماماً (نسخة `PunchCubit`
  /// خاصة بها عبر `sl<PunchCubit>()..loadInitial(user)`، بنفس نمط
  /// `RouteNames.tasksBoard`) — يفتحها إما زر "+" داخل
  /// `punch_list_screen.dart` أو الإجراء السريع "تسجيل عيب" في
  /// `features/home/presentation/widgets/quick_actions.dart` مباشرة
  /// دون المرور بـ `/punch-list` أصلاً. `punchListDetails` تستقبل
  /// [PunchItem]/`PunchCubit` الحاليين معاً عبر `extra:` (بنفس منطق
  /// `RoutePaths.photosAttach`) من `punch_list_screen.dart` فقط —
  /// انظر توثيق القرار الكامل في `app_router.dart`.
  static const String punchListCreate = 'punchListCreate';
  static const String punchListDetails = 'punchListDetails';
  static const String projects = 'projects';
  // 🆕 (Prompt 20) — انظر توثيق القرار الكامل في
  // `RoutePaths.projectDetails`/`app_router.dart`.
  static const String projectDetails = 'projectDetails';
  static const String projectMembers = 'projectMembers';
  static const String projectMilestones = 'projectMilestones';
  static const String projectSettings = 'projectSettings';
  static const String documents = 'documents';

  /// 🆕 (Prompt 21) مسار فرعي تحت `/documents` (وليس وجهة تنقّل رئيسية
  /// ضمن [AppNavDestinations] — بنفس منطق `RouteNames.projectDetails`
  /// تماماً، `:id` هو `Document.id`). يستقبل [DocumentRouteArgs] إلزامياً
  /// عبر `extra:` (نفس القيد المقبول أصلاً في `RouteNames.projectDetails`/
  /// `punchListDetails`) — انظر توثيق القرار الكامل في `app_router.dart`.
  static const String documentDetails = 'documentDetails';
  static const String equipment = 'equipment';

  /// 🆕 (Prompt 22) مسار فرعي مستقل تحت `/equipment` (وليس وجهة تنقّل
  /// رئيسية ضمن [AppNavDestinations] — بنفس منطق `RouteNames.tasksBoard`/
  /// `RouteNames.punchListCreate` تماماً): شاشة كاملة بلا حواف تنقّل
  /// ثابتة لتسجيل قراءة ساعات تشغيل يومية، تستقبل [LogUsageRouteArgs]
  /// إلزامياً عبر `extra:` (نسخة [EquipmentCubit] الحيّة + [Equipment]
  /// المُختارة، بنفس قيد `RouteNames.punchListDetails`) — انظر توثيق
  /// القرار الكامل في `log_usage_screen.dart`/`app_router.dart`.
  static const String equipmentLogUsage = 'equipmentLogUsage';

  /// 🆕 (Prompt 23) مسار فرعي مستقل (وليس وجهة تنقّل رئيسية ضمن
  /// [AppNavDestinations] — لا يوجد جرس/مركز إشعارات ضمن الشريط
  /// السفلي/القائمة الجانبية الأساسية، بل زر جرس مخصّص في
  /// `shells/desktop/topbar.dart` فقط، بنفس استثناء
  /// `RouteNames.tasksBoard`): شاشة قائمة إشعارات كاملة موحَّدة لكل
  /// المنصات، بلا `extra:` (تُحمِّل بياناتها ذاتياً عبر `AuthCubit` +
  /// `NotificationsCubit` خاصة بها، بنفس نمط `RouteNames.documents`)
  /// — انظر توثيق القرار الكامل في `notifications_screen.dart`.
  static const String notifications = 'notifications';
  static const String leaveRequests = 'leaveRequests';
  static const String analytics = 'analytics';
  static const String users = 'users';
  static const String settings = 'settings';
  static const String platformAdmin = 'platformAdmin';

  /// أسماء مسارات تدفّق الدخول التي يجب أن تبقى متاحة بدون جلسة
  /// نشطة — يعتمدها [AuthGuard] مباشرة (انظر `guards/auth_guard.dart`).
  static const Set<String> publicRoutes = <String>{
    splash,
    login,
    pin,
    companySelect,
    forgotPassword,
  };
}
