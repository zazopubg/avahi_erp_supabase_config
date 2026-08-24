import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/enums/task_priority.dart';
import '../../../../domain/enums/task_status.dart';

/// حالة `TasksCubit` الكاملة — Union Type مكتوب يدوياً (`sealed class`
/// + تفريغ أنماط `switch`)، بنفس نمط `attendance_state.dart`/`auth_state.dart`/
/// `home_state.dart` تماماً (بلا `freezed`).
///
/// ثلاث حالات فقط تحديداً كما طُلب في Prompt 16 — `TasksLoading` /
/// `TasksLoaded` / `TasksError` — على عكس `AttendanceState` الأوسع
/// (ست حالات)؛ التمييز بين "تحميل أولي" و"تحميل لوحة Kanban" و"تحديث
/// تفاؤلي جارٍ" يتم كله ضمن حقول [TasksData] نفسها (`isBoardLoading`)
/// وليس عبر حالات إضافية، لأن واجهة `tasks_board_screen.dart` تبقى
/// تفاعلية بالكامل (بطاقات قابلة للسحب) طوال أي عملية تحديث خلفية،
/// ولا ينبغي أبداً استبدال كامل الشجرة بمؤشر تحميل عند كل سحب/إفلات.
sealed class TasksState {
  const TasksState();

  /// تفريغ أنماط شامل (Exhaustive) — كل الحالات الثلاث إلزامية.
  T when<T>({
    required T Function() loading,
    required T Function(TasksData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final TasksState state = this;
    return switch (state) {
      TasksLoading() => loading(),
      TasksLoaded(:final data) => loaded(data),
      TasksError(:final failure) => error(failure),
    };
  }

  /// تفريغ أنماط جزئي — كل الحالات اختيارية، مع [orElse] إلزامي.
  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(TasksData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [TasksData] الحالية إن كانت الحالة [TasksLoaded]، أو `null` —
  /// مختصر مفيد للشاشات التي تحتاج قراءة آخر بيانات معروفة دون تفريغ
  /// أنماط كامل في كل مكان.
  TasksData? get dataOrNull =>
      maybeWhen<TasksData?>(orElse: () => null, loaded: (TasksData d) => d);
}

/// جارٍ التحميل الأولي (تحديد المشروع الحالي + جلب مهام المستخدم).
final class TasksLoading extends TasksState {
  const TasksLoading();
}

/// جاهزة لعرض كل شاشات الميزة — تفصيل التحميلات الجزئية اللاحقة
/// (لوحة Kanban، تصفية...) داخل [TasksData] نفسها.
final class TasksLoaded extends TasksState {
  const TasksLoaded(this.data);

  final TasksData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً (مثال: فشل تحديد المشروع
/// الحالي أو جلب مهام المستخدم). يعتمد `Retry` في الشاشة لإعادة
/// [TasksCubit.loadInitial].
final class TasksError extends TasksState {
  const TasksError(this.failure);

  final Failure failure;
}

/// تمثيل عرض خفيف (Presentation-only) لشخص يمكن إسناد مهمة إليه.
///
/// ⚠️ قرار تصميم متعمَّد: `features/users/` (دليل المستخدمين الفعلي
/// بأسمائهم الكاملة) لم يُبنَ بعد (Prompt 26)، ولا يوجد حالياً أي
/// `IUserRepository`/جدول أعضاء محلي يوفّر قائمة "كل أعضاء الشركة".
/// لذا يُشتق [TaskAssignee.knownFrom] هذا من معرّفات `assignedTo`/
/// `createdBy` الفريدة الظاهرة فعلياً ضمن مهام المشروع المحمَّلة
/// حالياً — بنفس أسلوب "معرّف مختصر" المعتمد أصلاً في
/// `features/attendance/presentation/widgets/worker_row.dart`
/// (`_shortUserId`) لنفس السبب تحديداً. يُستبدل هذا لاحقاً بقائمة
/// حقيقية من `features/users/` دون أي تغيير في واجهة [AssigneeSelector]
/// نفسها (`presentation/widgets/assignee_selector.dart`).
class TaskAssignee {
  const TaskAssignee({required this.userId, required this.displayLabel});

  final String userId;
  final String displayLabel;

  static String shortLabelOf(String userId) =>
      userId.length > 8 ? '#${userId.substring(0, 8)}' : '#$userId';

  /// يستخرج قائمة مُسنَدين مرشَّحين فريدة من [tasks] (كل معرّف
  /// `assignedTo` غير فارغ)، مرتّبة أبجدياً حسب المعرّف المختصر.
  static List<TaskAssignee> knownFrom(List<Task> tasks) {
    final Set<String> ids = <String>{
      for (final Task t in tasks)
        if (t.assignedTo != null) t.assignedTo!,
    };
    final List<TaskAssignee> result = ids
        .map(
          (String id) =>
              TaskAssignee(userId: id, displayLabel: shortLabelOf(id)),
        )
        .toList();
    result.sort(
      (TaskAssignee a, TaskAssignee b) => a.displayLabel.compareTo(b.displayLabel),
    );
    return result;
  }
}

/// حزمة بيانات ميزة المهام المجمّعة — يحملها [TasksLoaded] وحدها،
/// بنفس نمط `AttendanceData`/`HomeSummary`.
class TasksData {
  const TasksData({
    required this.currentUser,
    this.project,
    this.myTasks = const <Task>[],
    this.projectTasks = const <Task>[],
    this.isBoardLoading = false,
    this.statusFilter,
    this.priorityFilter,
    this.assigneeFilter,
    this.searchQuery = '',
  });

  final AppUser currentUser;

  /// المشروع الحالي (أول مشروع نشط ضمن مشاريع المستخدم — نفس منطق
  /// `HomeCubit._loadCurrentProject`/`AttendanceCubit.loadInitial`)،
  /// أو `null` إن لم يملك المستخدم أي مشروع بعد.
  final Project? project;

  /// مهام المستخدم الحالي فقط (`GetMyTasksUsecase`) — `my_tasks_screen.dart`.
  final List<Task> myTasks;

  /// كل مهام [project] (`GetProjectTasksUsecase`) — `tasks_board_screen.dart`
  /// و`tasks_list_screen.dart` (سطح المكتب). فارغة حتى يُستدعى
  /// `TasksCubit.loadBoard` صراحة (تحميل كسول، بنفس نمط
  /// `AttendanceCubit.loadMonitor`).
  final List<Task> projectTasks;
  final bool isBoardLoading;

  // ── تصفية (`task_filter_bar.dart`) ────────────────────────────
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final String? assigneeFilter;
  final String searchQuery;

  /// مُسنَدون مرشَّحون لحوار الإسناد (`task_assign_dialog.dart`) —
  /// مُشتقّون من [projectTasks] إن كانت محمَّلة، وإلا من [myTasks].
  List<TaskAssignee> get assignableUsers =>
      TaskAssignee.knownFrom(projectTasks.isNotEmpty ? projectTasks : myTasks);

  bool get hasActiveFilters =>
      statusFilter != null ||
      priorityFilter != null ||
      assigneeFilter != null ||
      searchQuery.trim().isNotEmpty;

  List<Task> _applyFilters(List<Task> source) {
    final String query = searchQuery.trim().toLowerCase();
    return source.where((Task t) {
      if (statusFilter != null && t.status != statusFilter) return false;
      if (priorityFilter != null && t.priority != priorityFilter) {
        return false;
      }
      if (assigneeFilter != null && t.assignedTo != assigneeFilter) {
        return false;
      }
      if (query.isNotEmpty && !t.title.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// [myTasks] بعد تطبيق التصفية الحالية — `my_tasks_screen.dart`.
  List<Task> get filteredMyTasks => _applyFilters(myTasks);

  /// [projectTasks] بعد تطبيق التصفية الحالية — `tasks_board_screen.dart`/
  /// `tasks_list_screen.dart`.
  List<Task> get filteredProjectTasks => _applyFilters(projectTasks);

  /// [filteredProjectTasks] مُجمَّعة حسب [TaskStatus] لأعمدة لوحة
  /// Kanban (`kanban_column.dart`)، مرتّبة داخل كل عمود حسب
  /// `Task.kanbanOrder`.
  Map<TaskStatus, List<Task>> get boardColumns {
    final Map<TaskStatus, List<Task>> columns = <TaskStatus, List<Task>>{
      for (final TaskStatus status in TaskStatus.values) status: <Task>[],
    };
    for (final Task t in filteredProjectTasks) {
      columns[t.status]!.add(t);
    }
    for (final List<Task> list in columns.values) {
      list.sort((Task a, Task b) => a.kanbanOrder.compareTo(b.kanbanOrder));
    }
    return columns;
  }

  TasksData copyWith({
    AppUser? currentUser,
    Project? project,
    bool clearProject = false,
    List<Task>? myTasks,
    List<Task>? projectTasks,
    bool? isBoardLoading,
    TaskStatus? statusFilter,
    bool clearStatusFilter = false,
    TaskPriority? priorityFilter,
    bool clearPriorityFilter = false,
    String? assigneeFilter,
    bool clearAssigneeFilter = false,
    String? searchQuery,
  }) {
    return TasksData(
      currentUser: currentUser ?? this.currentUser,
      project: clearProject ? null : (project ?? this.project),
      myTasks: myTasks ?? this.myTasks,
      projectTasks: projectTasks ?? this.projectTasks,
      isBoardLoading: isBoardLoading ?? this.isBoardLoading,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      priorityFilter: clearPriorityFilter
          ? null
          : (priorityFilter ?? this.priorityFilter),
      assigneeFilter: clearAssigneeFilter
          ? null
          : (assigneeFilter ?? this.assigneeFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
