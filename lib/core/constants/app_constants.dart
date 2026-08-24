/// ثوابت عامة عابرة للطبقات، لا تنتمي لفئة أكثر تحديداً (roles،
/// permissions، storage_keys، api_constants).
abstract final class AppConstants {
  static const String appName = 'Avahi';
  static const String appNameAr = 'أفاهي';

  /// أقصى حجم ملف مسموح برفعه (بالبايت) قبل ضغطه — 15 ميجابايت.
  static const int maxUploadFileSizeBytes = 15 * 1024 * 1024;

  /// أقصى عدد صور يمكن إرفاقها بتقرير ميداني واحد (Field Report).
  static const int maxAttachmentsPerReport = 20;

  /// نصف قطر الجغرافيا الافتراضي لتسجيل الحضور (Geofencing) بالأمتار.
  static const double defaultGeofenceRadiusMeters = 150;

  /// مهلة اعتبار الجلسة خاملة (Idle) قبل طلب إعادة تأكيد الهوية.
  static const Duration idleSessionTimeout = Duration(minutes: 30);

  /// الحد الأدنى لطول كلمة المرور.
  static const int minPasswordLength = 8;

  /// عدد أرقام رمز PIN السريع (`features/auth/`, Prompt 13).
  static const int pinLength = 6;

  /// عدد العناصر الافتراضي لكل صفحة في القوائم المُقسّمة صفحياً.
  static const int defaultPageSize = 20;

  /// امتدادات الصور المدعومة للرفع.
  static const List<String> supportedImageExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
  ];

  /// امتدادات المستندات المدعومة للرفع (وحدة `documents`، Prompt 21).
  static const List<String> supportedDocumentExtensions = <String>[
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
  ];
}
