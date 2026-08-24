import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../platform/capability_service.dart';
import '../platform/platform_detector.dart';
import '../services/camera_service.dart';
import '../services/file_picker_service.dart';
import '../services/file_picker_service_impl.dart';
import '../services/gps_location_service.dart';
import '../services/haptic_service.dart';
import '../services/image_picker_camera_service.dart';
import '../services/local_settings_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/secure_session_service.dart';
import '../services/session_service.dart';
import '../services/shared_prefs_settings_service.dart';
import '../services/web_notification_service.dart';
import '../utils/image_compressor.dart';

/// يسجّل خدمات `core/` التي أصبح لها تنفيذ فعلي متاح اليوم — الكل هنا
/// [Singleton] كسول (`registerLazySingleton`) لأنها بلا حالة تُذكر أو
/// حالتها بسيطة (جلسة داخلية، إعدادات ثابتة) ولا تتطلب إعادة إنشاء عبر
/// عمر التطبيق.
///
/// ⚠️ ملاحظة تصميم مهمة: عدة عقود ضمن `core/services/` (Prompt 02) ما
/// زالت واجهات مجرّدة (`abstract class`) بلا أي تنفيذ فعلي بعد — بانتظار
/// الـ Prompt الذي تحتاجها ميزته فعلياً لتُبنى بشكل صحيح (مثال:
/// `CameraService` سيحتاج `image_picker` فعلياً فقط عند بناء
/// `features/photos/`، Prompt 18). تسجيلها هنا الآن بتنفيذ وهمي فارغ
/// سيُخفي أخطاء لاحقاً بدل كشفها؛ لذا تُترك غير مسجَّلة عمداً حتى ذلك
/// الحين:
/// - [LocationService]      → ✅ [GpsLocationService] (Prompt 15، أول
///   ميزة تحتاجه فعلياً: `features/attendance/` للجيوفنسينغ). سيُعاد
///   استخدام نفس التسجيل لاحقاً من `features/field_reports/`/`photos/`
///   دون أي تعديل هنا.
/// - [CameraService]        → ✅ [ImagePickerCameraService] (Prompt 17،
///   أول ميزة تحتاجه فعلياً: `features/field_reports/` لإرفاق صور
///   بتقرير ميداني عبر `report_photo_attach.dart`). أُعيد استخدام نفس
///   التسجيل الآن من `features/photos/` (Prompt 18) دون أي تعديل هنا.
/// - [ImageCompressor]      → ✅ [ImagePackageCompressor] (Prompt 18،
///   أول ميزة تحتاجه فعلياً: `features/photos/` عند التقاط صورة
///   ميدانية — `photos_cubit.dart` يضغطها فوراً قبل إدراجها في طابور
///   الرفع المحلي). يستبدل [NoopImageCompressor] المؤقت (Prompt 02).
/// - [FilePickerService]    → `features/documents/` (Prompt 21)
/// - [PrintService]         → `features/documents/` (Prompt 21) — لم
///   يُستهلك فعلياً من `features/field_reports/` في هذه الخطوة؛
///   `report_export_screen.dart` يعتمد نسخ نصي (`Clipboard`) بدل
///   الطباعة المباشرة حالياً.
/// - [ShareService]         → أول استخدام فعلي لاحقاً (Prompt 21)
/// - [NotificationService]  → ✅ [WebNotificationService] فوق
///   Notification API القياسي للمتصفح (Prompt 27، أول ميزة تحتاجه
///   فعلياً: `features/settings/notification_settings.dart` — الوعد
///   القديم بربطه ضمن Prompt 23 لم يُنفَّذ فعلياً هناك، انظر توثيق
///   القرار الكامل في `WebNotificationService`).
/// - `DeviceInfoService`    → لا يستهلكها أي شيء بعد؛ تُسجَّل عند أول
///   حاجة فعلية (شاشة تشخيص/دعم فني ضمن `settings`، Prompt 27).
/// - [LocalSettingsService] → ✅ [SharedPrefsSettingsService] فوق
///   `shared_preferences` (Prompt 27، أول ميزة تحتاجه فعلياً:
///   `features/settings/` كاملة). ⚠️ يحتاج تهيئة async إضافية عبر
///   `init()` تُستدعى صراحة من `bootstrap.dart` **قبل** أي استخدام —
///   بخلاف بقية الخدمات هنا التي تكفيها `registerLazySingleton` وحدها.
void registerCoreModule(GetIt sl) {
  // ── الإعدادات ────────────────────────────────────────────────────
  sl.registerLazySingleton<AppConfig>(() => AppConfig.instance);

  // ── المنصّة (Platform) ──────────────────────────────────────────
  sl.registerLazySingleton<CapabilityService>(() => const CapabilityService());
  sl.registerLazySingleton<PlatformDetector>(() => const PlatformDetector());

  // ── خدمات لها تنفيذ فعلي اليوم ─────────────────────────────────
  // HapticService: لا جدوى فعلية منه على الويب حالياً؛ [NoopHapticService]
  // تنفيذ آمن افتراضي (لا يفعل شيئاً) يبقي كل استدعاء `sl<HapticService>()`
  // من أي طبقة أعلى صالحاً دون كسر أي شيء إن فُعِّل اهتزاز حقيقي لاحقاً
  // (مثال: عبر منصة أخرى غير الويب) دون تغيير أي استدعاء موجود.
  sl.registerLazySingleton<HapticService>(() => const NoopHapticService());

  // SessionService: [SecureSessionService] فوق `flutter_secure_storage`
  // (بدءاً من `features/auth/`، Prompt 13) — يستبدل [InMemorySessionService]
  // المؤقت (Prompt 02/11) الذي كان لا يُبقي الجلسة بعد إعادة تحميل
  // الصفحة (Web Refresh). لا تغيير مطلوب في أي استدعاء `sl<SessionService>()`
  // في بقية الطبقات (عقد `SessionService` نفسه لم يتغير سلوكياً، فقط
  // التنفيذ المسجَّل هنا).
  sl.registerLazySingleton<SessionService>(() => SecureSessionService());

  // LocationService: [GpsLocationService] فوق `geolocator` (بدءاً من
  // `features/attendance/`، Prompt 15) — انظر الملاحظة أعلاه.
  sl.registerLazySingleton<LocationService>(() => const GpsLocationService());

  // CameraService: [ImagePickerCameraService] فوق `image_picker` (بدءاً
  // من `features/field_reports/`، Prompt 17) — انظر الملاحظة أعلاه.
  sl.registerLazySingleton<CameraService>(() => ImagePickerCameraService());

  // ImageCompressor: [ImagePackageCompressor] فوق حزمة `image` (بدءاً
  // من `features/photos/`، Prompt 18) — انظر الملاحظة أعلاه.
  sl.registerLazySingleton<ImageCompressor>(() => const ImagePackageCompressor());

  // FilePickerService: [FilePickerServiceImpl] فوق حزمة `file_picker`
  // (بدءاً من `features/documents/`، Prompt 21) — أول استخدام فعلي له
  // هو `documents_manager.dart` (سطح المكتب فقط، انظر توثيق القرار في
  // `documents_cubit.dart` حول كون `documents_list.dart` الجوال عرضاً
  // فقط بلا رفع).
  sl.registerLazySingleton<FilePickerService>(() => const FilePickerServiceImpl());

  // NotificationService: [WebNotificationService] فوق Notification API
  // القياسي للمتصفح (بدءاً من `features/settings/`، Prompt 27) —
  // انظر الملاحظة أعلاه.
  sl.registerLazySingleton<NotificationService>(() => WebNotificationService());

  // LocalSettingsService: [SharedPrefsSettingsService] فوق
  // `shared_preferences` (بدءاً من `features/settings/`، Prompt 27) —
  // انظر الملاحظة أعلاه. ⚠️ `init()` **لا** يُستدعى هنا (التسجيل نفسه
  // متزامن ولا يمكنه انتظار Future) — `bootstrap.dart` يستدعيه صراحة
  // بعد `configureDependencies()` مباشرة.
  sl.registerLazySingleton<LocalSettingsService>(
    () => SharedPrefsSettingsService(),
  );
}
