import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/task.dart';
import '../../../../../domain/enums/task_status.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/tasks_cubit.dart';
import '../../state/tasks_state.dart';
import '../../widgets/kanban_column.dart';
import '../../widgets/task_filter_bar.dart';
import 'task_details_panel.dart';

/// نقطة الدخول المستقلة لمسار `RouteNames.tasksBoard` (`/tasks/board`)
/// — لوحة Kanban تفاعلية حقيقية بالسحب والإفلات، **محمية بـ**
/// `PlatformGuard` للشاشات الكبيرة فقط (انظر `navigation/guards/platform_guard.dart`:
/// أي محاولة وصول من عرض هاتف تُعاد توجيهها تلقائياً إلى `/tasks`).
///
/// مستقلة تماماً عن `tasks_screen.dart` (نسخة [TasksCubit] خاصة بها
/// عبر `sl<TasksCubit>()..loadInitial(user)` ثم `..loadBoard()`) —
/// انظر توثيق هذا القرار الكامل في `tasks_screen.dart`.
///
/// عمود واحد لكل [TaskStatus] (`kanban_column.dart`)، وإفلات بطاقة في
/// عمود جديد يستدعي `TasksCubit.updateStatus` تلقائياً (تحديث
/// تفاؤلي — البطاقة تتحرك فوراً ثم تتراجع تلقائياً عند فشل فعلي).
class TasksBoardScreen extends StatelessWidget {
  const TasksBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<TasksCubit>(
              create: (_) => sl<TasksCubit>()..loadInitial(user),
              child: _TasksBoardBody(user: user),
            );
          },
        );
      },
    );
  }
}

class _TasksBoardBody extends StatefulWidget {
  const _TasksBoardBody({required this.user});

  final AppUser user;

  @override
  State<_TasksBoardBody> createState() => _TasksBoardBodyState();
}

class _TasksBoardBodyState extends State<_TasksBoardBody> {
  String? _selectedTaskId;
  bool _requestedBoardLoad = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (BuildContext context, TasksState state) {
        return state.maybeWhen<Widget>(
          orElse: () {
            final TasksData data = state.dataOrNull!;
            // تحميل كسول للوحة عند أول نجاح لـ loadInitial (مرة واحدة
            // فقط) — لا يمكن استدعاؤه من `loadInitial` نفسها لأن
            // المشروع الحالي (`TasksData.project`) لا يُعرف إلا بعد
            // انتهائها.
            if (!_requestedBoardLoad && data.project != null) {
              _requestedBoardLoad = true;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => context.read<TasksCubit>().loadBoard(),
              );
            }
            return _BoardScaffold(
              data: data,
              selectedTaskId: _selectedTaskId,
              onTaskSelected: (String? id) =>
                  setState(() => _selectedTaskId = id),
            );
          },
          loading: () => const Scaffold(
            body: LoadingIndicator(label: 'جارٍ تحميل لوحة المهام...'),
          ),
          error: (Failure failure) => Scaffold(
            appBar: AppBar(title: const Text('لوحة Kanban')),
            body: ErrorView(
              title: 'تعذّر تحميل لوحة المهام',
              message: failure.message,
              onRetry: () => context.read<TasksCubit>().loadInitial(widget.user),
            ),
          ),
        );
      },
    );
  }
}

class _BoardScaffold extends StatelessWidget {
  const _BoardScaffold({
    required this.data,
    required this.onTaskSelected,
    this.selectedTaskId,
  });

  final TasksData data;
  final String? selectedTaskId;
  final ValueChanged<String?> onTaskSelected;

  @override
  Widget build(BuildContext context) {
    if (data.project == null) {
      return const Scaffold(
        body: Center(child: Text('لا يوجد مشروع نشط لعرض لوحة المهام')),
      );
    }

    final Map<TaskStatus, List<Task>> columns = data.boardColumns;

    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة المهام — ${data.project!.name}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'تحديث',
            icon: data.isBoardLoading
                ? const Padding(
                    padding: EdgeInsets.all(AvahiSpacing.sm),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: data.isBoardLoading
                ? null
                : () => context.read<TasksCubit>().loadBoard(),
          ),
        ],
      ),
      body: Row(
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
                    onStatusChanged: context.read<TasksCubit>().setStatusFilter,
                    onPriorityChanged:
                        context.read<TasksCubit>().setPriorityFilter,
                    onSearchChanged: context.read<TasksCubit>().setSearchQuery,
                    onClearFilters: context.read<TasksCubit>().clearFilters,
                  ),
                  const SizedBox(height: AvahiSpacing.md),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          for (final TaskStatus status in TaskStatus.values)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AvahiSpacing.sm,
                              ),
                              child: KanbanColumn(
                                status: status,
                                tasks: columns[status] ?? const <Task>[],
                                onTaskTap: (Task t) => onTaskSelected(t.id),
                                onTaskDropped: (Task task, int index) {
                                  if (task.status == status) return;
                                  context.read<TasksCubit>().updateStatus(
                                        task: task,
                                        newStatus: status,
                                        kanbanOrder: index,
                                      );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedTaskId != null)
            TaskDetailsPanel(
              taskId: selectedTaskId!,
              onClose: () => onTaskSelected(null),
            ),
        ],
      ),
    );
  }
}
