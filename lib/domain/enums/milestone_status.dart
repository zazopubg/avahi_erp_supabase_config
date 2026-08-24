/// 🆕 (Prompt 20) حالة المرحلة الرئيسية (Milestone) ضمن مشروع، مطابقة
/// تماماً لقيم عمود `project_milestones.status` في قاعدة البيانات
/// (انظر `020_create_project_milestones.sql` → `project_milestones_status_check`)
/// — بنفس فلسفة [ProjectStatus]/[TaskStatus] الحرفية تماماً.
enum MilestoneStatus {
  /// لم يبدأ العمل على المرحلة بعد.
  pending,

  /// المرحلة قيد التنفيذ حالياً.
  inProgress,

  /// المرحلة اكتملت بالكامل.
  completed,

  /// المرحلة متأخرة عن تاريخ الاستحقاق المحدد ([ProjectMilestone.dueDate])
  /// ولم تكتمل بعد — حالة صريحة يُحسبها [ProjectMilestone.isOverdue]
  /// تلقائياً عند القراءة، لكنها تبقى قيمة مخزّنة صراحة أيضاً لتمييز
  /// المراحل التي تجاوزت موعدها فعلياً عن "قيد التنفيذ" العادية ضمن
  /// شاشات الإدارة (`project_milestones.dart`).
  delayed;

  /// يطابق التسمية النصية بصيغة `snake_case` المخزّنة في Postgres
  /// (مثال: `inProgress` ↔ `'in_progress'`)، بدل الاعتماد على [name]
  /// مباشرة — بنفس نمط [ProjectStatus.dbValue].
  String get dbValue {
    switch (this) {
      case MilestoneStatus.pending:
        return 'pending';
      case MilestoneStatus.inProgress:
        return 'in_progress';
      case MilestoneStatus.completed:
        return 'completed';
      case MilestoneStatus.delayed:
        return 'delayed';
    }
  }

  static MilestoneStatus fromDbValue(String value) {
    return MilestoneStatus.values.firstWhere(
      (MilestoneStatus s) => s.dbValue == value,
      orElse: () => MilestoneStatus.pending,
    );
  }

  bool get isCompleted => this == MilestoneStatus.completed;
  bool get isDelayed => this == MilestoneStatus.delayed;
}
