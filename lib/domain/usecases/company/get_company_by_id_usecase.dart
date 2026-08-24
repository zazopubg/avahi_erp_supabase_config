import '../../../core/errors/failure.dart';
import '../../entities/company.dart';
import '../../repositories/i_company_repository.dart';

/// UseCase جلب بيانات شركة واحدة عبر معرّفها — أول استهلاك فعلي له في
/// `features/auth/` (Prompt 13) لعرض اسم/شعار الشركة بعد تسجيل الدخول
/// وفي شاشة اختيار الشركة عند تعدد العضويات.
class GetCompanyByIdUsecase {
  const GetCompanyByIdUsecase(this._repository);

  final ICompanyRepository _repository;

  Future<ResultOf<Company>> call(String companyId) {
    return _repository.getCompanyById(companyId);
  }
}
