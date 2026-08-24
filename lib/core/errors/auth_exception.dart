import 'app_exception.dart';

/// استثناءات متعلقة بالمصادقة (تسجيل الدخول/الجلسة)، مستقلة عن أي
/// تفاصيل تنفيذ فعلية لموفّر المصادقة (Supabase Auth يُربط لاحقاً في
/// `data/cloud/supabase/auth/`، Prompt 07).
class AuthException extends AppException {
  const AuthException({
    required super.message,
    required super.code,
    super.cause,
    super.stackTrace,
  });

  factory AuthException.invalidCredentials({Object? cause, StackTrace? st}) =>
      AuthException(
        message: 'بيانات الدخول غير صحيحة.',
        code: 'auth.invalid_credentials',
        cause: cause,
        stackTrace: st,
      );

  factory AuthException.sessionExpired({Object? cause, StackTrace? st}) =>
      AuthException(
        message: 'انتهت صلاحية الجلسة، الرجاء تسجيل الدخول من جديد.',
        code: 'auth.session_expired',
        cause: cause,
        stackTrace: st,
      );

  factory AuthException.notAuthenticated({Object? cause, StackTrace? st}) =>
      AuthException(
        message: 'يجب تسجيل الدخول أولاً.',
        code: 'auth.not_authenticated',
        cause: cause,
        stackTrace: st,
      );

  factory AuthException.accountDisabled({Object? cause, StackTrace? st}) =>
      AuthException(
        message: 'تم تعطيل هذا الحساب، يرجى التواصل مع مدير النظام.',
        code: 'auth.account_disabled',
        cause: cause,
        stackTrace: st,
      );

  factory AuthException.emailAlreadyInUse({Object? cause, StackTrace? st}) =>
      AuthException(
        message: 'البريد الإلكتروني مستخدم مسبقاً.',
        code: 'auth.email_already_in_use',
        cause: cause,
        stackTrace: st,
      );

  bool get isSessionExpired => code == 'auth.session_expired';
  bool get isNotAuthenticated => code == 'auth.not_authenticated';
}
