import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/auth_exception.dart';
import '../../../core/errors/network_exception.dart';
import '../../../core/errors/permission_exception.dart';

/// يحوّل أي استثناء صادر عن `supabase_flutter` (PostgREST/Auth/Storage/
/// Functions أو شبكي عام) إلى [AppException] من `core/errors/` موحّد،
/// بحيث لا تتسرّب أنواع استثناءات مكتبة Supabase خارج طبقة `data/`.
///
/// يُستخدم من كل `*_repository_impl.dart` عند نقطة `catch` الوحيدة قبل
/// إرجاع [Failure] عبر `Failure.fromException` (انظر
/// `core/errors/failure.dart`، Prompt 02).
abstract final class SupabaseErrorMapper {
  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is sb.AuthException) return _mapAuth(error, stackTrace);
    if (error is sb.PostgrestException) {
      return _mapPostgrest(error, stackTrace);
    }
    if (error is sb.StorageException) return _mapStorage(error, stackTrace);
    if (error is sb.FunctionException) {
      return _mapFunction(error, stackTrace);
    }

    return UnexpectedAppException(cause: error, stackTrace: stackTrace);
  }

  static AppException _mapAuth(sb.AuthException error, StackTrace? st) {
    final String code = error.code ?? '';
    if (code == 'invalid_credentials' ||
        error.message.toLowerCase().contains('invalid login')) {
      return AuthException.invalidCredentials(cause: error, st: st);
    }
    if (code == 'session_not_found' || code == 'refresh_token_not_found') {
      return AuthException.sessionExpired(cause: error, st: st);
    }
    if (code == 'user_banned') {
      return AuthException.accountDisabled(cause: error, st: st);
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        code == 'anonymous_provider_disabled') {
      return AuthException.emailAlreadyInUse(cause: error, st: st);
    }
    return AuthException(
      message: error.message,
      code: 'auth.${code.isEmpty ? 'unknown' : code}',
      cause: error,
      stackTrace: st,
    );
  }

  static AppException _mapPostgrest(sb.PostgrestException error, StackTrace? st) {
    // ── سياسات RLS: PostgREST يعيد 42501 (insufficient_privilege) أو
    // رسالة "row-level security" عند رفض السياسة للعملية. ─────────
    if (error.code == '42501' ||
        error.message.toLowerCase().contains('row-level security') ||
        error.message.toLowerCase().contains('permission denied')) {
      return PermissionException.deniedByPolicy(cause: error, st: st);
    }

    // ── قيد تفرّد (Unique Constraint)، مثال:
    // attendance_client_mutation_id_unique — لا يُعامَل كخطأ فادح؛
    // على الطبقة المستدعية (attendance) التعامل معه بإعادة الجلب. ──
    if (error.code == '23505') {
      return NetworkException(
        message: 'هذا السجل موجود مسبقاً (تعارض تفرّد).',
        code: 'postgrest.unique_violation',
        cause: error,
        stackTrace: st,
      );
    }

    // ── قيد مرجعي (Foreign Key) مفقود ──────────────────────────────
    if (error.code == '23503') {
      return NetworkException(
        message: 'مرجع بيانات غير موجود (Foreign Key).',
        code: 'postgrest.foreign_key_violation',
        cause: error,
        stackTrace: st,
      );
    }

    // ── قيد CHECK (قيمة enum غير صالحة مثلاً) ──────────────────────
    if (error.code == '23514') {
      return NetworkException(
        message: 'قيمة غير صالحة لحقل مقيّد (CHECK constraint).',
        code: 'postgrest.check_violation',
        cause: error,
        stackTrace: st,
      );
    }

    return NetworkException.serverError(
      statusCode: int.tryParse(error.code ?? '') ?? 500,
      message: error.message,
      cause: error,
      st: st,
    );
  }

  static AppException _mapStorage(sb.StorageException error, StackTrace? st) {
    if (error.statusCode == '403') {
      return PermissionException.deniedByPolicy(cause: error, st: st);
    }
    return NetworkException.serverError(
      statusCode: int.tryParse(error.statusCode ?? '') ?? 500,
      message: error.message,
      cause: error,
      st: st,
    );
  }

  static AppException _mapFunction(sb.FunctionException error, StackTrace? st) {
    if (error.status == 401) {
      return AuthException.notAuthenticated(cause: error, st: st);
    }
    if (error.status == 403) {
      return PermissionException.denied(cause: error, st: st);
    }
    final Object? details = error.details;
    final String message = details is Map && details['error'] is Map
        ? (details['error']['message']?.toString() ?? error.toString())
        : error.toString();
    return NetworkException.serverError(
      statusCode: error.status,
      message: message,
      cause: error,
      st: st,
    );
  }
}
