import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../domain/repositories/i_user_repository.dart';
import '../../../dto/app_user_dto.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IUserRepository] فوق جدول `public.company_members` مباشرة
/// (قراءة/تحديث دور/تحديث حالة) + Edge Function `invite-user`
/// (إنشاء عضوية جديدة، تتطلّب `service_role`). 🆕 (Prompt 26)
///
/// ⚠️ قرار تصميم (سحابي خالص، بلا نسخة `data/repositories_impl/`
/// مدموجة محلياً): بنفس منطق `CompanyRepositoryImpl`/
/// `AuthRepositoryImpl` — إدارة أعضاء الشركة عملية إدارية (admin)
/// تفترض اتصالاً دائماً بالإنترنت أصلاً (لا معنى لدعوة/تعديل صلاحية
/// مستخدم دون اتصال)، ولا تحتاج قراءة أوفلاين متسقة كبقية بيانات
/// العمل الميداني (`attendance`/`tasks`...) — انظر تعليق
/// `data_module.dart` حول "مستودعات سحابية خالصة".
class UserRepositoryImpl implements IUserRepository {
  UserRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  @override
  Future<ResultOf<List<AppUser>>> getCompanyMembers(String companyId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableCompanyMembers)
          .select()
          .eq('company_id', companyId)
          .order('full_name');

      return Right<Failure, List<AppUser>>(
        rows
            .map(
              (Map<String, dynamic> row) => AppUserDto.fromJson(row).toEntity(),
            )
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<AppUser>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<AppUser>> updateMemberRole({
    required String membershipId,
    required UserRole role,
  }) async {
    try {
      // ⚠️ هذا الـ UPDATE نفسه هو ما يُفعِّل تلقائياً Database Webhook
      // دالة `sync-user-claims` على الخادم (مضبوط على `company_members`
      // لأحداث UPDATE) — لا استدعاء إضافي مطلوب من هنا. انظر توثيق
      // القرار الكامل في `UpdateMemberRoleUsecase`.
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableCompanyMembers)
          .update(<String, dynamic>{'role': role.name})
          .eq('id', membershipId)
          .select()
          .single();

      return Right<Failure, AppUser>(AppUserDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, AppUser>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<AppUser>> updateMemberStatus({
    required String membershipId,
    required bool isActive,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableCompanyMembers)
          .update(<String, dynamic>{'is_active': isActive})
          .eq('id', membershipId)
          .select()
          .single();

      return Right<Failure, AppUser>(AppUserDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, AppUser>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<AppUser>> inviteUser({
    required String companyId,
    required String email,
    required String fullName,
    required UserRole role,
    String? jobTitle,
    String? phone,
  }) async {
    try {
      // ⚠️ عبر Edge Function `invite-user` (`service_role`) وليس
      // إدراجاً مباشراً — إنشاء/دعوة مستخدم `auth.users` جديد غير
      // متاح مطلقاً لعميل بصلاحية `anon`/مستخدم عادي. انظر توثيق
      // القرار الكامل في `IUserRepository.inviteUser`.
      final sb.FunctionResponse response = await _client.functions.invoke(
        ApiConstants.fnInviteUser,
        body: <String, dynamic>{
          'company_id': companyId,
          'email': email,
          'full_name': fullName,
          'role': role.name,
          if (jobTitle != null) 'job_title': jobTitle,
          if (phone != null) 'phone': phone,
        },
      );
      return _parseInviteEnvelope(response);
    } catch (error, stackTrace) {
      return Left<Failure, AppUser>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  /// يفكّ استجابة `invite-user` الموحّدة
  /// (`{success, data: {membership}}`) إلى [AppUser]، أو [Failure]
  /// عند `success: false` — بنفس نمط
  /// `AttendanceRepositoryImpl._parseAttendanceEnvelope`.
  ResultOf<AppUser> _parseInviteEnvelope(sb.FunctionResponse response) {
    final Object? data = response.data;
    if (data is! Map) {
      return const Left<Failure, AppUser>(
        NetworkFailure(
          message: 'استجابة غير متوقعة من دالة دعوة المستخدم.',
          code: 'users.invalid_response',
        ),
      );
    }
    final Map<String, dynamic> envelope = data.cast<String, dynamic>();

    if (envelope['success'] != true) {
      final Map<String, dynamic>? error =
          (envelope['error'] as Map?)?.cast<String, dynamic>();
      return Left<Failure, AppUser>(
        NetworkFailure(
          message: error?['message']?.toString() ?? 'فشل إرسال الدعوة.',
          code: 'users.${error?['code'] ?? 'unknown'}',
        ),
      );
    }

    final Map<String, dynamic> payload =
        (envelope['data'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> membershipJson =
        (payload['membership'] as Map).cast<String, dynamic>();
    return Right<Failure, AppUser>(
      AppUserDto.fromJson(membershipJson).toEntity(),
    );
  }
}
