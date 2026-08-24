import '../../../core/errors/failure.dart';
import '../../entities/app_notification.dart';
import '../../repositories/i_notification_repository.dart';

/// UseCase جلب إشعارات المستخدم الحالي. 🆕
class GetNotificationsUsecase {
  const GetNotificationsUsecase(this._repository);

  final INotificationRepository _repository;

  Future<ResultOf<List<AppNotification>>> call({
    required String userId,
    bool unreadOnly = false,
  }) {
    return _repository.getNotifications(userId: userId, unreadOnly: unreadOnly);
  }
}
