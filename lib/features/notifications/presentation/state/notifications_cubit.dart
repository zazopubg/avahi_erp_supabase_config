import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/repositories/i_notification_repository.dart';
import '../../../../domain/usecases/notifications/get_notifications_usecase.dart';
import '../../../../domain/usecases/notifications/mark_as_read_usecase.dart';
import 'notifications_state.dart';

/// `Cubit` ميزة `features/notifications/` (Prompt 23) — يقود كل
/// شاشات/مكونات الميزة معاً (`notifications_screen.dart` الموحَّدة،
/// و`navigation/shells/desktop/notification_panel.dart` المنسدلة على
/// سطح المكتب) عبر [NotificationsData] واحدة مجمّعة، بنفس فلسفة
/// `EquipmentCubit`/`DocumentsCubit` تماماً؛ والاشتراك اللحظي المدمج
/// بنفس القائمة بنفس نمط `ReportsInboxCubit`/`AttendanceCubit`.
///
/// ⚠️ قرار تصميم مهم (`INotificationRepository` مُحقَنة مباشرة، لا
/// `WatchNewNotificationsUsecase` منفصلة): الطلب الأصلي لهذه الخطوة
/// يذكر الاشتراك في `NotificationSubscription` (`data/cloud/supabase/
/// realtime/`) مباشرة، لكن ذلك صنف طبقة بيانات خام (Data Layer) —
/// استيراده مباشرة هنا يخرق حدود Clean Architecture المُلتزَم بها في
/// كل ميزة سابقة (`presentation/` لا تعرف بوجود `data/cloud/` إطلاقاً،
/// فقط `domain/repositories/` عبر الواجهات). البديل المتّبع هنا: حقن
/// [INotificationRepository] نفسها (الواجهة، لا التنفيذ) واستهلاك
/// `watchNewNotifications` منها مباشرة — بنفس سابقة `PhotosCubit`
/// (`photoRepository: sl<IPhotoRepository>()`) التي تحقن مستودعاً
/// مباشرة إلى جانب `UseCases` عند الحاجة لعملية بلا منطق عمل إضافي
/// يستحق طبقة `UseCase` خاصة به (هنا: تمرير Stream خام دون أي تحويل).
/// يبقى الحقن الأساسي [GetNotificationsUsecase]/[MarkAsReadUsecase]
/// (تحتوي [MarkAsReadUsecase.markAll] وظيفة "تعليم الكل كمقروء" —
/// بلا حاجة لصنف `MarkAllAsReadUsecase` منفصل) بنفس ما هو مطلوب حرفياً.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required GetNotificationsUsecase getNotificationsUsecase,
    required MarkAsReadUsecase markAsReadUsecase,
    required INotificationRepository notificationRepository,
  })  : _getNotificationsUsecase = getNotificationsUsecase,
        _markAsReadUsecase = markAsReadUsecase,
        _notificationRepository = notificationRepository,
        super(const NotificationsLoading());

  final GetNotificationsUsecase _getNotificationsUsecase;
  final MarkAsReadUsecase _markAsReadUsecase;
  final INotificationRepository _notificationRepository;

  StreamSubscription<AppNotification>? _subscription;

  // ── تحميل أولي + اشتراك لحظي ───────────────────────────────────

  /// يُستدعى عند دخول `notifications_screen.dart` (نقطة الدخول
  /// الوحيدة لمسار `RouteNames.notifications`) أو عند فتح
  /// `NotificationPanel` (سطح المكتب) — يجلب كل إشعارات [user] (مقروءة
  /// وغير مقروءة معاً، الأحدث أولاً) ثم يبدأ اشتراكاً لحظياً يدمج أي
  /// إشعار جديد وارد فوراً في مقدمة نفس القائمة.
  Future<void> loadInitial(AppUser user) async {
    emit(const NotificationsLoading());

    final ResultOf<List<AppNotification>> result =
        await _getNotificationsUsecase(userId: user.userId);

    result.fold(
      (Failure failure) => emit(NotificationsError(failure)),
      (List<AppNotification> notifications) {
        emit(
          NotificationsLoaded(
            NotificationsData(
              currentUser: user,
              notifications: notifications,
            ),
          ),
        );
        _subscribeToRealtime(user.userId);
      },
    );
  }

  void _subscribeToRealtime(String userId) {
    _subscription?.cancel();
    _subscription = _notificationRepository
        .watchNewNotifications(userId)
        .listen((AppNotification incoming) {
      final NotificationsData? current = state.dataOrNull;
      if (current == null) return;

      final int existingIndex = current.notifications.indexWhere(
        (AppNotification n) => n.id == incoming.id,
      );
      final List<AppNotification> updated = List<AppNotification>.of(
        current.notifications,
      );
      if (existingIndex >= 0) {
        updated[existingIndex] = incoming;
      } else {
        updated.insert(0, incoming);
      }

      emit(NotificationsLoaded(current.copyWith(notifications: updated)));
    });
  }

  /// يعيد تحميل كل الإشعارات من جديد — سحب للتحديث في
  /// `notifications_screen.dart`.
  Future<void> refresh() async {
    final NotificationsData? current = state.dataOrNull;
    if (current == null) return;

    emit(NotificationsLoaded(current.copyWith(isRefreshing: true)));
    final ResultOf<List<AppNotification>> result =
        await _getNotificationsUsecase(userId: current.currentUser.userId);
    final List<AppNotification> notifications = result.fold(
      (Failure _) => current.notifications,
      (List<AppNotification> n) => n,
    );
    final NotificationsData latest = state.dataOrNull ?? current;
    emit(
      NotificationsLoaded(
        latest.copyWith(notifications: notifications, isRefreshing: false),
      ),
    );
  }

  // ── تصفية (`notifications_screen.dart`) ───────────────────────────

  void setUnreadOnlyFilter(bool unreadOnly) {
    final NotificationsData? current = state.dataOrNull;
    if (current == null) return;
    emit(NotificationsLoaded(current.copyWith(unreadOnlyFilter: unreadOnly)));
  }

  // ── تعليم كمقروء (فردي/جماعي) ──────────────────────────────────

  /// يعلّم [notification] كمقروء — تُستدعى دائماً عند الضغط على أي
  /// إشعار (سواء انتهى الأمر بالتنقّل لكيان مرتبط أم لا، انظر
  /// [notificationRouteName]). لا تنفّذ أي استدعاء شبكة إن كان
  /// [AppNotification.isRead] `true` أصلاً. تُحدَّث القائمة محلياً
  /// فور نجاح الاستدعاء (إضافة للانتظار حتى وصول التحديث اللحظي
  /// المطابق أيضاً، بنفس منطق `ReportsInboxCubit.review`).
  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    final NotificationsData? current = state.dataOrNull;
    if (current == null) return;

    emit(
      NotificationsLoaded(
        current.copyWith(
          markingAsReadIds: <String>{
            ...current.markingAsReadIds,
            notification.id,
          },
        ),
      ),
    );

    final ResultOf<AppNotification> result = await _markAsReadUsecase(
      notification.id,
    );

    final NotificationsData latest = state.dataOrNull ?? current;
    final Set<String> clearedIds = Set<String>.of(latest.markingAsReadIds)
      ..remove(notification.id);

    result.fold(
      (Failure _) {
        emit(
          NotificationsLoaded(latest.copyWith(markingAsReadIds: clearedIds)),
        );
      },
      (AppNotification updated) {
        final List<AppNotification> updatedList = latest.notifications
            .map((AppNotification n) => n.id == updated.id ? updated : n)
            .toList(growable: false);
        emit(
          NotificationsLoaded(
            latest.copyWith(
              notifications: updatedList,
              markingAsReadIds: clearedIds,
            ),
          ),
        );
      },
    );
  }

  /// يعلّم كل إشعارات المستخدم الحالي كمقروءة دفعة واحدة — زر "تعليم
  /// الكل كمقروء" في `notifications_screen.dart`/`notification_panel.dart`.
  Future<void> markAllAsRead() async {
    final NotificationsData? current = state.dataOrNull;
    if (current == null || !current.hasUnread) return;

    emit(NotificationsLoaded(current.copyWith(isMarkingAllAsRead: true)));

    final ResultOf<void> result = await _markAsReadUsecase.markAll(
      current.currentUser.userId,
    );

    final NotificationsData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) {
        emit(
          NotificationsLoaded(latest.copyWith(isMarkingAllAsRead: false)),
        );
      },
      (_) {
        final DateTime now = DateTime.now();
        final List<AppNotification> updatedList = latest.notifications
            .map(
              (AppNotification n) => n.isRead
                  ? n
                  : n.copyWith(isRead: true, readAt: now),
            )
            .toList(growable: false);
        emit(
          NotificationsLoaded(
            latest.copyWith(
              notifications: updatedList,
              isMarkingAllAsRead: false,
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
