import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/task.dart';
import '../../../../../domain/enums/task_status.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../state/tasks_cubit.dart';
import '../../widgets/task_status_chip.dart';

/// شاشة تحديث حالة مهمة — Dropdown لاختيار [TaskStatus] الجديدة، حقل
/// ملاحظات نصي، وزر حفظ يستدعي `TasksCubit.updateStatus` (تحديث
/// تفاؤلي — انظر توثيقه الكامل في `tasks_cubit.dart`).
///
/// ⚠️ ملاحظة نطاق متعمَّدة: حقل الملاحظات هنا محلي فقط في هذه المرحلة
/// ولا يُرسَل للخادم — جدول `public.tasks` (Prompt 03) لا يملك عمود
/// `notes`/سجل تعليقات بعد؛ الحقل الفعلي المُرسَل عبر `UpdateTaskStatusUsecase`
/// هو [TaskStatus] الجديد فقط (وترتيب Kanban اختيارياً). يُفعَّل تخزين
/// الملاحظات فعلياً لاحقاً ضمن نظام تعليقات/سجل نشاط المهام (خارج
/// نطاق Prompt 16)، دون أي تغيير في شكل هذه الشاشة.
class TaskUpdateScreen extends StatefulWidget {
  const TaskUpdateScreen({required this.task, super.key});

  final Task task;

  @override
  State<TaskUpdateScreen> createState() => _TaskUpdateScreenState();
}

class _TaskUpdateScreenState extends State<TaskUpdateScreen> {
  late TaskStatus _selectedStatus;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.task.status;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final bool success = await context.read<TasksCubit>().updateStatus(
          task: widget.task,
          newStatus: _selectedStatus,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      context.showSnackBar('تم تحديث حالة المهمة بنجاح');
      Navigator.of(context).pop();
    } else {
      context.showSnackBar('تعذّر تحديث الحالة — تحقّق من صحة الانتقال بين الحالات');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChanged = _selectedStatus != widget.task.status;

    return Scaffold(
      appBar: AppBar(title: const Text('تحديث حالة المهمة')),
      body: ListView(
        padding: const EdgeInsets.all(AvahiSpacing.md),
        children: <Widget>[
          Text(widget.task.title, style: context.textTheme.titleMedium),
          const SizedBox(height: AvahiSpacing.xs),
          Row(
            children: <Widget>[
              const Text('الحالة الحالية: '),
              TaskStatusChip(status: widget.task.status, dense: true),
            ],
          ),
          const SizedBox(height: AvahiSpacing.lg),
          AvahiDropdown<TaskStatus>(
            label: 'الحالة الجديدة',
            value: _selectedStatus,
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
            onChanged: (TaskStatus? value) {
              if (value == null) return;
              setState(() => _selectedStatus = value);
            },
          ),
          const SizedBox(height: AvahiSpacing.md),
          AvahiTextField(
            controller: _notesController,
            label: 'ملاحظات (اختياري)',
            hint: 'أضف أي سياق حول هذا التحديث...',
            maxLines: 4,
          ),
          const SizedBox(height: AvahiSpacing.xl),
          AvahiButton(
            label: 'حفظ التحديث',
            icon: Icons.check,
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: hasChanged && !_isSaving ? _save : null,
          ),
        ],
      ),
    );
  }
}
