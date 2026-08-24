/// مسارات URL (Route Paths) الفعلية المستخدمة مع `go_router`. مطابقة
/// واحد لواحد مع [RouteNames] (`route_names.dart`) — أي إضافة مسار
/// جديد هنا تتطلب إضافة اسم مقابل هناك، والعكس.
///
/// ⚠️ كل وجهات `AdaptiveShell` مسارات **جذرية مستوية واحدة** (Top-level
/// Siblings، مثل `/home`، `/attendance`، `/tasks`...) وليست متداخلة
/// تحت `/home` — هذا هو النمط القياسي لـ `ShellRoute` في `go_router`
/// عندما يمثّل القالب تنقّلاً بين تبويبات/أقسام متكافئة (شريط سفلي أو
/// قائمة جانبية)، بدل تسلسل هرمي فعلي بين الميزات نفسها.
abstract final class RoutePaths {
  // ── تدفّق الدخول (Auth Flow) ──────────────────────────────────────
  /// مسار البداية (`initialLocation` في `app_router.dart`) — شاشة
  /// عابرة يحسم [AuthGuard] فورياً وجهتها الفعلية (`/login` أو `/home`).
  static const String splash = '/';
  static const String login = '/login';
  static const String pin = '/pin';
  static const String companySelect = '/company-select';
  static const String forgotPassword = '/forgot-password';

  // ── وجهات AdaptiveShell الرئيسية ─────────────────────────────────
  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String tasks = '/tasks';

  /// ✅ Prompt 16: مسار فرعي حقيقي تحت `/tasks` (وليس وجهة `AdaptiveShell`
  /// مستوية مستقلة كبقية هذه القائمة) — انظر توثيق [RouteNames.tasksBoard].
  static const String tasksBoard = '/tasks/board';
  static const String fieldReports = '/field-reports';
  static const String photos = '/photos';

  /// ✅ Prompt 18: مساران فرعيان **خارج** `ShellRoute` عمداً (بنفس
  /// منطق `/login`/`/pin` أعلاه) — تدفّق التقاط/ربط صورة يحتاج شاشة
  /// كاملة بلا حواف تنقّل ثابتة (شريط سفلي/قائمة جانبية)، تماماً كما
  /// لا تظهر تلك الحواف أثناء تسجيل الدخول. `photo_attach_screen.dart`
  /// يستقبل الصورة الملتقطة عبر `extra:` في `go_router.push` (وليس عبر
  /// معامل مسار نصي) — انظر توثيق القرار في `app_router.dart`.
  static const String photosCamera = '/photos/camera';
  static const String photosAttach = '/photos/attach';

  static const String punchList = '/punch-list';
  // 🆕 (Prompt 19) — انظر توثيق القرار الكامل في route_names.dart وapp_router.dart.
  static const String punchListCreate = '/punch-list/create';
  static const String punchListDetails = '/punch-list/details';
  static const String projects = '/projects';
  // 🆕 (Prompt 20) — مسارات فرعية مستوية داخل `ShellRoute` (تحتفظ
  // بحواف التنقّل الثابتة)، بنفس نمط `RoutePaths.tasksBoard`
  // (Prompt 16) وليس بنمط `punchListCreate`/`punchListDetails`
  // (خارج `ShellRoute`) — انظر توثيق القرار الكامل في
  // `route_names.dart`/`app_router.dart`. `:id` هو `Project.id`.
  static const String projectDetails = '/projects/:id';
  static const String projectMembers = '/projects/:id/members';
  static const String projectMilestones = '/projects/:id/milestones';
  static const String projectSettings = '/projects/:id/settings';
  static const String documents = '/documents';
  // 🆕 (Prompt 21) — بنفس نمط `RoutePaths.projectDetails` تماماً
  // (مسار فرعي مستوٍ داخل `ShellRoute`، يحتفظ بحواف التنقّل الثابتة).
  // `:id` هو `Document.id` — انظر توثيق القرار الكامل في
  // `route_names.dart`/`app_router.dart`.
  static const String documentDetails = '/documents/:id';
  static const String equipment = '/equipment';
  // 🆕 (Prompt 22) — خارج `ShellRoute` عمداً، بنفس نمط
  // `RoutePaths.punchListCreate`/`punchListDetails` — انظر توثيق
  // القرار الكامل في `RouteNames.equipmentLogUsage`.
  static const String equipmentLogUsage = '/equipment/log-usage';
  // 🆕 (Prompt 23) — مسار مستوٍ داخل `ShellRoute` (يحتفظ بحواف
  // التنقّل الثابتة، بنفس نمط `RoutePaths.tasksBoard` وليس بنمط
  // `punchListCreate`/`equipmentLogUsage` خارج `ShellRoute`) — انظر
  // توثيق القرار الكامل في `route_names.dart`/`app_router.dart`.
  static const String notifications = '/notifications';
  static const String leaveRequests = '/leave-requests';
  static const String analytics = '/analytics';
  static const String users = '/users';
  static const String settings = '/settings';
  static const String platformAdmin = '/platform-admin';
}
