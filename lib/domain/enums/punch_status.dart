/// حالة عنصر قائمة الملاحظات (Punch List)، مطابقة لعمود
/// `punch_items.status` (انظر `008_create_punch_items.sql` →
/// `punch_items_status_check`): open → in_progress → resolved → closed.
enum PunchStatus {
  /// فُتح العنصر ولم يبدأ العمل عليه بعد.
  open,

  /// قيد المعالجة/الإصلاح حالياً.
  inProgress,

  /// عولج/أُصلح، بانتظار الإغلاق النهائي (تأكيد إضافي غالباً).
  resolved,

  /// أُغلق نهائياً.
  closed;

  String get dbValue {
    switch (this) {
      case PunchStatus.open:
        return 'open';
      case PunchStatus.inProgress:
        return 'in_progress';
      case PunchStatus.resolved:
        return 'resolved';
      case PunchStatus.closed:
        return 'closed';
    }
  }

  static PunchStatus fromDbValue(String value) {
    return PunchStatus.values.firstWhere(
      (PunchStatus s) => s.dbValue == value,
      orElse: () => PunchStatus.open,
    );
  }

  bool get isOpen => this == PunchStatus.open;
  bool get isInProgress => this == PunchStatus.inProgress;
  bool get isResolved => this == PunchStatus.resolved;
  bool get isClosed => this == PunchStatus.closed;
}
