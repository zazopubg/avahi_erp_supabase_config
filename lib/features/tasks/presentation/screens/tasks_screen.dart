import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../ui/widgets/common/error_view.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../state/tasks_cubit.dart';
import '../state/tasks_state.dart';
import 'desktop/tasks_list_screen.dart';
import 'mobile/my_tasks_screen.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.tasks` (`/tasks`) — بنفس نمط
/// `AttendanceScreen` تماماً (`features/attendance/presentation/screens/attendance_screen.dart`،
/// Prompt 15): توفّر [TasksCubit] محلياً عبر `sl<TasksCubit>()..loadInitial(user)`
/// ثم تفرّع العرض حسب [ShellMode] فقط — [MyTasksScreen] للهاتف
/// (< 600) و[TasksListScreen] لما هو أوسع (لوحي/سطح مكتب).
///
/// لوحة Kanban (`tasks_board_screen.dart`) لها نقطة دخول مستقلة
/// خاصة بها على `RouteNames.tasksBoard` (`/tasks/board`، محمية بـ
/// `PlatformGuard` للشاشات الكبيرة فقط) بنسخة [TasksCubit] منفصلة
/// تماماً — وليس عبر هذه الشاشة، لأن `/tasks/board` مسار مباشر مستقل
/// قد يُفتح دون المرور بـ `/tasks` أصلاً (رابط عميق، أو تنقّل مباشر من
/// القائمة الجانبية لاحقاً).
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<TasksCubit>(
              create: (_) => sl<TasksCubit>()..loadInitial(user),
              child: _TasksBody(user: user),
            );
          },
        );
      },
    );
  }
}

class _TasksBody extends StatelessWidget {
  const _TasksBody({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (BuildContext context, TasksState state) {
        return state.maybeWhen<Widget>(
          orElse: () => context.shellMode.isMobile
              ? MyTasksScreen(user: user)
              : TasksListScreen(user: user),
          loading: () =>
              const Scaffold(body: LoadingIndicator(label: 'جارٍ تحميل المهام...')),
          error: (Failure failure) => Scaffold(
            appBar: AppBar(title: const Text('المهام')),
            body: ErrorView(
              title: 'تعذّر تحميل المهام',
              message: failure.message,
              onRetry: () => context.read<TasksCubit>().loadInitial(user),
            ),
          ),
        );
      },
    );
  }
}
