import '../../../core/errors/failure.dart';
import '../../entities/app_user.dart';
import '../../repositories/i_user_repository.dart';

/// UseCase جلب **كل** أعضاء شركة معيّنة (كل الأدوار والحالات معاً) —
/// أساس `users_list.dart` (Prompt 26). 🆕
class GetCompanyMembersUsecase {
  const GetCompanyMembersUsecase(this._repository);

  final IUserRepository _repository;

  Future<ResultOf<List<AppUser>>> call(String companyId) {
    return _repository.getCompanyMembers(companyId);
  }
}
