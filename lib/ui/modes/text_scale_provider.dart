import 'package:flutter_bloc/flutter_bloc.dart';

/// 🆕 (Prompt 27) عامل تكبير نص إضافي يتحكم به المستخدم يدوياً من
/// `display_settings.dart` — منفصل تماماً عن عامل تكبير النص القادم
/// من إعدادات نظام تشغيل/متصفح المستخدم (الذي يتولى حصره أصلاً
/// [TextScaleGuard]، Prompt 01).
///
/// القيمة هنا **مضاعِف إضافي** (Multiplier) يُطبَّق فوق ذلك العامل
/// النظامي المحصور مسبقاً (وليس بديلاً عنه) — انظر التركيب الكامل في
/// [TextScaleGuard.userScale] — بحيث يبقى المستخدم قادراً على تكبير
/// النص يدوياً من داخل التطبيق حتى إن كان نظام تشغيله لا يوفّر ذلك
/// أصلاً (أو يريد تكبيراً إضافياً فوق ما يوفّره نظامه).
///
/// محصور بين [minScale] و[maxScale] (نفس حدود [TextScaleGuard]
/// الافتراضية 0.85–1.4) لمنع كسر تخطيط الواجهة.
class TextScaleCubit extends Cubit<double> {
  TextScaleCubit({double initialScale = 1.0})
      : super(initialScale.clamp(minScale, maxScale));

  static const double minScale = 0.85;
  static const double maxScale = 1.4;

  /// خطوة تغيير قياسية لأزرار +/- في `display_settings.dart`.
  static const double step = 0.05;

  void setScale(double scale) => emit(scale.clamp(minScale, maxScale));

  void increase() => setScale(state + step);

  void decrease() => setScale(state - step);

  void reset() => emit(1.0);

  bool get isAtDefault => state == 1.0;
}
