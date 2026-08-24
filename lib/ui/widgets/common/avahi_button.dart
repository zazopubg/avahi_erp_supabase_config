import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../modes/glove_mode_provider.dart';
import '../../theme/avahi_spacing.dart';

/// أنماط الزر المتاحة في نظام التصميم.
enum AvahiButtonVariant {
  /// زر أساسي مملوء (Primary / Elevated).
  primary,

  /// زر ثانوي بحدود فقط (Outlined).
  secondary,

  /// زر نصي بدون خلفية أو حدود (Text).
  text,

  /// زر دلالي للحالات الخطرة (حذف، إلغاء نهائي).
  danger,
}

/// أحجام الزر المتاحة.
enum AvahiButtonSize { small, medium, large }

/// زر Avahi الموحّد — غلاف نظيف فوق أزرار Material 3 القياسية يطبّق
/// أنماط وأحجام نظام التصميم مباشرة، مع دعم حالة التحميل والتعطيل.
///
/// لا يحتوي على أي منطق عمل أو استدعاء API — مكوّن عرض بحت.
class AvahiButton extends StatelessWidget {
  const AvahiButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = AvahiButtonVariant.primary,
    this.size = AvahiButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  /// نص الزر.
  final String label;

  /// دالة الضغط؛ عند تركها `null` يظهر الزر معطّلاً تلقائياً.
  final VoidCallback? onPressed;

  final AvahiButtonVariant variant;
  final AvahiButtonSize size;

  /// أيقونة اختيارية تُعرض قبل النص (تُحترم اتجاهياً تلقائياً عبر Row).
  final IconData? icon;

  /// عند `true`، يُستبدل محتوى الزر بمؤشر تحميل دائري ويُعطَّل الضغط.
  final bool isLoading;

  /// عند `true`، يمتد الزر ليملأ العرض المتاح بالكامل.
  final bool isFullWidth;

  double get _height => switch (size) {
        AvahiButtonSize.small => 36,
        AvahiButtonSize.medium => 44,
        AvahiButtonSize.large => 52,
      };

  /// 🆕 (Prompt 27) ارتفاع الزر الفعلي عند تفعيل وضع القفازات — يزيد
  /// كل حجم بـ 14 نقطة إضافية (منطقة لمس أوسع بوضوح دون أن تتضاعف
  /// الأحجام الثلاثة لتتشابه ببعضها). القيمة الأساس تبقى [_height]
  /// نفسها المستخدمة عند التعطيل — لا تغيير في السلوك القديم.
  double _effectiveHeight(bool isGloveMode) =>
      isGloveMode ? _height + 14 : _height;

  EdgeInsetsGeometry get _padding => switch (size) {
        AvahiButtonSize.small => const EdgeInsets.symmetric(
            horizontal: AvahiSpacing.sm,
          ),
        AvahiButtonSize.medium => const EdgeInsets.symmetric(
            horizontal: AvahiSpacing.lg,
          ),
        AvahiButtonSize.large => const EdgeInsets.symmetric(
            horizontal: AvahiSpacing.xl,
          ),
      };

  /// 🆕 (Prompt 27) حشوة أفقية إضافية عند وضع القفازات — تكبّر منطقة
  /// اللمس أفقياً بقدر ما تكبّرها [_effectiveHeight] عمودياً.
  EdgeInsetsGeometry _effectivePadding(bool isGloveMode) {
    if (!isGloveMode) return _padding;
    final EdgeInsets base = _padding as EdgeInsets;
    return base + const EdgeInsets.symmetric(horizontal: AvahiSpacing.xs);
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 (Prompt 27) — أول استهلاك فعلي لـ [GloveModeCubit] عبر كل
    // التطبيق منذ إنشائه في Prompt 01 (كان يُوفَّر عبر `app.dart` دون
    // أي widget يقرأ حالته فعلياً حتى الآن). `context.watch` هنا
    // يعني أن **كل** استخدام لـ [AvahiButton] في كامل التطبيق (٢٤
    // ميزة سابقة، `big_check_in_button.dart` ضمنها) يستجيب لتبديل
    // `glove_mode_settings.dart` تلقائياً دون أي تعديل إضافي مطلوب
    // على مواقع الاستدعاء تلك — وهذا بالضبط سبب اختيار `context.watch`
    // هنا بدل تمرير `isGloveMode` كباراميتر صريح لكل استدعاء قديم.
    final bool isGloveMode = context.watch<GloveModeCubit>().state;
    final bool isDisabled = onPressed == null || isLoading;
    final VoidCallback? effectiveOnPressed = isDisabled ? null : onPressed;
    final double effectiveHeight = _effectiveHeight(isGloveMode);
    final EdgeInsetsGeometry effectivePadding = _effectivePadding(isGloveMode);
    final double iconSize = isGloveMode ? 24 : 18;
    final TextStyle? labelStyle = isGloveMode
        ? Theme.of(context).textTheme.titleMedium
        : null;

    final Widget content = isLoading
        ? SizedBox(
            height: isGloveMode ? 22 : 18,
            width: isGloveMode ? 22 : 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _loadingIndicatorColor(context),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: iconSize),
                const SizedBox(width: AvahiSpacing.xs),
              ],
              Text(label, style: labelStyle),
            ],
          );

    final Widget button = switch (variant) {
      AvahiButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(0, effectiveHeight),
            padding: effectivePadding,
          ),
          child: content,
        ),
      AvahiButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, effectiveHeight),
            padding: effectivePadding,
          ),
          child: content,
        ),
      AvahiButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(0, effectiveHeight),
            padding: effectivePadding,
          ),
          child: content,
        ),
      AvahiButtonVariant.danger => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(0, effectiveHeight),
            padding: effectivePadding,
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: content,
        ),
    };

    if (!isFullWidth) return button;

    return SizedBox(width: double.infinity, child: button);
  }

  Color _loadingIndicatorColor(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (variant) {
      AvahiButtonVariant.primary => scheme.onPrimary,
      AvahiButtonVariant.danger => scheme.onError,
      AvahiButtonVariant.secondary => scheme.primary,
      AvahiButtonVariant.text => scheme.primary,
    };
  }
}
