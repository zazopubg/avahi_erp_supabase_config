import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/task.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../state/tasks_cubit.dart';
import '../../state/tasks_state.dart';
import '../../widgets/assignee_selector.dart';

/// حوار إسناد مهمة إلى شخص — يعرض [AssigneeSelector] مع [TasksData.assignableUsers]
/// المرشَّحين الحاليين، ويستدعي `TasksCubit.assignTask` عند التأكيد.
///
/// يُستدعى دائماً عبر [TaskAssignDialog.show] الثابت من
/// `task_details_screen.dart` (الهاتف) و`task_details_panel.dart`/
/// `tasks_list_screen.dart` (سطح المكتب) — وليس عبر `AvahiDialog`
/// العام مباشرة، لأن المحتوى هنا يحمل حالة داخلية (المُسنَد المُختار +
/// مؤشر تحميل أثناء الحفظ) تتجاوز ما يوفّره [AvahiDialog.show] البسيط.
class TaskAssignDialog extends StatefulWidget {
  const TaskAssignDialog({required this.task, super.key});

  final Task task;

  static Future<void> show(BuildContext context, {required Task task}) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider<TasksCubit>.value(
        value: context.read<TasksCubit>(),
        child: TaskAssignDialog(task: task),
      ),
    );
  }

  @override
  State<TaskAssignDialog> createState() => _TaskAssignDialogState();
}

class _TaskAssignDialogState extends State<TaskAssignDialog> {
  String? _selectedUserId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.task.assignedTo;
  }

  Future<void> _confirm() async {
    setState(() => _isSaving = true);

    final bool success = await context.read<TasksCubit>().assignTask(
          taskId: widget.task.id,
          assigneeId: _selectedUserId,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      if (context.mounted) {
        context.showSnackBar('تم تحديث إسناد المهمة بنجاح');
      }
    } else {
      context.showSnackBar('تعذّر تحديث إسناد المهمة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (BuildContext context, TasksState state) {
        final TasksData? data = state.dataOrNull;

        return AlertDialog(
          title: const Text('إسناد المهمة'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.task.title, style: context.textTheme.bodyMedium),
                const SizedBox(height: AvahiSpacing.md),
                AssigneeSelector(
                  candidates: data?.assignableUsers ?? const <TaskAssignee>[],
                  selectedUserId: _selectedUserId,
                  enabled: !_isSaving,
                  onChanged: (String? userId) =>
                      setState(() => _selectedUserId = userId),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AvahiSpacing.md,
            0,
            AvahiSpacing.md,
            AvahiSpacing.md,
          ),
          actions: <Widget>[
            AvahiButton(
              label: 'إلغاء',
              variant: AvahiButtonVariant.text,
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            ),
            AvahiButton(
              label: 'تأكيد الإسناد',
              isLoading: _isSaving,
              onPressed: _confirm,
            ),
          ],
        );
      },
    );
  }
}
