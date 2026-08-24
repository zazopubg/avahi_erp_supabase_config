/// نوع الإجازة، مطابق لعمود `leave_requests.leave_type` (انظر
/// `014_create_leave_requests.sql` → `leave_requests_type_check`).
///
/// ⚠️ تعداد إضافي غير مذكور صراحة في قائمة enums الخاصة بهذه الخطوة،
/// لكنه ضروري لتمثيل [LeaveRequest] "بالحقول الكاملة كما في مخطط
/// قاعدة البيانات" (كما نص عليه المطلوب صراحة)، بدل ترك `leaveType`
/// كنص حر غير آمن.
enum LeaveType {
  annual,
  sick,
  emergency,
  unpaid,
  other;

  String get dbValue => name;

  static LeaveType fromDbValue(String value) {
    return LeaveType.values.firstWhere(
      (LeaveType t) => t.dbValue == value,
      orElse: () => LeaveType.other,
    );
  }
}
