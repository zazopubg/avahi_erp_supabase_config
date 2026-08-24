import 'package:flutter/material.dart';

/// أسماء عائلات الخطوط المسجّلة في `pubspec.yaml`.
abstract class AvahiFontFamily {
  /// الخط الأساسي للنصوص العامة والواجهة (عربي/إنجليزي).
  static const String primary = 'Cairo';

  /// خط ثانوي يُستخدم خصيصاً **للأرقام والبيانات** (لوحات المعلومات،
  /// الإحصاءات، الأرقام التعريفية) لوضوح أكبر في القراءة الرقمية.
  static const String numeric = 'IBMPlexSansArabic';
}

/// نظام الطباعة الكامل لتطبيق Avahi، مبني فوق [TextTheme] الخاص بـ
/// Material 3.
///
/// - [primary] (خط Cairo): يُستخدم لكل العناوين والنصوص العامة.
/// - [numeric] (خط IBM Plex Sans Arabic): نسخة موازية لكل الأنماط
///   لاستخدامها في عرض الأرقام والبيانات (استخدم [AvahiTypography.numeric]
///   أو [NumericTextStyle] عند عرض أرقام إحصائية أو معرّفات).
@immutable
class AvahiTypography {
  const AvahiTypography._();

  /// نص التطبيق الأساسي (Cairo) المبني على مقاييس Material 3 Type Scale.
  static TextTheme primary(TextTheme base, Color color) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w700,
            fontSize: 57,
            height: 1.12,
            color: color,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w700,
            fontSize: 45,
            height: 1.16,
            color: color,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w700,
            fontSize: 36,
            height: 1.22,
            color: color,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w700,
            fontSize: 32,
            height: 1.25,
            color: color,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w600,
            fontSize: 28,
            height: 1.29,
            color: color,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w600,
            fontSize: 24,
            height: 1.33,
            color: color,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w600,
            fontSize: 22,
            height: 1.27,
            color: color,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1.5,
            color: color,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.43,
            color: color,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w400,
            fontSize: 16,
            height: 1.5,
            color: color,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.43,
            color: color,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 1.33,
            color: color,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.43,
            color: color,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.33,
            color: color,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontFamily: AvahiFontFamily.primary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            height: 1.45,
            color: color,
          ),
        )
        .apply(fontFamily: AvahiFontFamily.primary);
  }

  /// نمط نصي مخصص لعرض **الأرقام والبيانات** (خط IBM Plex Sans Arabic).
  ///
  /// يُستخدم مثلاً في: عدّادات لوحة المعلومات، الأرقام التعريفية،
  /// الأسعار، الطوابع الزمنية الرقمية... إلخ.
  static TextStyle numeric({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: AvahiFontFamily.numeric,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }
}

/// امتداد يسمح بتحويل أي [TextStyle] موجود إلى نمط "رقمي" (خط
/// IBM Plex Sans Arabic مع أرقام جدولية) بسهولة:
/// `Theme.of(context).textTheme.titleLarge!.numeric`.
extension NumericTextStyle on TextStyle {
  TextStyle get numeric => copyWith(
        fontFamily: AvahiFontFamily.numeric,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );
}
