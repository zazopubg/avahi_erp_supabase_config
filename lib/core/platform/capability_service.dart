/// تعداد القدرات (Capabilities) التي قد يعتمد عليها التطبيق، والتي
/// يختلف توفرها الفعلي بين المتصفحات وأنظمة التشغيل المضيفة لها.
enum AppCapability {
  camera,
  gpsPreciseLocation,
  pushNotifications,
  fileSystemAccess,
  biometricAuth,
  haptics,
  qrScanning,
  digitalSignaturePad,
  backgroundSync,
}

/// خدمة تحديد القدرات المتاحة فعلياً في بيئة تشغيل الويب الحالية.
///
/// ⚠️ هذه نسخة Stub/Interface لهذه الخطوة (Prompt 02): القيم أدناه
/// تمثل توقّعات معقولة للمتصفح الحديث (Chrome) دون أي فحص فعلي وقت
/// التشغيل (مثل `navigator.permissions` عبر `dart:js_interop`)، والذي
/// سيُضاف عند ربط الخدمات الفعلية (camera_service, location_service..)
/// بمكوناتها الحقيقية في خطوات لاحقة (Prompt 15/18 وغيرها).
class CapabilityService {
  const CapabilityService();

  /// خريطة القدرات المدعومة نظرياً على الويب ضمن هذا التطبيق.
  ///
  /// `false` هنا لا تعني "غير مدعوم في أي متصفح"، بل "غير مضمون
  /// التوفر دون إذن صريح من المستخدم أو دعم مختلف بين المتصفحات"،
  /// لذا يجب دائماً التحقق الفعلي وقت الاستخدام (Best-effort).
  static const Map<AppCapability, bool> _webSupportMatrix =
      <AppCapability, bool>{
    AppCapability.camera: true,
    AppCapability.gpsPreciseLocation: true,
    AppCapability.pushNotifications: true,
    AppCapability.fileSystemAccess: false,
    AppCapability.biometricAuth: false,
    AppCapability.haptics: false,
    AppCapability.qrScanning: true,
    AppCapability.digitalSignaturePad: true,
    AppCapability.backgroundSync: false,
  };

  /// هل القدرة مدعومة نظرياً على المتصفح الحالي؟
  bool isSupported(AppCapability capability) =>
      _webSupportMatrix[capability] ?? false;

  /// قائمة كل القدرات غير المدعومة، مفيدة لعرض تنبيهات توضيحية
  /// للمستخدم (مثال: "بصمة الدخول غير متاحة على المتصفح، استخدم كلمة
  /// المرور").
  Set<AppCapability> get unsupportedCapabilities => _webSupportMatrix.entries
      .where((MapEntry<AppCapability, bool> e) => !e.value)
      .map((MapEntry<AppCapability, bool> e) => e.key)
      .toSet();

  /// يتحقق من مجموعة قدرات دفعة واحدة، ويُعيد فقط الناقصة منها.
  Set<AppCapability> missingFrom(Set<AppCapability> required) {
    return required.where((AppCapability c) => !isSupported(c)).toSet();
  }
}
