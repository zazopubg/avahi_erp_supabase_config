import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../../domain/repositories/i_notification_repository.dart';
import '../../../dto/notification_dto.dart';
import '../realtime/notification_subscription.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [INotificationRepository] فوق جدول `public.notifications` عبر
/// Supabase، مع [watchNewNotifications] مُفوَّضة إلى
/// [NotificationSubscription] (Realtime). 🆕
class NotificationRepositoryImpl implements INotificationRepository {
  NotificationRepositoryImpl({
    sb.SupabaseClient? client,
    NotificationSubscription? subscription,
  })  : _client = client ?? SupabaseClientProvider.client,
        _subscription = subscription ?? NotificationSubscription();

  final sb.SupabaseClient _client;
  final NotificationSubscription _subscription;

  @override
  Future<ResultOf<List<AppNotification>>> getNotifications({
    required String userId,
    bool unreadOnly = false,
  }) async {
    try {
      sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _client
          .from(ApiConstants.tableNotifications)
          .select()
          .eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final List<Map<String, dynamic>> rows =
          await query.order('created_at', ascending: false);

      return Right<Failure, List<AppNotification>>(
        rows
            .map((Map<String, dynamic> row) => NotificationDto.fromJson(row).toEntity())
            .toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<AppNotification>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<AppNotification>> markAsRead(String notificationId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableNotifications)
          .update(<String, dynamic>{
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', notificationId)
          .select()
          .single();
      return Right<Failure, AppNotification>(NotificationDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, AppNotification>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<void>> markAllAsRead(String userId) async {
    try {
      await _client
          .from(ApiConstants.tableNotifications)
          .update(<String, dynamic>{
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      return Left<Failure, void>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Stream<AppNotification> watchNewNotifications(String userId) {
    return _subscription.watchUserNotifications(userId);
  }
}
