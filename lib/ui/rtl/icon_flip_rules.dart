import 'package:flutter/material.dart';

/// قواعد انعكاس الأيقونات (Icon Mirroring) عند التبديل بين RTL وLTR.
///
/// ليست كل الأيقونات يجب أن تنعكس عند التبديل إلى RTL — فقط الأيقونات
/// ذات **الدلالة الاتجاهية** (أسهم، رجوع/تقدّم، ترتيب...). أما الأيقونات
/// ذات الدلالة الثابتة (مثل ⚙️ الإعدادات أو 🔔 الإشعارات) يجب ألا تنعكس
/// أبداً حفاظاً على معناها البصري.
abstract class AvahiIconFlipRules {
  /// مجموعة الأيقونات التي **يجب انعكاسها** في RTL لأنها تحمل دلالة
  /// اتجاهية (سهم للأمام يعني "التالي" الذي يشير بصرياً بحسب الاتجاه).
  static final Set<IconData> directionalIcons = <IconData>{
    Icons.arrow_forward,
    Icons.arrow_back,
    Icons.arrow_forward_ios,
    Icons.arrow_back_ios,
    Icons.arrow_forward_ios_rounded,
    Icons.arrow_back_ios_rounded,
    Icons.chevron_left,
    Icons.chevron_right,
    Icons.navigate_next,
    Icons.navigate_before,
    Icons.reply,
    Icons.forward,
    Icons.redo,
    Icons.undo,
    Icons.trending_flat,
    Icons.last_page,
    Icons.first_page,
    Icons.keyboard_arrow_left,
    Icons.keyboard_arrow_right,
    Icons.subdirectory_arrow_left,
    Icons.subdirectory_arrow_right,
    Icons.logout,
    Icons.login,
    Icons.exit_to_app,
    Icons.launch,
    Icons.open_in_new,
    Icons.send,
    Icons.assignment_return,
  };

  /// يحدد إذا كانت أيقونة معيّنة يجب أن تنعكس بحسب هذه القواعد.
  static bool shouldFlip(IconData icon) => directionalIcons.contains(icon);
}

/// Widget يلفّ أي أيقونة اتجاهية ويضمن انعكاسها تلقائياً في RTL بحسب
/// [AvahiIconFlipRules]، دون الحاجة لمنطق شرطي متكرر في شاشات الميزات.
///
/// ```dart
/// AvahiDirectionalIcon(icon: Icons.arrow_forward)
/// ```
///
/// للأيقونات غير الاتجاهية، استخدم [Icon] العادي مباشرة.
class AvahiDirectionalIcon extends StatelessWidget {
  const AvahiDirectionalIcon({
    required this.icon,
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final bool flip = isRtl && AvahiIconFlipRules.shouldFlip(icon);

    final Widget iconWidget = Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );

    if (!flip) return iconWidget;

    // انعكاس أفقي (Mirror) للأيقونة عبر مصفوفة تحويل.
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
      child: iconWidget,
    );
  }
}
