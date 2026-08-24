import '../../core/errors/failure.dart';
import '../entities/company.dart';

/// عقد الوصول إلى بيانات الشركة/المستأجر (`public.companies`).
abstract interface class ICompanyRepository {
  /// يجلب شركة واحدة عبر معرّفها.
  Future<ResultOf<Company>> getCompanyById(String companyId);

  /// يجلب الشركة الحالية النشطة لسياق المستخدم المسجّل دخوله.
  Future<ResultOf<Company>> getCurrentCompany();

  /// يحدّث بيانات الشركة (اسم، شعار، عنوان...)، متاح للأدوار الإدارية
  /// فقط — تُفرض هذه القاعدة عبر RLS في Supabase وليس هنا.
  Future<ResultOf<Company>> updateCompany(Company company);
}
