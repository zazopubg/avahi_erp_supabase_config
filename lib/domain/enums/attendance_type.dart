/// حالة اعتماد سجل الحضور، مطابقة لعمود `attendance.status` (انظر
/// `006_create_attendance.sql` → `attendance_status_check`).
///
/// ملاحظة تسمية: الشجرة المرجعية لهذه الخطوة (Prompt 05) تسمّي هذا
/// التعداد `attendance_type`؛ أُبقي على هذا الاسم حرفياً لضمان
/// التطابق مع الهيكل الشجري المعتمد، رغم أنه يمثّل فعلياً "حالة"
/// اعتماد السجل (pending/approved/rejected) وليس "نوعاً" مستقلاً.
/// لتمييز طريقة تسجيل الحضور (GPS مقابل QR) استُحدث تعداد منفصل هو
/// [CheckMethod] بحسب متطلبات هذه الخطوة أيضاً.
enum AttendanceType {
  /// بانتظار اعتماد المشرف/رئيس العمال.
  pending,

  /// اعتُمد السجل من قبل المسؤول المخوّل.
  approved,

  /// رُفض السجل (مثال: فشل التحقق الجغرافي ولم يُعتمد يدوياً).
  rejected;

  String get dbValue => name;

  static AttendanceType fromDbValue(String value) {
    return AttendanceType.values.firstWhere(
      (AttendanceType s) => s.dbValue == value,
      orElse: () => AttendanceType.pending,
    );
  }

  bool get isPending => this == AttendanceType.pending;
  bool get isApproved => this == AttendanceType.approved;
  bool get isRejected => this == AttendanceType.rejected;
}
