import 'package:flutter/material.dart';

import '../../theme/avahi_colors.dart';
import '../../theme/avahi_spacing.dart';

/// الحالات الأربع الممكنة لمؤشر المزامنة (Sync Indicator)، وهي أساسية
/// جداً في تطبيق ميداني يعمل غالباً بدون اتصال دائم بالإنترنت:
///
/// 1. [SyncState.synced]   → 🟢 تمت المزامنة بنجاح.
/// 2. [SyncState.syncing]  → 🟡 جارٍ الرفع/المزامنة الآن.
/// 3. [SyncState.pending]  → ⚪ بانتظار الاتصال لبدء المزامنة.
/// 4. [SyncState.failed]   → 🔴 فشلت المزامنة (تحتاج إعادة محاولة).
enum SyncState { synced, syncing, pending, failed }

/// مؤشر مزامنة صغير (أيقونة + نص اختياري) يعكس إحدى [SyncState] الأربع.
///
/// مكوّن عرض بحت — لا يحمل أي منطق مزامنة فعلي؛ يُستخدم بحقن [state] من
/// طبقة أعلى (Cubit) لاحقاً.
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({
    required this.state,
    super.key,
    this.showLabel = true,
    this.size = 16,
  });

  final SyncState state;

  /// عند `true`، يُعرض نص وصفي بجانب الأيقونة.
  final bool showLabel;

  final double size;

  _SyncVisual _visualFor(SyncState state, AvahiColors colors) {
    return switch (state) {
      SyncState.synced => _SyncVisual(
          icon: Icons.check_circle,
          color: colors.success,
          label: 'تمت المزامنة',
        ),
      SyncState.syncing => _SyncVisual(
          icon: Icons.sync,
          color: colors.warning,
          label: 'جارٍ المزامنة...',
          isSpinning: true,
        ),
      SyncState.pending => _SyncVisual(
          icon: Icons.schedule,
          color: colors.onSurfaceVariant,
          label: 'بانتظار الاتصال',
        ),
      SyncState.failed => _SyncVisual(
          icon: Icons.error,
          color: colors.danger,
          label: 'فشلت المزامنة',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final _SyncVisual visual = _visualFor(state, colors);

    final Widget icon = visual.isSpinning
        ? _SpinningIcon(icon: visual.icon, color: visual.color, size: size)
        : Icon(visual.icon, size: size, color: visual.color);

    if (!showLabel) {
      return Semantics(label: visual.label, child: icon);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        icon,
        const SizedBox(width: AvahiSpacing.xxs),
        Text(
          visual.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: visual.color,
              ),
        ),
      ],
    );
  }
}

class _SyncVisual {
  const _SyncVisual({
    required this.icon,
    required this.color,
    required this.label,
    this.isSpinning = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool isSpinning;
}

/// أيقونة دوّارة بسيطة تُستخدم لحالة [SyncState.syncing].
class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
