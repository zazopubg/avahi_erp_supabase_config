import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../dto/notification_dto.dart';
import 'realtime_manager.dart';

/// يبث صفوف `public.notifications` الجديدة لحظياً لمستخدم محدد. 🆕
/// المصدر الفعلي لكل إشعار هو الخادم (Database Webhooks تستدعي Edge
/// Functions مثل `report-notifications`/`equipment-alert`/
/// `leave-request-notify`، Prompt 04) التي تُدرج الصف مباشرة في
/// `public.notifications`؛ هذا الاشتراك فقط ينقل الإدراج الجديد إلى
/// العميل لحظياً دون Polling.
///
/// يُستهلك من [INotificationRepository.watchNewNotifications] في
/// `repositories/notification_repository_impl.dart`.
class NotificationSubscription {
  NotificationSubscription({RealtimeManager? realtimeManager})
      : _realtimeManager = realtimeManager ?? RealtimeManager();

  final RealtimeManager _realtimeManager;

  Stream<AppNotification> watchUserNotifications(String userId) {
    final StreamController<AppNotification> controller =
        StreamController<AppNotification>.broadcast();
    controller.onCancel = controller.close;
    final String channelName = 'notifications:user_id=eq.$userId';

    _realtimeManager.channelFor(channelName, (sb.RealtimeChannel channel) {
      return channel.onPostgresChanges(
        event: sb.PostgresChangeEvent.insert,
        schema: 'public',
        table: ApiConstants.tableNotifications,
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (sb.PostgresChangePayload payload) {
          controller.add(NotificationDto.fromJson(payload.newRecord).toEntity());
        },
      );
    });

    return controller.stream;
  }
}
