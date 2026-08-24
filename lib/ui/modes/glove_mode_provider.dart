import 'package:flutter_bloc/flutter_bloc.dart';

/// **وضع القفازات (Glove Mode)**: وضع عرض خاص يكبّر مناطق اللمس والعناصر
/// التفاعلية في الميدان (حيث يرتدي العمال قفازات سميكة تصعّب اللمس
/// الدقيق على الشاشة).
///
/// حالة بسيطة جداً — قيمة `bool` واحدة تُبدَّل عبر [GloveModeCubit.toggle].
/// لا يحتوي على أي منطق تخزين دائم (Persistence) في هذه الخطوة؛ سيُضاف
/// لاحقاً عند ربط طبقة `core/services` (Prompt 02) أو التخزين المحلي.
class GloveModeCubit extends Cubit<bool> {
  /// ينشئ Cubit بحالة ابتدائية `false` (الوضع العادي) ما لم يُحدَّد
  /// خلاف ذلك عبر [initialValue].
  GloveModeCubit({bool initialValue = false}) : super(initialValue);

  /// تفعيل وضع القفازات.
  void enable() => emit(true);

  /// تعطيل وضع القفازات.
  void disable() => emit(false);

  /// تبديل الحالة الحالية.
  void toggle() => emit(!state);
}
