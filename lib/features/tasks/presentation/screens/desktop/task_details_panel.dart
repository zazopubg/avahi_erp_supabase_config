import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/permissions.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/task.dart';
import '../../../../../domain/enums/task_status.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../state/tasks_cubit.dart';
import '../../state/tasks_state.dart';
import '../../widgets/task_priority_indicator.dart';
import '../../widgets/task_status_chip.dart';
import 'task_assign_dialog.dart';

/// لوحة تفاصيل مهمة جانبية لسطح المكتب — النظير المباشر لـ
/// `task_details_screen.dart` (الهاتف)، لكن كلوحة ثابتة ضمن التخطيط
/// ثنائي الأعمدة لـ `tasks_list_screen.dart` بدل صفحة كاملة منفصلة
/// (نمط "قائمة + لوحة جانبية" القياسي لسطح المكتب، شبيه بـ
/// `attendance_desktop_home.dart`).
///
/// يقرأ [taskId] فقط ويحلّه في كل مرة من `TasksState` الحالية (وليس
/// كائن [Task] ثابتاً) كي تعكس اللوحة أي تحديث تفاؤلي فوري (سحب/إفلات
/// على لوحة Kanban، أو إسناد جديد) دون الحاجة لإعادة اختيار المهمة
/// يدوياً.
class TaskDetailsPanel extends StatelessWidget {
  const TaskDetailsPanel({required this.taskId, super.key, this.onClose});

  final String taskId;
  final VoidCallback? onClose;

  Task? _resolve(TasksData data) {
    final Task? fromMy = data.myTasks
        .cast<Task?>()
        .firstWhere((Task? t) => t?.id == taskId, orElse: () => null);
    if (fromMy != null) return fromMy;
    return data.projectTasks
        .cast<Task?>()
        .firstWhere((Task? t) => t?.id == taskId, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (BuildContext context, TasksState state) {
        final TasksData? data = state.dataOrNull;
        final Task? task = data != null ? _resolve(data) : null;

        return Container(
          width: 360,
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(left: BorderSide(color: colors.outlineVariant)),
          ),
          child: task == null
              ? Center(
                  child: Text(
                    'اختر مهمة لعرض تفاصيلها',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              : _PanelContent(task: task, data: data!, onClose: onClose),
        );
      },
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({required this.task, required this.data, this.onClose});

  final Task task;
  final TasksData data;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final bool canAssign = RolePermissions.has(
      data.currentUser.role,
      Permission.tasksAssign,
    );

    return ListView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(task.title, style: context.textTheme.titleLarge),
            ),
            if (onClose != null)
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
          ],
        ),
        const SizedBox(height: AvahiSpacing.sm),
        Wrap(
          spacing: AvahiSpacing.sm,
          runSpacing: AvahiSpacing.xs,
          children: <Widget>[
            TaskStatusChip(status: task.status),
            TaskPriorityIndicator(priority: task.priority),
          ],
        ),
        if (task.description != null &&
            task.description!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: AvahiSpacing.lg),
          Text('الوصف', style: context.textTheme.titleSmall),
          const SizedBox(height: AvahiSpacing.xxs),
          Text(task.description!, style: context.textTheme.bodyMedium),
        ],
        const SizedBox(height: AvahiSpacing.lg),
        _DetailRow(
          label: 'تاريخ الاستحقاق',
          value: task.dueDate != null
              ? DateFormatter.longDate(task.dueDate!)
              : 'غير محدد',
        ),
        _DetailRow(
          label: 'المُسنَد إليه',
          value: task.assignedTo != null
              ? TaskAssignee.shortLabelOf(task.assignedTo!)
              : 'بلا إسناد',
        ),
        _DetailRow(
          label: 'آخر تحديث',
          value: DateFormatter.dateTime(task.updatedAt),
        ),
        const SizedBox(height: AvahiSpacing.lg),
        _QuickStatusUpdate(task: task),
        if (canAssign) ...<Widget>[
          const SizedBox(height: AvahiSpacing.sm),
          AvahiButton(
            label: 'إسناد المهمة',
            icon: Icons.person_add_alt,
            variant: AvahiButtonVariant.secondary,
            isFullWidth: true,
            onPressed: () => TaskAssignDialog.show(context, task: task),
          ),
        ],
      ],
    );
  }
}

/// تحديث حالة سريع من داخل اللوحة الجانبية (Dropdown مباشر بدل فتح
/// `task_update_screen.dart` — المخصصة أصلاً للهاتف) — يستدعي نفس
/// `TasksCubit.updateStatus` التفاؤلي.
class _QuickStatusUpdate extends StatelessWidget {
  const _QuickStatusUpdate({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return AvahiDropdown<TaskStatus>(
      label: 'تحديث الحالة',
      value: task.status,
      items: <AvahiDropdownItem<TaskStatus>>[
        for (final TaskStatus status in TaskStatus.values)
          AvahiDropdownItem<TaskStatus>(
            value: status,
            label: switch (status) {
              TaskStatus.todo => 'قائمة الانتظار',
              TaskStatus.inProgress => 'قيد التنفيذ',
              TaskStatus.review => 'قيد المراجعة',
              TaskStatus.done => 'مكتملة',
              TaskStatus.blocked => 'معلّقة',
            },
          ),
      ],
      onChanged: (TaskStatus? value) async {
        if (value == null || value == task.status) return;
        final bool success = await context.read<TasksCubit>().updateStatus(
          task: task,
          newStatus: value,
        );
        if (context.mounted && !success) {
          context.showSnackBar(
            'تعذّر تحديث الحالة — تحقّق من صحة الانتقال بين الحالات',
          );
        }
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xxs),
      child: Row(
        children: <Widget>[
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
