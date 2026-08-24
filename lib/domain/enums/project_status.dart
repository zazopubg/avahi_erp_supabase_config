/// حالة المشروع، مطابقة تماماً لقيم عمود `projects.status` في قاعدة
/// البيانات (انظر `003_create_projects.sql` → `projects_status_check`).
enum ProjectStatus {
  /// المشروع نشط وقيد التنفيذ حالياً.
  active,

  /// المشروع متوقف مؤقتاً (تعليق مؤقت للعمل).
  onHold,

  /// المشروع اكتمل تنفيذه بالكامل.
  completed,

  /// المشروع مؤرشف (لم يعد ظاهراً في القوائم النشطة افتراضياً).
  archived;

  /// يطابق التسمية النصية بصيغة `snake_case` المخزّنة في Postgres
  /// (مثال: `onHold` ↔ `'on_hold'`)، بدل الاعتماد على [name] مباشرة.
  String get dbValue {
    switch (this) {
      case ProjectStatus.active:
        return 'active';
      case ProjectStatus.onHold:
        return 'on_hold';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.archived:
        return 'archived';
    }
  }

  static ProjectStatus fromDbValue(String value) {
    return ProjectStatus.values.firstWhere(
      (ProjectStatus s) => s.dbValue == value,
      orElse: () => ProjectStatus.active,
    );
  }

  bool get isActive => this == ProjectStatus.active;
  bool get isOnHold => this == ProjectStatus.onHold;
  bool get isCompleted => this == ProjectStatus.completed;
  bool get isArchived => this == ProjectStatus.archived;
}
