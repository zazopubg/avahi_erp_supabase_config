import 'env.dart';

/// قيم إعداد ثابتة (غير حساسة) خاصة ببيئة التجريب (staging).
abstract final class EnvStaging {
  static const AppEnvironment environment = AppEnvironment.staging;

  static const String apiBaseLabel = 'staging';
  static const bool enableDebugBanner = true;
  static const bool enableVerboseLogging = true;
  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration syncInterval = Duration(minutes: 3);
}
