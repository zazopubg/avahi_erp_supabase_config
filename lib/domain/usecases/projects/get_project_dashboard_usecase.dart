import '../../../core/errors/failure.dart';
import '../../repositories/i_project_repository.dart';

/// UseCase جلب بيانات لوحة تحكّم مشروع مجمّعة (Prompt 20).
class GetProjectDashboardUsecase {
  const GetProjectDashboardUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<Map<String, num>>> call(String projectId) {
    return _repository.getProjectDashboard(projectId);
  }
}
