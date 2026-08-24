/// حالة المهمة ضمن لوحة Kanban (Prompt 16)، مطابقة لعمود
/// `tasks.status` (انظر `005_create_tasks.sql` → `tasks_status_check`).
enum TaskStatus {
  /// لم يبدأ العمل بها بعد (عمود "قائمة الانتظار" في Kanban).
  todo,

  /// قيد التنفيذ حالياً.
  inProgress,

  /// بانتظار المراجعة قبل الإغلاق.
  review,

  /// اكتملت المهمة بالكامل.
  done,

  /// معلّقة بسبب عائق يمنع المتابعة.
  blocked;

  String get dbValue {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.review:
        return 'review';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.blocked:
        return 'blocked';
    }
  }

  static TaskStatus fromDbValue(String value) {
    return TaskStatus.values.firstWhere(
      (TaskStatus s) => s.dbValue == value,
      orElse: () => TaskStatus.todo,
    );
  }

  bool get isTodo => this == TaskStatus.todo;
  bool get isInProgress => this == TaskStatus.inProgress;
  bool get isReview => this == TaskStatus.review;
  bool get isDone => this == TaskStatus.done;
  bool get isBlocked => this == TaskStatus.blocked;
}
