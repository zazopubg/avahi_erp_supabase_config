import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/permissions.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/task.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../state/tasks_cubit.dart';
import '../../state/tasks_state.dart';
import '../../widgets/task_priority_indicator.dart';
import '../../widgets/task_status_chip.dart';
import '../desktop/task_assign_dialog.dart';
import 'task_update_screen.dart';

/// شاشة تفاصيل مهمة واحدة كاملة — تُفتح عبر `Navigator.push` من
/// `my_tasks_screen.dart`/`tasks_list_screen.dart` (سطح المكتب يعرض
/// نفس المحتوى ضمن `task_details_panel.dart` بدل صفحة كاملة).
///
/// تعرض: العنوان، الوصف، شارة الحالة، مؤشر الأولوية، تاريخ الاستحقاق،
/// المُسنَد إليه، وتاريخي الإنشاء/آخر تحديث. زر "تحديث الحالة" يفتح
/// `task_update_screen.dart` دائماً؛ زر "إسناد" يظهر فقط لمن يملك
/// [Permission.tasksAssign].
///
/// ⚠️ تقرأ [Task] الممرّرة من `Navigator.push` مباشرة (لقطة لحظة
/// الفتح) للعرض الفوري بلا وميض تحميل، لكن كل الإجراءات (تحديث/إسناد)
/// تُنفَّذ عبر `TasksCubit` وتُعاد قراءتها من `TasksState` الحالية عبر
/// [_currentTaskOrFallback] كي تعكس الشاشة أي تحديث لحظي (تحديث
/// تفاؤلي من مكان آخر، أو نتيجة الإجراء نفسه) دون إغلاق نفسها.
class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({required this.task, super.key});

  final Task task;

  Task _currentTaskOrFallback(TasksState state) {
    final TasksData? data = state.dataOrNull;
    if (data == null) return task;
    final Task? fromMyTasks = data.myTasks
        .cast<Task?>()
        .firstWhere((Task? t) => t?.id == task.id, orElse: () => null);
    if (fromMyTasks != null) return fromMyTasks;
    final Task? fromProjectTasks = data.projectTasks
        .cast<Task?>()
        .firstWhere((Task? t) => t?.id == task.id, orElse: () => null);
    return fromProjectTasks ?? task;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (BuildContext context, TasksState state) {
        final Task current = _currentTaskOrFallback(state);
        final TasksData? data = state.dataOrNull;
        final bool canAssign = data != null &&
            RolePermissions.has(data.currentUser.role, Permission.tasksAssign);

        return Scaffold(
          appBar: AppBar(title: const Text('تفاصيل المهمة')),
          body: ListView(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            children: <Widget>[
              Text(current.title, style: context.textTheme.headlineSmall),
              const SizedBox(height: AvahiSpacing.sm),
              Wrap(
                spacing: AvahiSpacing.sm,
                runSpacing: AvahiSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  TaskStatusChip(status: current.status),
                  TaskPriorityIndicator(priority: current.priority),
                ],
              ),
              if (current.description != null &&
                  current.description!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: AvahiSpacing.lg),
                Text('الوصف', style: context.textTheme.titleSmall),
                const SizedBox(height: AvahiSpacing.xxs),
                Text(current.description!, style: context.textTheme.bodyMedium),
              ],
              const SizedBox(height: AvahiSpacing.lg),
              _DetailRow(
                icon: Icons.event_outlined,
                label: 'تاريخ الاستحقاق',
                value: current.dueDate != null
                    ? DateFormatter.longDate(current.dueDate!)
                    : 'غير محدد',
              ),
              _DetailRow(
                icon: Icons.person_outline,
                label: 'المُسنَد إليه',
                value: current.assignedTo != null
                    ? TaskAssignee.shortLabelOf(current.assignedTo!)
                    : 'بلا إسناد',
              ),
              _DetailRow(
                icon: Icons.schedule,
                label: 'آخر تحديث',
                value: DateFormatter.dateTime(current.updatedAt),
              ),
              const SizedBox(height: AvahiSpacing.xl),
              AvahiButton(
                label: 'تحديث الحالة',
                icon: Icons.edit_outlined,
                isFullWidth: true,
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => TaskUpdateScreen(task: current),
                  ),
                ),
              ),
              if (canAssign) ...<Widget>[
                const SizedBox(height: AvahiSpacing.sm),
                AvahiButton(
                  label: 'إسناد المهمة',
                  icon: Icons.person_add_alt,
                  variant: AvahiButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: () => TaskAssignDialog.show(context, task: current),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
          const SizedBox(width: AvahiSpacing.sm),
          Text(label, style: context.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
