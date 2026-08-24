import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/enums/related_entity_type.dart';
import '../../../../navigation/route_names.dart';

/// حالة `NotificationsCubit` الكاملة — Union Type مكتوب يدوياً (بلا
/// `freezed`)، بنفس نمط `EquipmentState`/`DocumentsState`/`PunchState`
/// تماماً: ثلاث حالات فقط (`NotificationsLoading` / `NotificationsLoaded`
/// / `NotificationsError`). 🆕 (Prompt 23)
sealed class NotificationsState {
  const NotificationsState();

  T when<T>({
    required T Function() loading,
    required T Function(NotificationsData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final NotificationsState state = this;
    return switch (state) {
      NotificationsLoading() => loading(),
      NotificationsLoaded(:final data) => loaded(data),
      NotificationsError(:final failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(NotificationsData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [NotificationsData] الحالية إن كانت الحالة [NotificationsLoaded]،
  /// أو `null` — بنفس نمط `EquipmentState.dataOrNull`.
  NotificationsData? get dataOrNull => maybeWhen<NotificationsData?>(
        orElse: () => null,
        loaded: (NotificationsData d) => d,
      );
}

/// جارٍ التحميل الأولي (كل إشعارات المستخدم الحالي، الأحدث أولاً).
final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

/// جاهزة لعرض كل شاشات/مكونات الميزة (`notifications_screen.dart`
/// الموحَّدة، و`notification_panel.dart` المنسدلة على سطح المكتب) —
/// الفرق بينهما بصري بحت (قائمة كاملة قابلة للتصفية مقابل أحدث عدد
/// محدود)، كلاهما يقرآن من نفس [NotificationsData.notifications].
final class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.data);

  final NotificationsData data;
}

/// فشل تعذّر معه تحميل أي إشعارات إطلاقاً — يعتمد `Retry` في الشاشة
/// لإعادة `NotificationsCubit.loadInitial`.
final class NotificationsError extends NotificationsState {
  const NotificationsError(this.failure);

  final Failure failure;
}

/// حزمة بيانات ميزة الإشعارات المجمّعة — يحملها [NotificationsLoaded] وحدها.
class NotificationsData {
  const NotificationsData({
    required this.currentUser,
    this.notifications = const <AppNotification>[],
    this.unreadOnlyFilter = false,
    this.isRefreshing = false,
    this.isMarkingAllAsRead = false,
    this.markingAsReadIds = const <String>{},
  });

  final AppUser currentUser;

  /// كل إشعارات المستخدم الحالي (مقروءة وغير مقروءة معاً) — الأحدث
  /// أولاً، مُحمَّلة عبر `GetNotificationsUsecase(unreadOnly: false)`
  /// ومُحدَّثة لحظياً بأي إشعار جديد وارد عبر
  /// `INotificationRepository.watchNewNotifications` (انظر توثيق
  /// القرار الكامل في `NotificationsCubit`).
  final List<AppNotification> notifications;

  /// عند `true`، تُعرض غير المقروءة فقط — `notifications_screen.dart`
  /// (تبويب/مفتاح تبديل أعلى القائمة) و`notification_panel.dart` (لا
  /// يعرض هذا الفلتر، يستهلك [notifications] كاملة دائماً بحدّ أقصى
  /// عدد عناصر).
  final bool unreadOnlyFilter;

  /// عملية تحديث (سحب للتحديث) جارية حالياً.
  final bool isRefreshing;

  /// عملية "تعليم الكل كمقروء" جارية حالياً.
  final bool isMarkingAllAsRead;

  /// معرّفات إشعارات قيد التعليم كمقروءة حالياً (تعليم فردي) — تسمح
  /// بعرض مؤشر تحميل مصغّر لكل عنصر على حدة دون تجميد القائمة كاملة.
  final Set<String> markingAsReadIds;

  int get unreadCount =>
      notifications.where((AppNotification n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  /// [notifications] بعد تطبيق [unreadOnlyFilter] الحالي —
  /// `notifications_screen.dart`.
  List<AppNotification> get filteredNotifications => unreadOnlyFilter
      ? notifications.where((AppNotification n) => !n.isRead).toList(
            growable: false,
          )
      : notifications;

  /// أحدث عدد محدود من الإشعارات (غير المقروءة أولاً ثم البقية) —
  /// `notification_panel.dart` (اللوحة المنسدلة على سطح المكتب، عرض
  /// مضغوط بحد أقصى [limit] عنصراً بدل القائمة الكاملة).
  List<AppNotification> latest({int limit = 6}) =>
      notifications.take(limit).toList(growable: false);

  NotificationsData copyWith({
    AppUser? currentUser,
    List<AppNotification>? notifications,
    bool? unreadOnlyFilter,
    bool? isRefreshing,
    bool? isMarkingAllAsRead,
    Set<String>? markingAsReadIds,
  }) {
    return NotificationsData(
      currentUser: currentUser ?? this.currentUser,
      notifications: notifications ?? this.notifications,
      unreadOnlyFilter: unreadOnlyFilter ?? this.unreadOnlyFilter,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isMarkingAllAsRead: isMarkingAllAsRead ?? this.isMarkingAllAsRead,
      markingAsReadIds: markingAsReadIds ?? this.markingAsReadIds,
    );
  }
}

/// يحوّل [AppNotification.relatedEntityType] إلى `RouteNames` الوجهة
/// المناسبة للتنقّل المباشر عند الضغط على الإشعار. 🆕
///
/// ⚠️ قرار تصميم مهم (وجهة القائمة العامة، لا الكيان المحدَّد نفسه):
/// كل مسارات الكيان المفرد المتاحة فعلياً في `app_router.dart`
/// (`RoutePaths.projectDetails`، `documentDetails`،
/// `punchListDetails`...) تتطلب حالياً تمرير نسخة `Cubit` حيّة عبر
/// `extra:` إلى جانب معرّف الكيان (انظر توثيق `ProjectRouteArgs`/
/// `DocumentRouteArgs`/`PunchItemDetailsRouteArgs`) — لا يوجد دعم
/// لبناء تلك الحالة من `relatedEntityId` وحده عبر رابط عميق (Deep
/// Link) في أي من هذه المسارات بعد. لذا يوجّه إشعار مرتبط بمشروع أو
/// مستند أو عنصر ملاحظات إلى **شاشة القائمة العامة** لميزته (التي
/// تُحمَّل ذاتياً وتفتح `Cubit` خاصاً بها) بدل محاولة فتح رابط عميق
/// غير مدعوم — بنفس منطق قيود Deep Link الموثَّقة أصلاً في
/// `RoutePaths.projectDetails`/`documentDetails`. توسيع هذا لاحقاً
/// (تحميل الكيان بمعرّفه ثم فتح تفاصيله مباشرة) خارج نطاق هذه الخطوة.
String? notificationRouteName(RelatedEntityType? type) {
  if (type == null) return null;
  return switch (type) {
    RelatedEntityType.fieldReport => RouteNames.fieldReports,
    RelatedEntityType.punchItem => RouteNames.punchList,
    RelatedEntityType.task => RouteNames.tasks,
    RelatedEntityType.attendance => RouteNames.attendance,
    RelatedEntityType.equipment => RouteNames.equipment,
    RelatedEntityType.project => RouteNames.projects,
  };
}
