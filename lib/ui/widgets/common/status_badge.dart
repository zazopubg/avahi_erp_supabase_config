import 'package:flutter/material.dart';

import '../../theme/avahi_colors.dart';
import '../../theme/avahi_radius.dart';
import '../../theme/avahi_spacing.dart';

/// الحالات الدلالية العامة المتاحة لأي شارة حالة في التطبيق، متوافقة مع
/// نظام الألوان الدلالي في `avahi_colors.dart`.
enum AvahiStatus {
  /// 🟢 مكتمل / متزامن.
  success,

  /// 🔴 متأخر / خطأ.
  danger,

  /// 🟡 جارٍ / قيد الانتظار.
  warning,

  /// 🔵 معلومات.
  info,

  /// ⚪ محايد (بلا دلالة لونية خاصة).
  neutral,
}

/// شارة حالة نصية صغيرة (Pill/Chip) تُستخدم لعرض حالة عنصر ما (مهمة،
/// تقرير، حضور...) بلون دلالي واضح.
///
/// مكوّن عرض بحت — لا يحمل أي منطق تحديد الحالة الفعلي؛ المستدعي هو من
/// يحدد [status] المناسبة للبيانات.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.status,
    super.key,
    this.icon,
    this.dense = false,
  });

  final String label;
  final AvahiStatus status;

  /// أيقونة اختيارية تُعرض قبل النص.
  final IconData? icon;

  /// عند `true`، تُستخدم مسافات أصغر (لاستخدامها داخل جداول مكتظة).
  final bool dense;

  _StatusColors _colorsFor(AvahiColors colors) {
    return switch (status) {
      AvahiStatus.success => _StatusColors(
          background: colors.successContainer,
          foreground: colors.onSuccessContainer,
        ),
      AvahiStatus.danger => _StatusColors(
          background: colors.dangerContainer,
          foreground: colors.onDangerContainer,
        ),
      AvahiStatus.warning => _StatusColors(
          background: colors.warningContainer,
          foreground: colors.onWarningContainer,
        ),
      AvahiStatus.info => _StatusColors(
          background: colors.infoContainer,
          foreground: colors.onInfoContainer,
        ),
      AvahiStatus.neutral => _StatusColors(
          background: colors.surfaceVariant,
          foreground: colors.onSurfaceVariant,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final _StatusColors statusColors = _colorsFor(colors);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AvahiSpacing.xs : AvahiSpacing.sm,
        vertical: dense ? 2 : AvahiSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: statusColors.background,
        borderRadius: AvahiRadius.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: statusColors.foreground),
            const SizedBox(width: AvahiSpacing.xxs),
          ],
          Text(
            label,
            style: (dense ? textTheme.labelSmall : textTheme.labelMedium)
                ?.copyWith(color: statusColors.foreground),
          ),
        ],
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
