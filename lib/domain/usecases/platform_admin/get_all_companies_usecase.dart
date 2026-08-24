import '../../../core/errors/failure.dart';
import '../../entities/company.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase جلب كل شركات المنصّة — يغذّي `admin_dashboard.dart`
/// و`tenants_list.dart` معاً. 🆕 (Prompt 28)
class GetAllCompaniesUsecase {
  const GetAllCompaniesUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<List<Company>>> call() {
    return _repository.getAllCompanies();
  }
}
