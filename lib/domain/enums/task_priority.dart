/// أولوية المهمة، مطابقة لعمود `tasks.priority` (انظر
/// `005_create_tasks.sql` → `tasks_priority_check`). نفس القيم
/// تُستخدم أيضاً في `punch_items.priority`، لذا هذا التعداد مشترك
/// بين [Task] و[PunchItem].
enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get dbValue => name;

  static TaskPriority fromDbValue(String value) {
    return TaskPriority.values.firstWhere(
      (TaskPriority p) => p.dbValue == value,
      orElse: () => TaskPriority.medium,
    );
  }

  bool get isLow => this == TaskPriority.low;
  bool get isMedium => this == TaskPriority.medium;
  bool get isHigh => this == TaskPriority.high;
  bool get isUrgent => this == TaskPriority.urgent;
}
