import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../../domain/enums/notification_type.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/empty_state.dart';
import '../state/home_cubit.dart';

/// قسم آخر 3 إشعارات غير مقروءة — استهلاك أولي مبسّط (بلا بث لحظي،
/// بلا صفحة كاملة مخصصة، بلا فلترة حسب النوع...)؛ التفاصيل الكاملة في
/// `features/notifications/` (Prompt 23). الضغط على إشعار يعلّمه
/// كمقروء عبر `HomeCubit.markNotificationAsRead` (تحديث متفائل محلي —
/// انظر توثيقها في `home_cubit.dart`).
///
/// مكوّن عرض بحت في جزئه الأكبر — يستقبل [notifications] جاهزة من
/// الشاشة الأب (`HomeSummary.latestUnreadNotifications`)، ولا يقرأ
/// `HomeCubit` إلا عند الضغط الفعلي على عنصر.
class AlertsSection extends StatelessWidget {
  const AlertsSection({required this.notifications, super.key});

  final List<AppNotification> notifications;

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.taskAssigned => Icons.checklist_outlined,
        NotificationType.attendanceApproved => Icons.check_circle_outline,
        NotificationType.attendanceRejected => Icons.cancel_outlined,
        NotificationType.fieldReportSubmitted ||
        NotificationType.fieldReportReviewed =>
          Icons.description_outlined,
        NotificationType.leaveRequestSubmitted ||
        NotificationType.leaveRequestReviewed =>
          Icons.event_busy_outlined,
        NotificationType.punchItemAssigned => Icons.fact_check_outlined,
        NotificationType.equipmentAssigned ||
        NotificationType.equipmentMaintenanceDue =>
          Icons.construction_outlined,
        NotificationType.documentUploaded => Icons.folder_outlined,
        NotificationType.general => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('آخر الإشعارات', style: context.textTheme.titleSmall),
        const SizedBox(height: AvahiSpacing.sm),
        if (notifications.isEmpty)
          const EmptyState(
            title: 'لا توجد إشعارات جديدة',
            icon: Icons.notifications_none_outlined,
          )
        else
          ...notifications.map(
            (AppNotification notification) => _AlertTile(
              notification: notification,
              icon: _iconFor(notification.type),
            ),
          ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.notification, required this.icon});

  final AppNotification notification;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AvahiSpacing.xs),
      child: ListTile(
        leading: Icon(icon, color: context.colors.primary),
        title: Text(notification.title),
        subtitle:
            notification.body != null ? Text(notification.body!) : null,
        trailing: Text(
          DateFormatter.relative(notification.createdAt),
          style: context.textTheme.labelSmall,
        ),
        onTap: () => context.read<HomeCubit>().markNotificationAsRead(
              notification.id,
            ),
      ),
    );
  }
}
