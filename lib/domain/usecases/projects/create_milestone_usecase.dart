import '../../../core/errors/failure.dart';
import '../../entities/project_milestone.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase إنشاء مرحلة رئيسية جديدة — `project_milestones.dart`.
class CreateMilestoneUsecase {
  const CreateMilestoneUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<ProjectMilestone>> call(ProjectMilestone milestone) {
    return _repository.createMilestone(milestone);
  }
}
