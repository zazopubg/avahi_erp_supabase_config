/// نوع الإشعار داخل التطبيق، مطابق لعمود `notifications.type`. القيم
/// هنا تعكس القيد الأحدث `notifications_type_check` بعد توسيعه في
/// `019_extend_notification_types.sql` (Prompt 04) لدعم الإشعارات
/// الصادرة من Edge Functions (`report-notifications`,
/// `equipment-alert`, `leave-request-notify`). 🆕
enum NotificationType {
  general,
  taskAssigned,
  attendanceApproved,
  attendanceRejected,
  fieldReportSubmitted,
  fieldReportReviewed,
  leaveRequestSubmitted,
  leaveRequestReviewed,
  punchItemAssigned,
  equipmentAssigned,
  equipmentMaintenanceDue,
  documentUploaded;

  String get dbValue {
    switch (this) {
      case NotificationType.general:
        return 'general';
      case NotificationType.taskAssigned:
        return 'task_assigned';
      case NotificationType.attendanceApproved:
        return 'attendance_approved';
      case NotificationType.attendanceRejected:
        return 'attendance_rejected';
      case NotificationType.fieldReportSubmitted:
        return 'field_report_submitted';
      case NotificationType.fieldReportReviewed:
        return 'field_report_reviewed';
      case NotificationType.leaveRequestSubmitted:
        return 'leave_request_submitted';
      case NotificationType.leaveRequestReviewed:
        return 'leave_request_reviewed';
      case NotificationType.punchItemAssigned:
        return 'punch_item_assigned';
      case NotificationType.equipmentAssigned:
        return 'equipment_assigned';
      case NotificationType.equipmentMaintenanceDue:
        return 'equipment_maintenance_due';
      case NotificationType.documentUploaded:
        return 'document_uploaded';
    }
  }

  static NotificationType fromDbValue(String value) {
    return NotificationType.values.firstWhere(
      (NotificationType t) => t.dbValue == value,
      orElse: () => NotificationType.general,
    );
  }
}
