import 'env.dart';

/// قيم إعداد ثابتة (غير حساسة) خاصة ببيئة الإنتاج (prod).
abstract final class EnvProd {
  static const AppEnvironment environment = AppEnvironment.prod;

  static const String apiBaseLabel = 'prod';
  static const bool enableDebugBanner = false;
  static const bool enableVerboseLogging = false;
  static const Duration networkTimeout = Duration(seconds: 12);
  static const Duration syncInterval = Duration(minutes: 5);
}
