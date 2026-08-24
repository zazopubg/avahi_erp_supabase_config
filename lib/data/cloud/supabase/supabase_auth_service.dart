import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/failure.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/logger.dart';
import 'supabase_client_provider.dart';
import 'supabase_error_mapper.dart';

/// Claims الخاصة بمستخدم Supabase Auth، مُستخرجة من `app_metadata` في
/// جسم JWT (وليس فقط من استجابة تسجيل الدخول). تُحدَّث هذه الحقول
/// تلقائياً من الخادم عبر Edge Function `sync-user-claims` (انظر
/// `backend/supabase/functions/sync-user-claims/`، Prompt 04) كلما
/// تغيّرت عضوية/دور المستخدم في `company_members`.
///
/// ⚠️ تبقى `company_members` (عبر RLS) المصدر الحقيقي للصلاحية دائماً؛
/// هذه الـ Claims طبقة دفاع/تحسين أداء إضافية فقط (تفادي استعلام
/// إضافي عند كل تحقق دور)، وقد تتأخر لحظياً عن قاعدة البيانات مباشرة
/// بعد أي تعديل (حتى تُنفَّذ دالة `sync-user-claims`).
class AppJwtClaims {
  const AppJwtClaims({
    this.companyId,
    this.role,
    this.isPlatformOwner = false,
  });

  final String? companyId;
  final String? role;
  final bool isPlatformOwner;

  static const AppJwtClaims empty = AppJwtClaims();

  /// يفكّ ترميز الجزء الوسيط (Payload) من JWT (بدون التحقق من التوقيع
  /// — التحقق الفعلي بالتوقيع يتم من طرف خادم Supabase نفسه؛ هذا فك
  /// ترميز محلي فقط لقراءة الـ Claims المعروضة على العميل).
  factory AppJwtClaims.fromAccessToken(String accessToken) {
    try {
      final List<String> parts = accessToken.split('.');
      if (parts.length != 3) return AppJwtClaims.empty;

      final String normalized = base64Url.normalize(parts[1]);
      final Map<String, dynamic> payload =
          jsonDecode(utf8.decode(base64Url.decode(normalized)))
              as Map<String, dynamic>;

      final Map<String, dynamic> appMetadata =
          (payload['app_metadata'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};

      return AppJwtClaims(
        companyId: appMetadata['company_id'] as String?,
        role: appMetadata['role'] as String?,
        isPlatformOwner: appMetadata['is_platform_owner'] as bool? ?? false,
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'AppJwtClaims: تعذّر فك ترميز JWT، سيُستخدم AppJwtClaims.empty. $error',
      );
      AppLogger.debug(stackTrace.toString());
      return AppJwtClaims.empty;
    }
  }
}

/// تنفيذ [AuthService] (العقد المُعرَّف في `core/services/auth_service.dart`
/// منذ Prompt 02) فوق `supabase_flutter`. هذه الخدمة مسؤولة فقط عن
/// دورة حياة الجلسة (دخول/خروج/تغيّرات)؛ بناء [AppUser] الكامل (مع
/// `full_name`/`role`/...) من صف `company_members` هو مسؤولية
/// `AuthRepositoryImpl` (`repositories/auth_repository_impl.dart`) التي
/// تستهلك هذه الخدمة.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  sb.GoTrueClient get _auth => _client.auth;

  /// الـ Claims الحالية المستخرجة من JWT الجلسة الفعّالة، أو
  /// [AppJwtClaims.empty] إن لم توجد جلسة.
  AppJwtClaims get currentClaims {
    final String? token = _auth.currentSession?.accessToken;
    if (token == null) return AppJwtClaims.empty;
    return AppJwtClaims.fromAccessToken(token);
  }

  @override
  AuthSessionInfo? get currentSession => _toSessionInfo(_auth.currentSession);

  @override
  Stream<AuthSessionInfo?> get sessionChanges => _auth.onAuthStateChange.map(
        (sb.AuthState state) => _toSessionInfo(state.session),
      );

  @override
  Future<ResultOf<AuthSessionInfo>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final sb.AuthResponse response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final AuthSessionInfo? info = _toSessionInfo(response.session);
      if (info == null) {
        return const Left<Failure, AuthSessionInfo>(
          AuthFailure(
            message: 'فشل تسجيل الدخول: لم تُنشأ جلسة صالحة.',
            code: 'auth.no_session',
          ),
        );
      }
      return Right<Failure, AuthSessionInfo>(info);
    } catch (error, stackTrace) {
      return Left<Failure, AuthSessionInfo>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      return Left<Failure, void>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      return Left<Failure, void>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  AuthSessionInfo? _toSessionInfo(sb.Session? session) {
    if (session == null) return null;
    final AppJwtClaims claims = AppJwtClaims.fromAccessToken(session.accessToken);
    return AuthSessionInfo(
      userId: session.user.id,
      // ⚠️ قد تكون فارغة لثوانٍ معدودة بعد إنشاء حساب جديد مباشرة (قبل
      // اكتمال webhook مزامنة الـ Claims)؛ `AuthRepositoryImpl` يعتمد
      // بشكل أساسي على استعلام `company_members` وليس على هذا الحقل
      // وحده لبناء [AppUser] الكامل.
      tenantId: claims.companyId ?? '',
      roleName: claims.role ?? '',
      email: session.user.email,
    );
  }
}
