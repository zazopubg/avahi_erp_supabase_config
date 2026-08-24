import '../../../core/errors/failure.dart';
import '../../entities/app_notification.dart';
import '../../repositories/i_notification_repository.dart';

/// UseCase تعليم إشعار (أو كل إشعارات مستخدم) كمقروء. 🆕
class MarkAsReadUsecase {
  const MarkAsReadUsecase(this._repository);

  final INotificationRepository _repository;

  Future<ResultOf<AppNotification>> call(String notificationId) {
    return _repository.markAsRead(notificationId);
  }

  Future<ResultOf<void>> markAll(String userId) {
    return _repository.markAllAsRead(userId);
  }
}
