/// نظام المسافات الموحّد لتطبيق Avahi، مبني على وحدة أساس 4px.
///
/// استخدم هذه الثوابت بدلاً من أرقام Padding/Margin الحرّة للحفاظ على
/// اتساق بصري عبر كل شاشات التطبيق.
abstract class AvahiSpacing {
  /// 0px
  static const double none = 0;

  /// 4px — أصغر وحدة مسافة (بين عناصر متلاصقة جداً).
  static const double xxs = 4;

  /// 8px
  static const double xs = 8;

  /// 12px
  static const double sm = 12;

  /// 16px — المسافة الافتراضية الأكثر استخداماً (padding الشاشات مثلاً).
  static const double md = 16;

  /// 24px
  static const double lg = 24;

  /// 32px
  static const double xl = 32;

  /// 40px
  static const double xxl = 40;

  /// 48px
  static const double xxxl = 48;

  /// 64px — أكبر وحدة مسافة (فواصل أقسام كبيرة).
  static const double huge = 64;
}
