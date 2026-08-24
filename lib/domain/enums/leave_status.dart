/// حالة طلب الإجازة، مطابقة لعمود `leave_requests.status` (انظر
/// `014_create_leave_requests.sql` → `leave_requests_status_check`). 🆕
enum LeaveStatus {
  pending,
  approved,
  rejected,

  /// ألغاها مقدّم الطلب نفسه قبل أو بعد الاعتماد.
  cancelled;

  String get dbValue => name;

  static LeaveStatus fromDbValue(String value) {
    return LeaveStatus.values.firstWhere(
      (LeaveStatus s) => s.dbValue == value,
      orElse: () => LeaveStatus.pending,
    );
  }

  bool get isPending => this == LeaveStatus.pending;
  bool get isApproved => this == LeaveStatus.approved;
  bool get isRejected => this == LeaveStatus.rejected;
  bool get isCancelled => this == LeaveStatus.cancelled;
}
