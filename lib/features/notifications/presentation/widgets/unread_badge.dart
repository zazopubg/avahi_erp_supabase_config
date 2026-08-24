import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';

/// شارة عداد حمراء صغيرة (Pill) لعدد الإشعارات غير المقروءة — تُستخدم
/// في رأس `notification_panel.dart` (سطح المكتب) وعنوان
/// `notifications_screen.dart`.
///
/// لا تُعرض إطلاقاً عند [count] صفر (`SizedBox.shrink`) — القرار في هذا
/// المكوّن نفسه بدل تكراره في كل مستدعٍ. قيم أكبر من 99 تُعرض كـ "99+".
///
/// مكوّن عرض بحت — لا يحمل أي منطق حساب العدد الفعلي.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({required this.count, super.key, this.dense = false});

  final int count;

  /// عند `true`، تُستخدم مسافات/خط أصغر (لاستخدامها فوق أيقونة الجرس
  /// مثلاً، بدل عنوان قائمة كاملة).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final String label = count > 99 ? '99+' : '$count';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 5 : 8,
        vertical: dense ? 1 : 3,
      ),
      constraints: BoxConstraints(minWidth: dense ? 16 : 22),
      decoration: BoxDecoration(
        color: colors.danger,
        borderRadius: AvahiRadius.radiusFull,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.onDanger,
          fontSize: dense ? 10 : 12,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}
