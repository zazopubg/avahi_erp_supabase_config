import '../../../../domain/enums/sync_state.dart';

/// حالة `SettingsCubit` الكاملة — بيانات مجمّعة واحدة (وليس Union Type
/// متعدد الحالات مثل `AuthState`): بخلاف شاشات تجلب بيانات من الشبكة
/// (حيث `initial`/`loading`/`error` منطقية)، إعدادات `settings/` كلها
/// محلية بحتة (`SharedPreferences`) وتُحمَّل بشكل متزامن عملياً بعد
/// `LocalSettingsService.init()` (`bootstrap.dart`) — لا حالة تحميل
/// حقيقية تستحق التمثيل. [SettingsData] تبدأ فوراً بقيم افتراضية
/// آمنة وتتحدّث تدريجياً — بنفس فلسفة `HomeState` (تحميل تدريجي بلا
/// شاشة `Loading` كاملة تحجب الواجهة).
class SettingsData {
  const SettingsData({
    this.syncState = SyncState.pending,
    this.isSyncTriggeringNow = false,
    this.isSyncAutoEnabled = true,
    this.lastSuccessfulSyncAt,
    this.pendingOutboxCount = 0,
    this.notificationCategories = const <String, bool>{},
    this.isRequestingNotificationPermission = false,
    this.notificationPermissionGranted = false,
    this.notificationPermissionDenied = false,
  });

  /// آخر حالة معروفة لمحرّك المزامنة (`SyncScheduler.stateStream`).
  final SyncState syncState;

  /// `true` أثناء تنفيذ "مزامنة الآن" يدوياً — يُستخدم لتعطيل الزر
  /// مؤقتاً ومنع نقرات متكررة.
  final bool isSyncTriggeringNow;

  final bool isSyncAutoEnabled;

  final DateTime? lastSuccessfulSyncAt;

  final int pendingOutboxCount;

  /// حالة كل تصنيف إشعار (مفتاح التصنيف ← مُفعَّل؟) — انظر
  /// `NotificationCategories` (`notification_settings.dart`) للتصنيفات
  /// الثابتة المدعومة.
  final Map<String, bool> notificationCategories;

  final bool isRequestingNotificationPermission;
  final bool notificationPermissionGranted;
  final bool notificationPermissionDenied;

  SettingsData copyWith({
    SyncState? syncState,
    bool? isSyncTriggeringNow,
    bool? isSyncAutoEnabled,
    DateTime? lastSuccessfulSyncAt,
    bool clearLastSuccessfulSyncAt = false,
    int? pendingOutboxCount,
    Map<String, bool>? notificationCategories,
    bool? isRequestingNotificationPermission,
    bool? notificationPermissionGranted,
    bool? notificationPermissionDenied,
  }) {
    return SettingsData(
      syncState: syncState ?? this.syncState,
      isSyncTriggeringNow: isSyncTriggeringNow ?? this.isSyncTriggeringNow,
      isSyncAutoEnabled: isSyncAutoEnabled ?? this.isSyncAutoEnabled,
      lastSuccessfulSyncAt: clearLastSuccessfulSyncAt
          ? null
          : (lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt),
      pendingOutboxCount: pendingOutboxCount ?? this.pendingOutboxCount,
      notificationCategories:
          notificationCategories ?? this.notificationCategories,
      isRequestingNotificationPermission: isRequestingNotificationPermission ??
          this.isRequestingNotificationPermission,
      notificationPermissionGranted:
          notificationPermissionGranted ?? this.notificationPermissionGranted,
      notificationPermissionDenied:
          notificationPermissionDenied ?? this.notificationPermissionDenied,
    );
  }
}
