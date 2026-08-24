import 'package:flutter/material.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/enums/task_priority.dart';
import '../../../../domain/enums/task_status.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_text_field.dart';
import '../state/tasks_state.dart';
import 'task_status_chip.dart';

/// شريط تصفية المهام — حقل بحث بالعنوان + رقاقات (Chips) تصفية حسب
/// الحالة والأولوية، مستخدَم من `my_tasks_screen.dart` (الهاتف) و
/// `tasks_board_screen.dart`/`tasks_list_screen.dart` (سطح المكتب)
/// معاً بنفس المكوّن تماماً.
///
/// مكوّن عرض بحت — لا يستدعي `TasksCubit` مباشرة؛ الشاشة الأب هي من
/// تمرّر القيم الحالية وتستقبل التغييرات عبر الاستدعاءات الخلفية
/// (`on...Changed`)، غالباً بربطها مباشرة بدوال `TasksCubit.set...Filter`.
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    required this.data,
    super.key,
    this.onStatusChanged,
    this.onPriorityChanged,
    this.onSearchChanged,
    this.onClearFilters,
  });

  final TasksData data;
  final ValueChanged<TaskStatus?>? onStatusChanged;
  final ValueChanged<TaskPriority?>? onPriorityChanged;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AvahiTextField(
          hint: 'ابحث بعنوان المهمة...',
          prefixIcon: Icons.search,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: AvahiSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (final TaskStatus status in TaskStatus.values) ...<Widget>[
                _FilterChoiceChip(
                  selected: data.statusFilter == status,
                  onSelected: (bool selected) =>
                      onStatusChanged?.call(selected ? status : null),
                  child: TaskStatusChip(status: status, dense: true),
                ),
                const SizedBox(width: AvahiSpacing.xs),
              ],
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(
                  horizontal: AvahiSpacing.xxs,
                ),
                color: context.colors.outlineVariant,
              ),
              const SizedBox(width: AvahiSpacing.xs),
              for (final TaskPriority priority
                  in TaskPriority.values) ...<Widget>[
                _FilterChoiceChip(
                  selected: data.priorityFilter == priority,
                  onSelected: (bool selected) =>
                      onPriorityChanged?.call(selected ? priority : null),
                  child: Text(_priorityLabel(priority)),
                ),
                const SizedBox(width: AvahiSpacing.xs),
              ],
              if (data.hasActiveFilters)
                ActionChip(
                  avatar: const Icon(Icons.close, size: 16),
                  label: const Text('مسح الفلاتر'),
                  onPressed: onClearFilters,
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _priorityLabel(TaskPriority priority) => switch (priority) {
        TaskPriority.low => 'منخفضة',
        TaskPriority.medium => 'متوسطة',
        TaskPriority.high => 'عالية',
        TaskPriority.urgent => 'عاجلة',
      };
}

/// غلاف [FilterChip] موحّد يسمح بتمرير أي [child] (شارة حالة جاهزة أو
/// نص بسيط) بدل نص فقط، لإعادة استخدام [TaskStatusChip] داخل الرقاقة
/// نفسها دون ازدواجية منطق الألوان.
class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.selected,
    required this.onSelected,
    required this.child,
  });

  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: child,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      side: BorderSide(
        color: selected
            ? context.colors.primary
            : context.colors.outlineVariant,
      ),
    );
  }
}
