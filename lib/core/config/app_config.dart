import 'env.dart';
import 'env.dev.dart';
import 'env.prod.dart';
import 'env.staging.dart';

/// نقطة الوصول الموحّدة لإعدادات التطبيق الفعّالة بحسب [Env.current].
///
/// بقية طبقات التطبيق (config/di/services...) يجب أن تعتمد فقط على
/// `AppConfig.instance` بدلاً من التحقق من البيئة يدوياً في كل مكان.
final class AppConfig {
  AppConfig._({
    required this.environment,
    required this.apiBaseLabel,
    required this.enableDebugBanner,
    required this.enableVerboseLogging,
    required this.networkTimeout,
    required this.syncInterval,
  });

  /// النسخة الفعّالة الوحيدة من الإعدادات لكامل عمر التطبيق.
  static final AppConfig instance = _resolve();

  final AppEnvironment environment;
  final String apiBaseLabel;
  final bool enableDebugBanner;
  final bool enableVerboseLogging;
  final Duration networkTimeout;
  final Duration syncInterval;

  static AppConfig _resolve() {
    switch (Env.current) {
      case AppEnvironment.staging:
        return AppConfig._(
          environment: EnvStaging.environment,
          apiBaseLabel: EnvStaging.apiBaseLabel,
          enableDebugBanner: EnvStaging.enableDebugBanner,
          enableVerboseLogging:
              EnvStaging.enableVerboseLogging || Env.verboseLogging,
          networkTimeout: EnvStaging.networkTimeout,
          syncInterval: EnvStaging.syncInterval,
        );
      case AppEnvironment.prod:
        return AppConfig._(
          environment: EnvProd.environment,
          apiBaseLabel: EnvProd.apiBaseLabel,
          enableDebugBanner: EnvProd.enableDebugBanner,
          enableVerboseLogging:
              EnvProd.enableVerboseLogging || Env.verboseLogging,
          networkTimeout: EnvProd.networkTimeout,
          syncInterval: EnvProd.syncInterval,
        );
      case AppEnvironment.dev:
        return AppConfig._(
          environment: EnvDev.environment,
          apiBaseLabel: EnvDev.apiBaseLabel,
          enableDebugBanner: EnvDev.enableDebugBanner,
          enableVerboseLogging:
              EnvDev.enableVerboseLogging || Env.verboseLogging,
          networkTimeout: EnvDev.networkTimeout,
          syncInterval: EnvDev.syncInterval,
        );
    }
  }

  bool get isDev => environment.isDev;
  bool get isStaging => environment.isStaging;
  bool get isProd => environment.isProd;

  @override
  String toString() =>
      'AppConfig(env: ${environment.name}, build: ${Env.buildLabel})';
}
