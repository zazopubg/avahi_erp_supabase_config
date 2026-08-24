import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/company.dart';
import '../../../../domain/repositories/i_company_repository.dart';
import '../../../dto/company_dto.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [ICompanyRepository] فوق جدول `public.companies` عبر Supabase.
class CompanyRepositoryImpl implements ICompanyRepository {
  CompanyRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  @override
  Future<ResultOf<Company>> getCompanyById(String companyId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableCompanies)
          .select()
          .eq('id', companyId)
          .single();
      return Right<Failure, Company>(CompanyDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Company>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Company>> getCurrentCompany() async {
    try {
      final String? userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Left<Failure, Company>(
          AuthFailure(
            message: 'يجب تسجيل الدخول أولاً.',
            code: 'auth.not_authenticated',
          ),
        );
      }

      final Map<String, dynamic>? membership = await _client
          .from(ApiConstants.tableCompanyMembers)
          .select('company_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (membership == null) {
        return const Left<Failure, Company>(
          AuthFailure(
            message: 'لا توجد عضوية شركة نشطة لهذا المستخدم.',
            code: 'auth.no_active_membership',
          ),
        );
      }

      return getCompanyById(membership['company_id'] as String);
    } catch (error, stackTrace) {
      return Left<Failure, Company>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Company>> updateCompany(Company company) async {
    try {
      // ⚠️ الفرض الفعلي لقيد "أدوار إدارية فقط" يتم عبر سياسة RLS
      // `companies_update` وليس هنا (يُترجَم رفض السياسة إلى
      // PermissionException عبر SupabaseErrorMapper عند حدوثه).
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableCompanies)
          .update(CompanyDto.fromEntity(company).toInsertJson())
          .eq('id', company.id)
          .select()
          .single();
      return Right<Failure, Company>(CompanyDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Company>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
