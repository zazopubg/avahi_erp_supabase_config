import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../utils/logger.dart';
import 'local_settings_service.dart';

/// تنفيذ [LocalSettingsService] الفعلي فوق `shared_preferences` —
/// يُبقي كل تفضيلات `features/settings/` محفوظة عبر إعادة تحميل
/// الصفحة (Web Refresh) وإغلاق/فتح التطبيق، بنفس دور
/// [SecureSessionService] لكن دون تشفير (لا حاجة له لبيانات عرض بحتة
/// كوضع القفازات أو اللغة المفضّلة).
///
/// ⚠️ [init] يُستدعى مرة واحدة فقط من `bootstrap.dart` **قبل**
/// `runApp` (بنفس نمط `sl<LocalDatabase>()` هناك) — يفشل الإقلاع
/// بوضوح إن تعذّر الوصول لـ `SharedPreferences` بدل ترك كل قراءة لاحقة
/// (`readGloveMode`/`readThemeModeName`...) تعتمد على مثيل `null` غير
/// مهيَّأ. بعد [init]، كل القراءات متزامنة فعلياً (`SharedPreferences`
/// تخزّن نسخة كاملة في الذاكرة بعد أول تحميل) رغم بقاء توقيع الكتابة
/// `Future`-based التزاماً بعقد [LocalSettingsService] نفسه.
class SharedPrefsSettingsService implements LocalSettingsService {
  SharedPreferences? _prefs;

  SharedPreferences get _requirePrefs {
    final SharedPreferences? prefs = _prefs;
    assert(
      prefs != null,
      'SharedPrefsSettingsService.init() لم يُستدعَ بعد — '
      'يجب استدعاؤه من bootstrap.dart قبل أي استخدام.',
    );
    return prefs ?? (throw StateError('SharedPrefsSettingsService غير مهيَّأة.'));
  }

  @override
  Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info('SharedPrefsSettingsService: تمت التهيئة بنجاح.');
  }

  // ── وضع القفازات ────────────────────────────────────────────────

  @override
  Future<void> saveGloveMode(bool enabled) =>
      _requirePrefs.setBool(StorageKeys.prefsGloveMode, enabled);

  @override
  bool readGloveMode() =>
      _requirePrefs.getBool(StorageKeys.prefsGloveMode) ?? false;

  // ── السمة ──────────────────────────────────────────────────────

  @override
  Future<void> saveThemeModeName(String modeName) =>
      _requirePrefs.setString(StorageKeys.prefsThemeMode, modeName);

  @override
  String? readThemeModeName() =>
      _requirePrefs.getString(StorageKeys.prefsThemeMode);

  // ── مقياس النص ─────────────────────────────────────────────────

  @override
  Future<void> saveTextScale(double scale) =>
      _requirePrefs.setDouble(StorageKeys.prefsTextScale, scale);

  @override
  double readTextScale() =>
      _requirePrefs.getDouble(StorageKeys.prefsTextScale) ?? 1.0;

  // ── اللغة ──────────────────────────────────────────────────────

  @override
  Future<void> saveLanguageCode(String languageCode) =>
      _requirePrefs.setString(StorageKeys.prefsLocale, languageCode);

  @override
  String? readLanguageCode() =>
      _requirePrefs.getString(StorageKeys.prefsLocale);

  // ── المزامنة ──────────────────────────────────────────────────

  @override
  Future<void> saveSyncAutoEnabled(bool enabled) =>
      _requirePrefs.setBool(StorageKeys.syncAutoEnabled, enabled);

  @override
  bool readSyncAutoEnabled() =>
      _requirePrefs.getBool(StorageKeys.syncAutoEnabled) ?? true;

  @override
  Future<void> saveLastSuccessfulSyncAt(DateTime timestamp) =>
      _requirePrefs.setString(
        StorageKeys.syncLastSuccessAt,
        timestamp.toIso8601String(),
      );

  @override
  DateTime? readLastSuccessfulSyncAt() {
    final String? raw = _requirePrefs.getString(StorageKeys.syncLastSuccessAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── الإشعارات ─────────────────────────────────────────────────

  @override
  Future<void> saveNotificationCategoryEnabled(
    String category,
    bool enabled,
  ) =>
      _requirePrefs.setBool(
        '${StorageKeys.notificationCategoryPrefix}$category',
        enabled,
      );

  @override
  bool readNotificationCategoryEnabled(
    String category, {
    bool defaultValue = true,
  }) =>
      _requirePrefs.getBool(
        '${StorageKeys.notificationCategoryPrefix}$category',
      ) ??
      defaultValue;

  @override
  Future<void> savePushPermissionRequested(bool requested) =>
      _requirePrefs.setBool(
        StorageKeys.notificationPermissionRequested,
        requested,
      );

  @override
  bool readPushPermissionRequested() =>
      _requirePrefs.getBool(StorageKeys.notificationPermissionRequested) ??
      false;
}
