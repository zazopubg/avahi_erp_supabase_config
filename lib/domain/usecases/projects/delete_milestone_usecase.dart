import '../../../core/errors/failure.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase حذف مرحلة رئيسية نهائياً — `project_milestones.dart`.
class DeleteMilestoneUsecase {
  const DeleteMilestoneUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<void>> call(String milestoneId) {
    return _repository.deleteMilestone(milestoneId);
  }
}
