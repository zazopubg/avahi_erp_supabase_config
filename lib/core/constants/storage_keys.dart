/// مفاتيح التخزين المحلي الموحّدة (Local Storage / Secure Storage /
/// Drift KV) لتفادي تكرار سلاسل نصية حرفية (Magic Strings) عبر
/// الطبقات المختلفة. يُبنى عليها لاحقاً في `session_service` و
/// `data/local/` (Prompt 08).
abstract final class StorageKeys {
  // ── الجلسة والمصادقة ───────────────────────────────────────
  static const String authAccessToken = 'auth.access_token';
  static const String authRefreshToken = 'auth.refresh_token';
  static const String authUserId = 'auth.user_id';
  static const String authTenantId = 'auth.tenant_id';
  static const String authRole = 'auth.role';
  static const String authLastLoginAt = 'auth.last_login_at';

  /// تجزئة (Hash) رمز PIN المحلي السريع — انظر `features/auth/`
  /// (Prompt 13، `SecureSessionService`). لا يُخزَّن الرمز نفسه أبداً.
  static const String authPinHash = 'auth.pin_hash';

  // ── تفضيلات العرض ───────────────────────────────────────────
  static const String prefsThemeMode = 'prefs.theme_mode';
  static const String prefsLocale = 'prefs.locale';
  static const String prefsGloveMode = 'prefs.glove_mode';
  static const String prefsTextScale = 'prefs.text_scale';

  // ── المزامنة Sync ────────────────────────────────────────────
  static const String syncLastSuccessAt = 'sync.last_success_at';
  static const String syncOutboxPending = 'sync.outbox_pending_count';
  static const String syncDeviceId = 'sync.device_id';

  /// 🆕 (Prompt 27) — هل استراتيجيات المزامنة التلقائية
  /// ([ContinuousSyncStrategy]/[ForegroundSyncStrategy] عبر
  /// `SyncScheduler`) مُفعَّلة، أم أوقفها المستخدم يدوياً من
  /// `sync_settings.dart` مفضّلاً الاعتماد فقط على زر "مزامنة الآن"؟
  /// انظر توثيق القرار الكامل في `SyncScheduler.pauseAutomatic`.
  static const String syncAutoEnabled = 'sync.auto_enabled';

  // ── الإشعارات (تصنيفات، Prompt 27) ─────────────────────────────
  /// بادئة مفاتيح تفضيل كل تصنيف إشعار على حدة — انظر
  /// `LocalSettingsService.saveNotificationCategoryEnabled` (المفتاح
  /// الفعلي يُبنى بدمج هذه البادئة مع اسم التصنيف: `'notifications.category.$category'`).
  static const String notificationCategoryPrefix = 'notifications.category.';

  /// هل طلب المستخدم إذن الإشعارات من المتصفح من قبل (بصرف النظر عن
  /// نتيجة الطلب) — يمنع إعادة عرض حوار طلب الإذن تلقائياً في كل
  /// دخول لـ `notification_settings.dart`.
  static const String notificationPermissionRequested =
      'notifications.permission_requested';

  // ── الإعداد الأولي Onboarding ────────────────────────────────
  static const String onboardingCompleted = 'onboarding.completed';
  static const String onboardingSeenVersion = 'onboarding.seen_version';
}
