/// واجهة خدمة تخزين إعدادات المستخدم المحلية (Prompt 27) — مسؤولة عن
/// حفظ/استرجاع كل تفضيلات `features/settings/` عبر إعادة تحميل الصفحة
/// (Web Refresh) وإغلاق/فتح التطبيق، بنفس فلسفة [SessionService] لكن
/// لبيانات غير حسّاسة (لا تحتاج تشفيراً) بخلاف `flutter_secure_storage`.
///
/// ⚠️ قرار تصميم: عقد واحد بدلالات صريحة (Named Methods) لكل إعداد
/// على حدة — وليس `get(String key)`/`set(String key, dynamic value)`
/// عام غير مكتوب النوع — بنفس فلسفة `SessionService` (`saveAccessToken`/
/// `readAccessToken` صريحتان بدل `save('access_token', ...)` عام).
/// هذا يجعل كل استدعاء آمناً وقت الترجمة (Compile-time) ومكتشَفاً عبر
/// الإكمال التلقائي، ويمنع أخطاء كتابة صامتة في أسماء المفاتيح.
///
/// التنفيذ الفعلي [SharedPrefsSettingsService] فوق `shared_preferences`
/// (انظر الملف المجاور) — يحتاج تهيئة async واحدة عبر [init] تُستدعى
/// من `bootstrap.dart` **قبل** `runApp` (بنفس نمط `LocalDatabase`
/// و`SupabaseClientProvider.initialize()` هناك)، بعدها تبقى كل
/// القراءات/الكتابات متزامنة فعلياً (SharedPreferences تخزّن نسخة في
/// الذاكرة بعد أول تحميل) رغم توقيعها `Future`-based هنا للحفاظ على
/// إمكانية استبدال التنفيذ لاحقاً بمخزن حقيقي async (IndexedDB مباشر
/// مثلاً) دون تغيير هذا العقد.
abstract class LocalSettingsService {
  /// يحمّل المخزن الأساسي مرة واحدة — يجب استدعاؤه واستكمال انتظاره
  /// قبل أي استدعاء آخر (`bootstrap.dart`).
  Future<void> init();

  // ── وضع القفازات (Glove Mode) ─────────────────────────────────────
  Future<void> saveGloveMode(bool enabled);
  bool readGloveMode();

  // ── السمة (فاتح/داكن/تلقائي) ───────────────────────────────────────
  Future<void> saveThemeModeName(String modeName);
  String? readThemeModeName();

  // ── مقياس النص الإضافي الذي يتحكم به المستخدم يدوياً ────────────────
  Future<void> saveTextScale(double scale);
  double readTextScale();

  // ── اللغة الحالية ────────────────────────────────────────────────
  Future<void> saveLanguageCode(String languageCode);
  String? readLanguageCode();

  // ── استراتيجية المزامنة ─────────────────────────────────────────
  Future<void> saveSyncAutoEnabled(bool enabled);
  bool readSyncAutoEnabled();

  Future<void> saveLastSuccessfulSyncAt(DateTime timestamp);
  DateTime? readLastSuccessfulSyncAt();

  // ── تفضيلات الإشعارات (تصنيفات) ────────────────────────────────────
  Future<void> saveNotificationCategoryEnabled(String category, bool enabled);
  bool readNotificationCategoryEnabled(String category, {bool defaultValue = true});

  Future<void> savePushPermissionRequested(bool requested);
  bool readPushPermissionRequested();
}
