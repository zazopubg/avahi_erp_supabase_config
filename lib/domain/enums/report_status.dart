/// حالة التقرير الميداني ضمن دورة اعتماده، مطابقة لعمود
/// `field_reports.status` (انظر `007_create_field_reports.sql` →
/// `field_reports_status_check`): draft → submitted → reviewed/rejected.
enum ReportStatus {
  /// مسوّدة قيد التحرير، لم تُقدَّم بعد.
  draft,

  /// قُدِّمت للمراجعة (بانتظار توقيع/اعتماد المشرف).
  submitted,

  /// راجعها المسؤول واعتمدها.
  reviewed,

  /// رفضها المسؤول (انظر `rejectionReason` في [FieldReport]).
  rejected;

  String get dbValue => name;

  static ReportStatus fromDbValue(String value) {
    return ReportStatus.values.firstWhere(
      (ReportStatus s) => s.dbValue == value,
      orElse: () => ReportStatus.draft,
    );
  }

  bool get isDraft => this == ReportStatus.draft;
  bool get isSubmitted => this == ReportStatus.submitted;
  bool get isReviewed => this == ReportStatus.reviewed;
  bool get isRejected => this == ReportStatus.rejected;
}
