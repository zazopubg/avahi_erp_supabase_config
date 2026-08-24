import '../../../core/errors/failure.dart';
import '../../entities/project_milestone.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase جلب مراحل مشروع محدد — `project_milestones.dart`/
/// `project_overview.dart`.
class GetProjectMilestonesUsecase {
  const GetProjectMilestonesUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<List<ProjectMilestone>>> call(String projectId) {
    return _repository.getProjectMilestones(projectId);
  }
}
