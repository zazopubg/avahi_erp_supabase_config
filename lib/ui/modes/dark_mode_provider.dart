import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// يدير وضع السمة الحالي (فاتح/داكن/تلقائي بحسب النظام) عبر [ThemeMode]
/// القياسي في Flutter.
///
/// الحالة الابتدائية الافتراضية هي [ThemeMode.system] (اتباع إعداد نظام
/// التشغيل). لا يحتوي على أي منطق تخزين دائم في هذه الخطوة؛ سيُضاف لاحقاً
/// عند ربط طبقة `core/services` (Prompt 02).
class DarkModeCubit extends Cubit<ThemeMode> {
  DarkModeCubit({ThemeMode initialMode = ThemeMode.system})
      : super(initialMode);

  void useLight() => emit(ThemeMode.light);

  void useDark() => emit(ThemeMode.dark);

  void useSystem() => emit(ThemeMode.system);

  /// تبديل بسيط بين الفاتح والداكن (يتجاهل System عند التبديل اليدوي).
  void toggle() {
    emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
