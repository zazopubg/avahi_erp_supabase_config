import 'env.dart';

/// قيم إعداد ثابتة (غير حساسة) خاصة ببيئة التطوير (dev)، تُستخدم كـ
/// احتياط عندما لا تُمرَّر تعريفات عبر `--dart-define-from-file`.
///
/// لا تحتوي على أي أسرار حقيقية — الغرض منها فقط توفير قيم توضيحية
/// أثناء التطوير المحلي على المتصفح.
abstract final class EnvDev {
  static const AppEnvironment environment = AppEnvironment.dev;

  static const String apiBaseLabel = 'dev';
  static const bool enableDebugBanner = true;
  static const bool enableVerboseLogging = true;
  static const Duration networkTimeout = Duration(seconds: 20);
  static const Duration syncInterval = Duration(minutes: 1);
}
