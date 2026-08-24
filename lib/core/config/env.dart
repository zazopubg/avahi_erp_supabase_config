/// أنواع بيئات التشغيل المدعومة في تطبيق Avahi.
enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  bool get isDev => this == AppEnvironment.dev;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProd => this == AppEnvironment.prod;
}

/// نقطة الوصول الموحّدة لكل قيم البيئة التي تُمرَّر عبر
/// `--dart-define` أو `--dart-define-from-file` وقت البناء/التشغيل.
///
/// ⚠️ هذا الملف لا يحتوي على أي قيم حساسة فعلية؛ القيم الافتراضية هنا
/// مخصصة فقط لتشغيل محلي (dev) عندما لا تُمرَّر أي تعريفات. لا يُسمح
/// أبداً بوضع مفاتيح إنتاجية حقيقية هنا أو في نظام التحكم بالإصدار.
abstract final class Env {
  /// البيئة الحالية، تُحدَّد عبر: --dart-define=APP_ENV=dev|staging|prod
  static AppEnvironment get current =>
      AppEnvironment.fromString(_appEnvRaw);

  static const String _appEnvRaw = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// عنوان مشروع Supabase (سيُستخدم فعلياً بدءاً من Prompt 07).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  /// المفتاح العلني (anon key) لمشروع Supabase.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// مفتاح خدمة الطقس التلقائي (يُستخدم لاحقاً في Prompt 17).
  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
  );

  /// تفعيل السجلات التفصيلية (Verbose Logging) بغض النظر عن البيئة.
  static const bool verboseLogging = bool.fromEnvironment(
    'VERBOSE_LOGGING',
  );

  /// اسم إصدار البناء المعروض في واجهات التشخيص/الدعم الفني.
  static const String buildLabel = String.fromEnvironment(
    'BUILD_LABEL',
    defaultValue: 'local',
  );

  /// تحقق سريع من اكتمال إعداد المتغيرات الحرجة (يُستخدم لاحقاً في
  /// bootstrap.dart ضمن Prompt 11 لإيقاف الإقلاع بشكل واضح عند نقص
  /// الإعداد بدلاً من فشل غامض لاحقاً).
  static bool get isConfigComplete =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
