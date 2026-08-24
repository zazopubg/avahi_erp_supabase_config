import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/repositories/i_auth_repository.dart';
import '../../../dto/app_user_dto.dart';
import '../supabase_auth_service.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IAuthRepository] فوق [SupabaseAuthService] (دورة حياة
/// الجلسة) + جدول `public.company_members` (بناء [AppUser] الكامل).
///
/// ⚠️ حالة تعدد العضويات: [login]/[getCurrentUser] تستخدمان أول عضوية
/// نشطة تُعيدها قاعدة البيانات (`limit(1)`) دون ترتيب مضمون، كقيمة
/// افتراضية سريعة. الحسم الفعلي لاختيار الشركة عند تعدد العضويات هو
/// مسؤولية `features/auth/` (Prompt 13) عبر [getUserMemberships] أدناه
/// (تجلب كل العضويات دون حدّ)، وليس من مسؤولية هذه الطبقة.
class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl({sb.SupabaseClient? client, AuthService? authService})
      : _client = client ?? SupabaseClientProvider.client,
        _authService = authService ?? SupabaseAuthService(client: client);

  final sb.SupabaseClient _client;
  final AuthService _authService;

  @override
  Future<ResultOf<AppUser>> login({
    required String email,
    required String password,
  }) async {
    final ResultOf<AuthSessionInfo> sessionResult =
        await _authService.signInWithPassword(email: email, password: password);

    return sessionResult.fold(
      (Failure failure) => Left<Failure, AppUser>(failure),
      (AuthSessionInfo session) => _fetchActiveMembership(session.userId),
    );
  }

  @override
  Future<ResultOf<void>> logout() => _authService.signOut();

  @override
  Future<ResultOf<AppUser?>> getCurrentUser() async {
    final AuthSessionInfo? session = _authService.currentSession;
    if (session == null) return const Right<Failure, AppUser?>(null);

    final ResultOf<AppUser> result = await _fetchActiveMembership(session.userId);
    return result.fold(
      (Failure failure) => Left<Failure, AppUser?>(failure),
      (AppUser user) => Right<Failure, AppUser?>(user),
    );
  }

  @override
  Stream<AppUser?> watchAuthState() {
    return _authService.sessionChanges.asyncMap((AuthSessionInfo? session) async {
      if (session == null) return null;
      final ResultOf<AppUser> result = await _fetchActiveMembership(session.userId);
      return result.fold((_) => null, (AppUser user) => user);
    });
  }

  @override
  Future<ResultOf<void>> sendPasswordResetEmail(String email) =>
      _authService.sendPasswordResetEmail(email);

  @override
  Future<ResultOf<List<AppUser>>> getUserMemberships(String userId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableCompanyMembers)
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      return Right<Failure, List<AppUser>>(
        rows
            .map((Map<String, dynamic> row) => AppUserDto.fromJson(row).toEntity())
            .toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<AppUser>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  /// يجلب أول عضوية شركة نشطة للمستخدم [userId] ويحوّلها إلى [AppUser].
  Future<ResultOf<AppUser>> _fetchActiveMembership(String userId) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from(ApiConstants.tableCompanyMembers)
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (row == null) {
        return const Left<Failure, AppUser>(
          AuthFailure(
            message: 'لا توجد عضوية شركة نشطة لهذا المستخدم.',
            code: 'auth.no_active_membership',
          ),
        );
      }

      return Right<Failure, AppUser>(AppUserDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, AppUser>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
