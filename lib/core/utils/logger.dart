import 'dart:developer' as developer;

import '../config/app_config.dart';

/// مستويات السجلات المدعومة.
enum LogLevel { debug, info, warning, error }

/// أداة تسجيل موحّدة وخفيفة عبر التطبيق، مبنية فوق `dart:developer`
/// (متوافقة تماماً مع Chrome DevTools على الويب). تحترم [AppConfig]
/// لتفادي إغراق سجلات الإنتاج برسائل `debug` غير الضرورية.
///
/// ⚠️ لا يوجد هنا أي إرسال فعلي لخدمة تتبع أخطاء خارجية (Sentry وما
/// شابه) — يمكن إضافته لاحقاً كطبقة تنفيذ إضافية دون تغيير الواجهة.
abstract final class AppLogger {
  static const String _defaultTag = 'Avahi';

  static void debug(String message, {String tag = _defaultTag}) {
    if (!AppConfig.instance.enableVerboseLogging) return;
    _log(LogLevel.debug, message, tag: tag);
  }

  static void info(String message, {String tag = _defaultTag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void warning(String message, {String tag = _defaultTag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  static void error(
    String message, {
    String tag = _defaultTag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: '$tag/${level.name}',
      level: _severity(level),
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  static int _severity(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
