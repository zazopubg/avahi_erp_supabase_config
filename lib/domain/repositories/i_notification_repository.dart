import '../../core/errors/failure.dart';
import '../entities/app_notification.dart';

/// عقد الوصول إلى إشعارات المستخدم داخل التطبيق (`public.notifications`). 🆕
abstract interface class INotificationRepository {
  /// يجلب إشعارات مستخدم محدد، الأحدث أولاً.
  Future<ResultOf<List<AppNotification>>> getNotifications({
    required String userId,
    bool unreadOnly = false,
  });

  /// يعلّم إشعاراً واحداً كمقروء.
  Future<ResultOf<AppNotification>> markAsRead(String notificationId);

  /// يعلّم كل إشعارات مستخدم كمقروءة دفعة واحدة.
  Future<ResultOf<void>> markAllAsRead(String userId);

  /// يبث الإشعارات الجديدة لحظياً (Supabase Realtime، Prompt 07).
  Stream<AppNotification> watchNewNotifications(String userId);
}
