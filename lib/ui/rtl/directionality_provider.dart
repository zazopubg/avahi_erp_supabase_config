import 'package:flutter/material.dart';

/// يضبط اتجاه شجرة الواجهة (RTL/LTR) بناءً على رمز اللغة الحالي.
///
/// التطبيق يدعم العربية (RTL افتراضياً) والإنجليزية (LTR)، ويعتمد على
/// [Directionality] القياسي في Flutter لضبط اتجاه كل الـ widgets
/// تلقائياً (padding, alignment, icons... إلخ) بدل الاعتماد على قيم
/// left/right يدوية في أي مكان بالتطبيق — استخدم بدلاً من ذلك
/// الامتدادات المنطقية (start/end) في `logical_extensions.dart`.
class AvahiDirectionalityProvider extends StatelessWidget {
  const AvahiDirectionalityProvider({
    required this.locale,
    required this.child,
    super.key,
  });

  /// اللغة الحالية للتطبيق (مثال: `Locale('ar')` أو `Locale('en')`).
  final Locale locale;

  final Widget child;

  /// مجموعة رموز اللغات التي تُعرض من اليمين لليسار.
  static const Set<String> _rtlLanguageCodes = <String>{
    'ar', // العربية
    'he', // العبرية
    'fa', // الفارسية
    'ur', // الأردية
  };

  /// يحدد ما إذا كانت لغة معيّنة تُعرض RTL.
  static bool isRtl(Locale locale) =>
      _rtlLanguageCodes.contains(locale.languageCode);

  /// اتجاه النص المقابل للغة معيّنة.
  static TextDirection directionOf(Locale locale) =>
      isRtl(locale) ? TextDirection.rtl : TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: directionOf(locale),
      child: child,
    );
  }
}

/// امتداد مساعد للوصول السريع لاتجاه النص الحالي من [BuildContext].
extension DirectionalityContext on BuildContext {
  TextDirection get textDirection => Directionality.of(this);

  bool get isRtl => textDirection == TextDirection.rtl;

  bool get isLtr => textDirection == TextDirection.ltr;
}
