import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/task.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/tasks_cubit.dart';
import '../../state/tasks_state.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_filter_bar.dart';
import 'task_details_screen.dart';

/// قائمة مهام المستخدم الحالي — الشاشة الرئيسية على الهاتف لميزة
/// المهام (`RouteNames.tasks`، `ShellMode.mobile`)، مصفّاة تلقائياً
/// حسب صلاحياته عبر `GetMyTasksUsecase(userId: ...)` نفسها (طبقة
/// `data/` هي من تُقيّد النطاق فعلياً حسب [Permission.tasksViewAssigned]
/// عبر RLS Supabase — انظر `core/errors/failure.dart` وتوثيق
/// `TasksCubit.loadInitial`).
///
/// تعرض [TaskFilterBar] أعلى القائمة، ثم بطاقات [TaskCard] لكل مهمة
/// (مع شارة الحالة ظاهرة دائماً هنا — بخلاف عمود كانبان واحد الحالة).
/// الضغط على بطاقة يفتح `task_details_screen.dart`.
class MyTasksScreen extends StatelessWidget {
  const MyTasksScreen({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مهامي')),
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (BuildContext context, TasksState state) {
          return state.maybeWhen<Widget>(
            orElse: () => _TasksList(data: state.dataOrNull!),
            loading: () => const LoadingIndicator(label: 'جارٍ تحميل مهامك...'),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل المهام',
              message: failure.message,
              onRetry: () => context.read<TasksCubit>().loadInitial(user),
            ),
          );
        },
      ),
    );
  }
}

class _TasksList extends StatelessWidget {
  const _TasksList({required this.data});

  final TasksData data;

  @override
  Widget build(BuildContext context) {
    final List<Task> tasks = data.filteredMyTasks;

    return RefreshIndicator(
      onRefresh: () => context.read<TasksCubit>().refreshMyTasks(),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AvahiSpacing.md,
              AvahiSpacing.md,
              AvahiSpacing.md,
              AvahiSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: TaskFilterBar(
                data: data,
                onStatusChanged: context.read<TasksCubit>().setStatusFilter,
                onPriorityChanged: context.read<TasksCubit>().setPriorityFilter,
                onSearchChanged: context.read<TasksCubit>().setSearchQuery,
                onClearFilters: context.read<TasksCubit>().clearFilters,
              ),
            ),
          ),
          if (tasks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: data.hasActiveFilters
                    ? 'لا توجد مهام مطابقة للتصفية الحالية'
                    : 'لا توجد مهام مُسنَدة إليك حالياً',
                icon: Icons.checklist_outlined,
                actionLabel: data.hasActiveFilters ? 'مسح الفلاتر' : null,
                onAction: data.hasActiveFilters
                    ? context.read<TasksCubit>().clearFilters
                    : null,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AvahiSpacing.md,
                0,
                AvahiSpacing.md,
                AvahiSpacing.md,
              ),
              sliver: SliverList.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AvahiSpacing.xs),
                itemBuilder: (BuildContext context, int index) {
                  final Task task = tasks[index];
                  return TaskCard(
                    task: task,
                    showStatus: true,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => TaskDetailsScreen(task: task),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
