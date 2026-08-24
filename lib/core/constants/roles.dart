/// أدوار المستخدمين المدعومة في نظام Avahi، مرتبة تصاعدياً من الأقل
/// صلاحية (worker) إلى الأعلى صلاحية (platformOwner).
///
/// ⚠️ هذا التعداد هو المصدر الوحيد للحقيقة (Single Source of Truth)
/// لأدوار النظام. أي جدول قاعدة بيانات لاحقاً (Prompt 03، عمود
/// `role` في جدول `profiles`) يجب أن يعتمد على القيم النصية هنا
/// (`UserRole.name`) لضمان التطابق بين Flutter وSupabase/Postgres.
enum UserRole {
  /// عامل ميداني: تسجيل حضور، مهام مُسندة إليه، تقارير ميدانية بسيطة.
  worker,

  /// رئيس عمال/مشرف مباشر: يدير فريق عمال، يعتمد الحضور، يوزع المهام.
  foreman,

  /// مهندس موقع: صلاحيات فنية أوسع (تقارير، قوائم الملاحظات، مستندات).
  engineer,

  /// مدير مشروع: صلاحيات إدارية على مستوى مشروع واحد أو أكثر.
  projectManager,

  /// مدير نظام (على مستوى المستأجر/الشركة الواحدة، Tenant Admin).
  admin,

  /// مالك المنصة: صلاحيات كاملة عابرة لكل المستأجرين (Platform Admin).
  platformOwner;

  /// الترتيب الرقمي للدور، الأكبر = صلاحيات أوسع. مفيد للمقارنات
  /// السريعة (مثال: `role.rank >= UserRole.projectManager.rank`).
  int get rank => index;

  bool get isWorker => this == UserRole.worker;
  bool get isForeman => this == UserRole.foreman;
  bool get isEngineer => this == UserRole.engineer;
  bool get isProjectManager => this == UserRole.projectManager;
  bool get isAdmin => this == UserRole.admin;
  bool get isPlatformOwner => this == UserRole.platformOwner;

  /// صحيح لأي دور إداري بمستوى مستأجر واحد أو أعلى (admin/platformOwner
  /// مستثنيان بمعنى مختلف؛ يُستخدم للتحكم بواجهات الإدارة العامة).
  bool get isTenantManagement =>
      this == UserRole.projectManager || this == UserRole.admin;

  /// يحوّل نصاً (كما يُخزَّن في Supabase) إلى [UserRole] مع قيمة
  /// افتراضية آمنة (`worker`) عند عدم التطابق، بدل رمي استثناء.
  static UserRole fromName(String value) {
    return UserRole.values.firstWhere(
      (UserRole r) => r.name == value,
      orElse: () => UserRole.worker,
    );
  }
}
