import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/task.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../state/tasks_state.dart';
import 'task_priority_indicator.dart';
import 'task_status_chip.dart';

/// بطاقة مهمة مضغوطة — العنصر البصري المشترك بين أعمدة لوحة Kanban
/// (`kanban_column.dart`، سطح المكتب) وقوائم المهام (`my_tasks_screen.dart`،
/// الهاتف). تعرض العنوان، مؤشر الأولوية، شارة حالة اختيارية (تُخفى
/// افتراضياً ضمن عمود الكانبان نفسه — الحالة مفهومة أصلاً من مكان
/// العمود)، تاريخ الاستحقاق (بتمييز لوني عند التأخر)، والمُسنَد إليه.
///
/// مكوّن عرض بحت — [onTap] اختياري لفتح تفاصيل المهمة؛ لا يحمل أي
/// منطق سحب/إفلات بنفسه (`kanban_column.dart` هو من يلفّها بـ
/// `Draggable`/`LongPressDraggable` عند الحاجة).
class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    super.key,
    this.onTap,
    this.showStatus = false,
    this.isDragging = false,
  });

  final Task task;
  final VoidCallback? onTap;

  /// عند `true`، تُعرض [TaskStatusChip] أعلى البطاقة — مفيد ضمن
  /// `my_tasks_screen.dart`/`tasks_list_screen.dart` حيث تُعرض مهام
  /// بحالات متعددة معاً، بخلاف عمود كانبان واحد.
  final bool showStatus;

  /// عند `true`، تُعرض البطاقة بشفافية مخفَّضة (نسخة "شبح" أثناء
  /// السحب ضمن `Draggable.feedback`/`childWhenDragging`).
  final bool isDragging;

  bool get _isOverdue =>
      task.dueDate != null &&
      !task.status.isDone &&
      task.dueDate!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Opacity(
      opacity: isDragging ? 0.4 : 1,
      child: Material(
        color: context.colors.surface,
        borderRadius: AvahiRadius.radiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AvahiRadius.radiusMd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AvahiSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AvahiRadius.radiusMd,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    TaskPriorityIndicator(
                      priority: task.priority,
                      showLabel: false,
                    ),
                    const SizedBox(width: AvahiSpacing.xs),
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                if (showStatus) ...<Widget>[
                  const SizedBox(height: AvahiSpacing.xs),
                  TaskStatusChip(status: task.status, dense: true),
                ],
                const SizedBox(height: AvahiSpacing.xs),
                Row(
                  children: <Widget>[
                    if (task.dueDate != null) ...<Widget>[
                      Icon(
                        Icons.event_outlined,
                        size: 14,
                        color: _isOverdue
                            ? colors.danger
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AvahiSpacing.xxs),
                      Text(
                        DateFormatter.shortDate(task.dueDate!),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: _isOverdue
                              ? colors.danger
                              : colors.onSurfaceVariant,
                          fontWeight: _isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (task.assignedTo != null)
                      Tooltip(
                        message: TaskAssignee.shortLabelOf(task.assignedTo!),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: colors.brandContainer,
                          child: Icon(
                            Icons.person,
                            size: 12,
                            color: colors.onBrandContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
