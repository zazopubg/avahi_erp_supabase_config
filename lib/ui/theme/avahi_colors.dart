import 'package:flutter/material.dart';

/// نظام الألوان الكامل لتطبيق Avahi.
///
/// يعتمد على نظام ألوان **دلالي (Semantic)** بحيث يُستخدم كل لون
/// للدلالة على معنى ثابت في كل أنحاء التطبيق:
/// - 🟢 أخضر  → مكتمل / متزامن (Synced / Completed)
/// - 🔴 أحمر  → متأخر / خطأ (Overdue / Error)
/// - 🟡 أصفر  → جارٍ / قيد الانتظار (Pending / In Progress)
/// - 🔵 أزرق  → معلومات (Informational)
///
/// يوفر هذا الملف نسختين كاملتين: [AvahiColors.light] و [AvahiColors.dark].
@immutable
class AvahiColors {
  const AvahiColors({
    required this.brightness,
    // ── العلامة التجارية ────────────────────────────────────
    required this.brand,
    required this.brandOnBrand,
    required this.brandContainer,
    required this.onBrandContainer,
    // ── الخلفيات والأسطح ─────────────────────────────────────
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    // ── الحالات الدلالية: النجاح/الاكتمال/التزامن ────────────
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    // ── الحالات الدلالية: الخطر/الخطأ/التأخر ─────────────────
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
    // ── الحالات الدلالية: التحذير/الانتظار/الجاري ────────────
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    // ── الحالات الدلالية: المعلومات ───────────────────────────
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    // ── حالات إضافية شائعة الاستخدام ─────────────────────────
    required this.disabled,
    required this.onDisabled,
    required this.shadow,
    required this.scrim,
    required this.overlay,
  });

  final Brightness brightness;

  final Color brand;
  final Color brandOnBrand;
  final Color brandContainer;
  final Color onBrandContainer;

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  final Color disabled;
  final Color onDisabled;
  final Color shadow;
  final Color scrim;
  final Color overlay;

  // ── النسخة الفاتحة (Light) ────────────────────────────────
  static const AvahiColors light = AvahiColors(
    brightness: Brightness.light,
    brand: Color(0xFF0F6E4F),
    brandOnBrand: Color(0xFFFFFFFF),
    brandContainer: Color(0xFFD3F3E0),
    onBrandContainer: Color(0xFF00391F),
    background: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEEF0F3),
    surfaceElevated: Color(0xFFFFFFFF),
    onBackground: Color(0xFF1A1C1E),
    onSurface: Color(0xFF1A1C1E),
    onSurfaceVariant: Color(0xFF43474E),
    outline: Color(0xFFCBD0D6),
    outlineVariant: Color(0xFFE1E4E8),
    success: Color(0xFF1E8E5A),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFD8F4E4),
    onSuccessContainer: Color(0xFF0A3D25),
    danger: Color(0xFFD9342B),
    onDanger: Color(0xFFFFFFFF),
    dangerContainer: Color(0xFFFBDAD7),
    onDangerContainer: Color(0xFF5C1410),
    warning: Color(0xFFC98A02),
    onWarning: Color(0xFF3A2900),
    warningContainer: Color(0xFFFCEBBE),
    onWarningContainer: Color(0xFF3A2900),
    info: Color(0xFF1D6FC9),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFD9E8FB),
    onInfoContainer: Color(0xFF0B2E52),
    disabled: Color(0xFFC7CACD),
    onDisabled: Color(0xFF8A8D91),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    overlay: Color(0x14000000),
  );

  // ── النسخة الداكنة (Dark) ──────────────────────────────────
  static const AvahiColors dark = AvahiColors(
    brightness: Brightness.dark,
    brand: Color(0xFF63D9A6),
    brandOnBrand: Color(0xFF00391F),
    brandContainer: Color(0xFF00542F),
    onBrandContainer: Color(0xFFD3F3E0),
    background: Color(0xFF121316),
    surface: Color(0xFF1B1D20),
    surfaceVariant: Color(0xFF25282C),
    surfaceElevated: Color(0xFF2A2D31),
    onBackground: Color(0xFFE3E4E6),
    onSurface: Color(0xFFE3E4E6),
    onSurfaceVariant: Color(0xFFC3C7CC),
    outline: Color(0xFF44474C),
    outlineVariant: Color(0xFF34373B),
    success: Color(0xFF5FCF9A),
    onSuccess: Color(0xFF073622),
    successContainer: Color(0xFF0B4A2E),
    onSuccessContainer: Color(0xFFC0F0D6),
    danger: Color(0xFFEB6A61),
    onDanger: Color(0xFF3E0906),
    dangerContainer: Color(0xFF6E1F19),
    onDangerContainer: Color(0xFFFAD3CF),
    warning: Color(0xFFE8B646),
    onWarning: Color(0xFF3A2900),
    warningContainer: Color(0xFF574000),
    onWarningContainer: Color(0xFFFAE3AC),
    info: Color(0xFF6FAAEE),
    onInfo: Color(0xFF072A4C),
    infoContainer: Color(0xFF0E3B69),
    onInfoContainer: Color(0xFFD2E4FB),
    disabled: Color(0xFF3C3F43),
    onDisabled: Color(0xFF75787C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    overlay: Color(0x1FFFFFFF),
  );

  /// إرجاع النسخة المناسبة بحسب [Brightness] الحالي.
  static AvahiColors of(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// امتداد للوصول السريع لـ [AvahiColors] من أي [BuildContext]
/// عبر: `context.avahiColors`.
extension AvahiColorsContext on BuildContext {
  AvahiColors get avahiColors => AvahiColors.of(Theme.of(this).brightness);
}
