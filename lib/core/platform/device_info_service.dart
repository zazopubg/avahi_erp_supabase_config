/// معلومات وصفية عن بيئة تشغيل التطبيق الحالية، تُستخدم للتشخيص
/// وسجلات المزامنة (Sync Logs) وتخصيص واجهة الدعم الفني.
class DeviceInfo {
  const DeviceInfo({
    required this.browserLabel,
    required this.isWeb,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  final String browserLabel;
  final bool isWeb;
  final double viewportWidth;
  final double viewportHeight;

  @override
  String toString() =>
      'DeviceInfo(browser: $browserLabel, viewport: '
      '${viewportWidth.toStringAsFixed(0)}x'
      '${viewportHeight.toStringAsFixed(0)})';
}

/// خدمة استخلاص معلومات الجهاز/المتصفح الحالي.
///
/// ⚠️ نسخة Interface بسيطة لهذه الخطوة؛ لا اعتماد فعلي بعد على حزمة
/// `package_info_plus` أو `dart:js_interop` لقراءة `navigator.userAgent`
/// — سيُستكمل ذلك عند الحاجة الفعلية في `core/services/` أو `core/di/`.
abstract class DeviceInfoService {
  Future<DeviceInfo> current();
}

/// تنفيذ افتراضي مؤقت يُعيد قيماً عامة غير دقيقة، إلى حين ربط الخدمة
/// الحقيقية بمصدر بيانات فعلي (Prompt 11 أو أثناء `core/services`).
class StubDeviceInfoService implements DeviceInfoService {
  const StubDeviceInfoService();

  @override
  Future<DeviceInfo> current() async {
    return const DeviceInfo(
      browserLabel: 'unknown-browser',
      isWeb: true,
      viewportWidth: 0,
      viewportHeight: 0,
    );
  }
}
