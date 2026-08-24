/// طريقة تسجيل الحضور، مطابقة لعمود `attendance.check_method` (انظر
/// `006_create_attendance.sql` → `attendance_check_method_check`). 🆕
enum CheckMethod {
  /// تسجيل عبر تحديد الموقع الجغرافي (GPS) والتحقق من الجيوفنسينغ.
  gps,

  /// تسجيل عبر مسح رمز QR ثابت في الموقع (`attendance.qr_code_id`).
  qr;

  String get dbValue => name;

  static CheckMethod fromDbValue(String value) {
    return CheckMethod.values.firstWhere(
      (CheckMethod m) => m.dbValue == value,
      orElse: () => CheckMethod.gps,
    );
  }

  bool get isGps => this == CheckMethod.gps;
  bool get isQr => this == CheckMethod.qr;
}
