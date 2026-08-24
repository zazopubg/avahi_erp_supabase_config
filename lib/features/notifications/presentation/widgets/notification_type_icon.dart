import 'package:flutter/material.dart';

import '../../../../domain/enums/notification_type.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/widgets/common/status_badge.dart' show AvahiStatus;

/// يحوّل [NotificationType] إلى أيقونة ودلالة لونية ([AvahiStatus])
/// مناسبة — منطق مشترك بين [NotificationTypeIcon] و`notification_tile.dart`/
/// `alerts_section.dart` (`features/home/`)، بنفس نمط
/// `equipmentStatusVisuals` في `equipment/presentation/widgets/
/// equipment_status_badge.dart`.
(IconData, AvahiStatus) notificationTypeVisuals(NotificationType type) {
  switch (type) {
    case NotificationType.taskAssigned:
      return (Icons.checklist_outlined, AvahiStatus.info);
    case NotificationType.attendanceApproved:
      return (Icons.check_circle_outline, AvahiStatus.success);
    case NotificationType.attendanceRejected:
      return (Icons.cancel_outlined, AvahiStatus.danger);
    case NotificationType.fieldReportSubmitted:
      return (Icons.description_outlined, AvahiStatus.info);
    case NotificationType.fieldReportReviewed:
      return (Icons.fact_check_outlined, AvahiStatus.success);
    case NotificationType.leaveRequestSubmitted:
      return (Icons.event_busy_outlined, AvahiStatus.info);
    case NotificationType.leaveRequestReviewed:
      return (Icons.event_available_outlined, AvahiStatus.success);
    case NotificationType.punchItemAssigned:
      return (Icons.fact_check_outlined, AvahiStatus.warning);
    case NotificationType.equipmentAssigned:
      return (Icons.construction_outlined, AvahiStatus.info);
    case NotificationType.equipmentMaintenanceDue:
      return (Icons.build_outlined, AvahiStatus.warning);
    case NotificationType.documentUploaded:
      return (Icons.folder_outlined, AvahiStatus.info);
    case NotificationType.general:
      return (Icons.notifications_outlined, AvahiStatus.neutral);
  }
}

(Color, Color) _colorsFor(AvahiColors colors, AvahiStatus status) {
  return switch (status) {
    AvahiStatus.success => (colors.successContainer, colors.onSuccessContainer),
    AvahiStatus.danger => (colors.dangerContainer, colors.onDangerContainer),
    AvahiStatus.warning => (colors.warningContainer, colors.onWarningContainer),
    AvahiStatus.info => (colors.infoContainer, colors.onInfoContainer),
    AvahiStatus.neutral => (colors.surfaceVariant, colors.onSurfaceVariant),
  };
}

/// أيقونة نوع إشعار مضمّنة داخل حاوية دائرية ملوّنة حسب دلالة
/// [NotificationType] — العنصر البصري الأول في كل من `notification_tile.dart`
/// و`notifications_screen.dart`/`notification_panel.dart`.
///
/// مكوّن عرض بحت — لا يحمل أي منطق تحديد النوع الفعلي.
class NotificationTypeIcon extends StatelessWidget {
  const NotificationTypeIcon({
    required this.type,
    super.key,
    this.size = 36,
  });

  final NotificationType type;

  /// قطر الحاوية الدائرية بالبكسل المنطقي.
  final double size;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final (IconData icon, AvahiStatus status) = notificationTypeVisuals(type);
    final (Color background, Color foreground) = _colorsFor(colors, status);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AvahiRadius.radiusFull,
      ),
      child: Icon(icon, color: foreground, size: size * 0.52),
    );
  }
}
