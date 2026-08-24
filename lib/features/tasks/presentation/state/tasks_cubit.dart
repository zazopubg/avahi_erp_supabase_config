import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/enums/task_priority.dart';
import '../../../../domain/enums/task_status.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import '../../../../domain/usecases/tasks/assign_task_usecase.dart';
import '../../../../domain/usecases/tasks/get_my_tasks_usecase.dart';
import '../../../../domain/usecases/tasks/get_project_tasks_usecase.dart';
import '../../../../domain/usecases/tasks/update_task_status_usecase.dart';
import 'tasks_state.dart';

/// `Cubit` ميزة المهام بالكامل — يقود كل شاشات `features/tasks/`
/// (قائمة مهامي، تفاصيل/تحديث مهمة، لوحة Kanban وجدول سطح المكتب،
/// وحوار الإسناد) عبر [TasksData] واحدة مجمّعة، بنفس فلسفة
/// `AttendanceCubit` (`features/attendance/`، Prompt 15).
class TasksCubit extends Cubit<TasksState> {
  TasksCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required GetMyTasksUsecase getMyTasksUsecase,
    required GetProjectTasksUsecase getProjectTasksUsecase,
    required UpdateTaskStatusUsecase updateTaskStatusUsecase,
    required AssignTaskUsecase assignTaskUsecase,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _getMyTasksUsecase = getMyTasksUsecase,
        _getProjectTasksUsecase = getProjectTasksUsecase,
        _updateTaskStatusUsecase = updateTaskStatusUsecase,
        _assignTaskUsecase = assignTaskUsecase,
        super(const TasksLoading());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final GetMyTasksUsecase _getMyTasksUsecase;
  final GetProjectTasksUsecase _getProjectTasksUsecase;
  final UpdateTaskStatusUsecase _updateTaskStatusUsecase;
  final AssignTaskUsecase _assignTaskUsecase;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى مرة واحدة عند دخول `tasks_screen.dart`/`tasks_board_screen.dart`:
  /// يحدّد "المشروع الحالي" (نفس منطق `AttendanceCubit.loadInitial`)
  /// ثم يجلب مهام المستخدم الحالي ضمنه. لا يجلب [TasksData.projectTasks]
  /// (لوحة Kanban) هنا — تحميل كسول منفصل عبر [loadBoard]، بنفس نمط
  /// `AttendanceCubit.loadMonitor`.
  Future<void> loadInitial(AppUser user) async {
    emit(const TasksLoading());

    final ResultOf<List<Project>> projectsResult = await _getMyProjectsUsecase(
      user.userId,
    );

    final Project? project = projectsResult.fold(
      (Failure _) => null,
      (List<Project> projects) {
        if (projects.isEmpty) return null;
        return projects.firstWhere(
          (Project p) => p.status.isActive,
          orElse: () => projects.first,
        );
      },
    );

    final ResultOf<List<Task>> myTasksResult = await _getMyTasksUsecase(
      userId: user.userId,
      projectId: project?.id,
    );

    myTasksResult.fold(
      (Failure f) => emit(TasksError(f)),
      (List<Task> tasks) => emit(
        TasksLoaded(
          TasksData(currentUser: user, project: project, myTasks: tasks),
        ),
      ),
    );
  }

  /// يعيد تحميل [TasksData.myTasks] فقط (مثال: سحب-للتحديث في
  /// `my_tasks_screen.dart`) دون إعادة تحديد المشروع الحالي.
  Future<void> refreshMyTasks() async {
    final TasksData? current = state.dataOrNull;
    if (current == null) return;

    final ResultOf<List<Task>> result = await _getMyTasksUsecase(
      userId: current.currentUser.userId,
      projectId: current.project?.id,
    );

    result.fold(
      (Failure _) {},
      (List<Task> tasks) => emit(TasksLoaded(current.copyWith(myTasks: tasks))),
    );
  }

  // ── لوحة Kanban / جدول سطح المكتب ──────────────────────────────

  /// يجلب كل مهام [TasksData.project] — `tasks_board_screen.dart`
  /// (Kanban) و`tasks_list_screen.dart` (جدول). لا حاجة لمشروع محدد
  /// إن كانت [TasksData.project] فارغة أصلاً (لا مشروع نشط).
  Future<void> loadBoard() async {
    final TasksData? current = state.dataOrNull;
    final Project? project = current?.project;
    if (current == null || project == null) return;

    emit(TasksLoaded(current.copyWith(isBoardLoading: true)));

    final ResultOf<List<Task>> result = await _getProjectTasksUsecase(
      project.id,
    );

    final TasksData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) =>
          emit(TasksLoaded(latest.copyWith(isBoardLoading: false))),
      (List<Task> tasks) => emit(
        TasksLoaded(
          latest.copyWith(projectTasks: tasks, isBoardLoading: false),
        ),
      ),
    );
  }

  // ── تحديث حالة مهمة (تفاؤلي) ────────────────────────────────────

  /// يحدّث حالة/ترتيب [task] ضمن لوحة Kanban عبر **تحديث تفاؤلي
  /// (Optimistic Update)**: تُحدَّث بطاقة المهمة محلياً وتُبَثّ الحالة
  /// الجديدة **فوراً** (قبل انتظار رد الخادم إطلاقاً) لضمان سلاسة حركة
  /// السحب والإفلات في `tasks_board_screen.dart`/`kanban_column.dart`؛
  /// عند فشل [UpdateTaskStatusUsecase] فعلياً (مثال: انتقال حالة غير
  /// مسموح به عبر `TaskValidator`، أو خطأ شبكة)، تُستعاد الحالة
  /// المحفوظة *قبل* التحديث التفاؤلي (`baseline`) بالكامل — تراجع
  /// فوري تلقائي دون أي إجراء إضافي من المستخدم. تُستبدَل البطاقة عند
  /// النجاح بالكائن المُعاد فعلياً من الخادم (وليس النسخة التفاؤلية
  /// المحلية)، ضماناً لتطابق `updatedAt`/`kanbanOrder` النهائيين.
  ///
  /// تُحدَّث كلتا القائمتين معاً ([TasksData.myTasks] و
  /// [TasksData.projectTasks]) بما أن نفس المهمة قد تظهر في كليهما.
  ///
  /// يُعيد `true` عند النجاح و`false` عند الفشل (بعد التراجع) — يعتمد
  /// المستدعي (`task_update_screen.dart`) هذه القيمة لعرض رسالة خطأ
  /// مناسبة عبر `context.showSnackBar`.
  Future<bool> updateStatus({
    required Task task,
    required TaskStatus newStatus,
    int? kanbanOrder,
  }) async {
    final TasksData? baseline = state.dataOrNull;
    if (baseline == null) return false;

    final Task optimisticTask = task.copyWith(
      status: newStatus,
      kanbanOrder: kanbanOrder ?? task.kanbanOrder,
    );

    emit(
      TasksLoaded(
        baseline.copyWith(
          myTasks: _replaceTask(baseline.myTasks, optimisticTask),
          projectTasks: _replaceTask(baseline.projectTasks, optimisticTask),
        ),
      ),
    );

    final ResultOf<Task> result = await _updateTaskStatusUsecase(
      currentTask: task,
      newStatus: newStatus,
      kanbanOrder: kanbanOrder,
    );

    return result.fold(
      (Failure _) {
        // تراجع كامل إلى الحالة المحفوظة قبل التحديث التفاؤلي.
        emit(TasksLoaded(baseline));
        return false;
      },
      (Task updated) {
        final TasksData latest = state.dataOrNull ?? baseline;
        emit(
          TasksLoaded(
            latest.copyWith(
              myTasks: _replaceTask(latest.myTasks, updated),
              projectTasks: _replaceTask(latest.projectTasks, updated),
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── إسناد مهمة ────────────────────────────────────────────────

  /// يُسند [taskId] إلى [assigneeId] (أو يلغي الإسناد عند تركه
  /// `null`) — `task_assign_dialog.dart`. يُعيد `true`/`false` بنفس
  /// أسلوب [updateStatus] (بلا تحديث تفاؤلي هنا: الإسناد إجراء أقل
  /// تكراراً ولا يتطلب سلاسة حركة فورية كسحب/إفلات الكانبان).
  Future<bool> assignTask({required String taskId, String? assigneeId}) async {
    final TasksData? current = state.dataOrNull;
    if (current == null) return false;

    final ResultOf<Task> result = await _assignTaskUsecase(
      taskId: taskId,
      assigneeId: assigneeId,
    );

    return result.fold(
      (Failure _) => false,
      (Task updated) {
        final TasksData latest = state.dataOrNull ?? current;
        emit(
          TasksLoaded(
            latest.copyWith(
              myTasks: _replaceTask(latest.myTasks, updated),
              projectTasks: _replaceTask(latest.projectTasks, updated),
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── تصفية (`task_filter_bar.dart`) ──────────────────────────────

  void setStatusFilter(TaskStatus? status) {
    final TasksData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      TasksLoaded(
        current.copyWith(
          statusFilter: status,
          clearStatusFilter: status == null,
        ),
      ),
    );
  }

  void setPriorityFilter(TaskPriority? priority) {
    final TasksData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      TasksLoaded(
        current.copyWith(
          priorityFilter: priority,
          clearPriorityFilter: priority == null,
        ),
      ),
    );
  }

  void setAssigneeFilter(String? assigneeId) {
    final TasksData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      TasksLoaded(
        current.copyWith(
          assigneeFilter: assigneeId,
          clearAssigneeFilter: assigneeId == null,
        ),
      ),
    );
  }

  void setSearchQuery(String query) {
    final TasksData? current = state.dataOrNull;
    if (current == null) return;
    emit(TasksLoaded(current.copyWith(searchQuery: query)));
  }

  void clearFilters() {
    final TasksData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      TasksLoaded(
        current.copyWith(
          clearStatusFilter: true,
          clearPriorityFilter: true,
          clearAssigneeFilter: true,
          searchQuery: '',
        ),
      ),
    );
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  List<Task> _replaceTask(List<Task> source, Task updated) {
    return source
        .map((Task t) => t.id == updated.id ? updated : t)
        .toList(growable: false);
  }
}
