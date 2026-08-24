import 'package:flutter/material.dart';

import '../../../../domain/enums/task_priority.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// مؤشر أولوية مهمة — دائرة لونية دلالية صغيرة + تسمية اختيارية،
/// أخفّ بصرياً من [TaskStatusChip] (بلا خلفية كبسولية) لأنه يُستخدم
/// غالباً بجانب عناصر أخرى مكتظة (`task_card.dart`، صفوف الجدول).
///
/// مكوّن عرض بحت — لا يحمل أي منطق تحديد أولوية فعلي.
class TaskPriorityIndicator extends StatelessWidget {
  const TaskPriorityIndicator({
    required this.priority,
    super.key,
    this.showLabel = true,
    this.dense = false,
  });

  final TaskPriority priority;

  /// عند `false`، تُعرض الدائرة اللونية فقط بلا نص (مثال: ضمن بطاقة
  /// كانبان مكتظة `task_card.dart`).
  final bool showLabel;
  final bool dense;

  static (Color Function(AvahiColors), String) _visualsFor(
    TaskPriority priority,
  ) {
    return switch (priority) {
      TaskPriority.low => ((AvahiColors c) => c.success, 'منخفضة'),
      TaskPriority.medium => ((AvahiColors c) => c.info, 'متوسطة'),
      TaskPriority.high => ((AvahiColors c) => c.warning, 'عالية'),
      TaskPriority.urgent => ((AvahiColors c) => c.danger, 'عاجلة'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final (Color Function(AvahiColors) colorOf, String label) = _visualsFor(
      priority,
    );
    final Color color = colorOf(colors);
    final double dotSize = dense ? 8 : 10;

    if (!showLabel) {
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AvahiSpacing.xxs),
        Text(
          label,
          style: (dense
                  ? Theme.of(context).textTheme.labelSmall
                  : Theme.of(context).textTheme.labelMedium)
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
