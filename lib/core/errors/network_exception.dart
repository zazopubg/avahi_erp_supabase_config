import 'app_exception.dart';

/// استثناءات متعلقة بالشبكة والاتصال بالخادم (بغض النظر عن كون
/// الخادم Supabase أو أي API آخر — لا استيراد لأي حزمة Supabase هنا).
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    required super.code,
    super.cause,
    super.stackTrace,
    this.statusCode,
  });

  /// رمز حالة HTTP إن وُجد (null عند فشل قبل وصول أي استجابة، مثل
  /// انقطاع الاتصال الكلي).
  final int? statusCode;

  /// لا يوجد اتصال بالإنترنت إطلاقاً وقت الطلب.
  factory NetworkException.offline({Object? cause, StackTrace? st}) =>
      NetworkException(
        message: 'لا يوجد اتصال بالإنترنت حالياً.',
        code: 'network.offline',
        cause: cause,
        stackTrace: st,
      );

  /// انتهت مهلة الطلب (Timeout) دون استجابة من الخادم.
  factory NetworkException.timeout({Object? cause, StackTrace? st}) =>
      NetworkException(
        message: 'انتهت مهلة الاتصال بالخادم.',
        code: 'network.timeout',
        cause: cause,
        stackTrace: st,
      );

  /// استجابة خادم بحالة خطأ (4xx/5xx).
  factory NetworkException.serverError({
    required int statusCode,
    String? message,
    Object? cause,
    StackTrace? st,
  }) =>
      NetworkException(
        message: message ?? 'حدث خطأ من طرف الخادم.',
        code: 'network.server_error',
        statusCode: statusCode,
        cause: cause,
        stackTrace: st,
      );

  /// تعذّر تحليل استجابة الخادم (تنسيق غير متوقع).
  factory NetworkException.malformedResponse({
    Object? cause,
    StackTrace? st,
  }) =>
      NetworkException(
        message: 'تعذّر قراءة استجابة الخادم.',
        code: 'network.malformed_response',
        cause: cause,
        stackTrace: st,
      );

  bool get isOffline => code == 'network.offline';
  bool get isTimeout => code == 'network.timeout';
  bool get isServerError => code == 'network.server_error';
}
