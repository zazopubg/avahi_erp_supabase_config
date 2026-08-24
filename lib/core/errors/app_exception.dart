/// الأساس المجرّد لكل استثناءات تطبيق Avahi.
///
/// ⚠️ هذا الملف (وكل هرمية `core/errors/`) لا يستورد أي شيء من
/// `domain/` أو `data/` عمداً؛ الهدف أن تبقى طبقة الأخطاء مستقلة تماماً
/// وقابلة للاستخدام من أي طبقة أخرى دون خطر دورة استيراد (Import Cycle).
///
/// كل استثناء فرعي (network/auth/permission/sync...) يجب أن يرث من
/// هذا الصف ويوفر [code] فريداً و[message] مناسباً للعرض أو التسجيل.
abstract class AppException implements Exception {
  const AppException({
    required this.message,
    required this.code,
    this.cause,
    this.stackTrace,
  });

  /// رسالة موجّهة للمطوّر/السجلات (وليست بالضرورة نصاً نهائياً يُعرض
  /// للمستخدم — واجهة العرض تتولى الترجمة/الصياغة المناسبة).
  final String message;

  /// رمز فريد قابل للفهرسة (مفيد للتحليلات، التصفية، والترجمة لاحقاً
  /// عبر `l10n`، مثال: `network.timeout`, `auth.invalid_credentials`).
  final String code;

  /// السبب الجذري الأصلي إن وُجد (استثناء آخر تم التقاطه وتغليفه).
  final Object? cause;

  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// استثناء عام لأي حالة غير متوقعة لم تُصنَّف ضمن الأنواع المتخصصة
/// الأخرى (network/auth/permission/sync). يُستخدم كملاذ أخير.
class UnexpectedAppException extends AppException {
  const UnexpectedAppException({
    super.message = 'حدث خطأ غير متوقع.',
    super.cause,
    super.stackTrace,
  }) : super(code: 'app.unexpected');
}

/// استثناء للحالات التي يفشل فيها التحقق من صحة المدخلات (Validation)
/// خارج نطاق `domain/validators` (مثال: تحقق سريع على مستوى الواجهة).
class ValidationAppException extends AppException {
  const ValidationAppException({
    required super.message,
    this.fieldErrors = const <String, String>{},
    super.cause,
    super.stackTrace,
  }) : super(code: 'app.validation');

  /// أخطاء مفصّلة لكل حقل، مفيدة لعرضها أسفل كل `AvahiTextField`.
  final Map<String, String> fieldErrors;
}

/// استثناء لحالة عدم توفر ميزة/قدرة على المنصة الحالية (مرتبط
/// بـ [core/platform/capability_service.dart]).
class UnsupportedCapabilityAppException extends AppException {
  const UnsupportedCapabilityAppException({
    required super.message,
    super.cause,
    super.stackTrace,
  }) : super(code: 'app.unsupported_capability');
}
