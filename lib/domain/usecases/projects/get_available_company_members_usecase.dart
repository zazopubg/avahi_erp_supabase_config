import '../../../core/errors/failure.dart';
import '../../entities/app_user.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase جلب أعضاء الشركة القابلين للإضافة لمشروع
/// معيّن (غير مُسندين إليه بعد) — أساس `member_role_selector.dart`.
class GetAvailableCompanyMembersUsecase {
  const GetAvailableCompanyMembersUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<List<AppUser>>> call({
    required String companyId,
    required String projectId,
  }) {
    return _repository.getAvailableCompanyMembers(
      companyId: companyId,
      projectId: projectId,
    );
  }
}
