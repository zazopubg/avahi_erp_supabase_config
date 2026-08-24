import 'package:flutter/material.dart';

/// يحصر عامل تكبير النص (textScaleFactor / TextScaler) القادم من إعدادات
/// نظام تشغيل المستخدم ضمن حدود آمنة لتفادي كسر تخطيط الواجهة.
///
/// الحد الأدنى: [minScale] = 0.85
/// الحد الأقصى: [maxScale] = 1.4
///
/// يُستخدم بلفّ أي شجرة widgets (عادة على مستوى `MaterialApp.builder`):
///
/// ```dart
/// MaterialApp.router(
///   builder: (context, child) => TextScaleGuard(child: child!),
///   ...
/// )
/// ```
///
/// 🆕 (Prompt 27) [userScale]: مضاعِف إضافي يتحكم به المستخدم يدوياً
/// من `display_settings.dart` عبر `TextScaleCubit` (`ui/modes/
/// text_scale_provider.dart`) — يُطبَّق **فوق** عامل النظام (وليس
/// بديلاً عنه) قبل إعادة الحصر ضمن [minScale]/[maxScale] نفسهما، بحيث
/// يبقى الناتج النهائي دوماً آمناً بصرف النظر عن تركيبة القيمتين.
/// القيمة الافتراضية `1.0` (بلا أي تأثير إضافي) تُبقي كل استدعاء سابق
/// لهذا الودجة (`app.dart` قبل Prompt 27) يعمل دون أي تعديل مطلوب.
class TextScaleGuard extends StatelessWidget {
  const TextScaleGuard({
    required this.child,
    super.key,
    this.minScale = 0.85,
    this.maxScale = 1.4,
    this.userScale = 1.0,
  });

  /// الحد الأدنى المسموح به لعامل تكبير النص.
  final double minScale;

  /// الحد الأقصى المسموح به لعامل تكبير النص.
  final double maxScale;

  /// مضاعِف إضافي بتحكم المستخدم — انظر توثيق القرار أعلاه.
  final double userScale;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double systemFactor = mediaQuery.textScaler
        .clamp(minScaleFactor: minScale, maxScaleFactor: maxScale)
        .scale(1.0);
    final TextScaler clampedScaler = TextScaler.linear(systemFactor * userScale)
        .clamp(minScaleFactor: minScale, maxScaleFactor: maxScale);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedScaler),
      child: child,
    );
  }
}
