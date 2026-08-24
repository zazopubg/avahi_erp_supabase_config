import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/task.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/tasks_cubit.dart';
import '../../state/tasks_state.dart';
import '../../widgets/task_filter_bar.dart';
import '../../widgets/task_priority_indicator.dart';
import '../../widgets/task_status_chip.dart';
import 'task_details_panel.dart';

/// عرض جدولي بديل لمهام المشروع على سطح المكتب — النظير الجدولي
/// لـ `tasks_board_screen.dart` (Kanban)، ويستخدم [DataGridRtl] العام
/// (نفس المستخدَم في `attendance_table.dart`، Prompt 15).
///
/// تخطيط ثنائي الأعمدة قياسي لسطح المكتب: الجدول + [TaskFilterBar] في
/// عمود موسَّع، و[TaskDetailsPanel] ثابتة على اليمين تعرض تفاصيل
/// المهمة المُختارة حالياً (`_selectedTaskId`) — الضغط على أي صف
/// يبدّل الاختيار بدل فتح صفحة منفصلة (بخلاف الهاتف).
///
/// يعرض أيضاً زر "لوحة Kanban" أعلى الجدول للانتقال إلى
/// `RouteNames.tasksBoard` (`/tasks/board`، محمي بـ `PlatformGuard`
/// للشاشات الكبيرة فقط — انظر `navigation/guards/platform_guard.dart`).
class TasksListScreen extends StatefulWidget {
  const TasksListScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  String? _selectedTaskId;

  @override
  void initState() {
    super.initState();
    context.read<TasksCubit>().loadBoard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المهام'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.sm),
            child: AvahiButton(
              label: 'لوحة Kanban',
              icon: Icons.view_kanban_outlined,
              variant: AvahiButtonVariant.secondary,
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.tasksBoard),
            ),
          ),
        ],
      ),
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (BuildContext context, TasksState state) {
          final TasksData? data = state.dataOrNull;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Task> tasks = data.filteredProjectTasks.isNotEmpty ||
                  data.hasActiveFilters
              ? data.filteredProjectTasks
              : data.filteredMyTasks;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AvahiSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TaskFilterBar(
                        data: data,
                        onStatusChanged:
                            context.read<TasksCubit>().setStatusFilter,
                        onPriorityChanged:
                            context.read<TasksCubit>().setPriorityFilter,
                        onSearchChanged:
                            context.read<TasksCubit>().setSearchQuery,
                        onClearFilters: context.read<TasksCubit>().clearFilters,
                      ),
                      const SizedBox(height: AvahiSpacing.md),
                      Expanded(
                        child: tasks.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد مهام لعرضها',
                                icon: Icons.checklist_outlined,
                              )
                            : DataGridRtl<Task>(
                                rowKeyOf: (Task t) => t.id,
                                onRowTap: (Task t) =>
                                    setState(() => _selectedTaskId = t.id),
                                columns: <DataGridColumn<Task>>[
                                  DataGridColumn<Task>(
                                    label: 'العنوان',
                                    flex: 3,
                                    cellBuilder: (_, Task t) => Text(
                                      t.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DataGridColumn<Task>(
                                    label: 'الحالة',
                                    cellBuilder: (_, Task t) =>
                                        TaskStatusChip(status: t.status, dense: true),
                                  ),
                                  DataGridColumn<Task>(
                                    label: 'الأولوية',
                                    cellBuilder: (_, Task t) =>
                                        TaskPriorityIndicator(
                                      priority: t.priority,
                                      dense: true,
                                    ),
                                  ),
                                  DataGridColumn<Task>(
                                    label: 'المُسنَد إليه',
                                    cellBuilder: (_, Task t) => Text(
                                      t.assignedTo != null
                                          ? TaskAssignee.shortLabelOf(
                                              t.assignedTo!,
                                            )
                                          : '—',
                                    ),
                                  ),
                                  DataGridColumn<Task>(
                                    label: 'الاستحقاق',
                                    cellBuilder: (_, Task t) => Text(
                                      t.dueDate != null
                                          ? DateFormatter.shortDate(t.dueDate!)
                                          : '—',
                                    ),
                                  ),
                                ],
                                rows: tasks,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedTaskId != null)
                TaskDetailsPanel(
                  taskId: _selectedTaskId!,
                  onClose: () => setState(() => _selectedTaskId = null),
                ),
            ],
          );
        },
      ),
    );
  }
}
