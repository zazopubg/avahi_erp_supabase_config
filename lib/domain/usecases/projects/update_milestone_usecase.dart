import '../../../core/errors/failure.dart';
import '../../entities/project_milestone.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase تحديث مرحلة رئيسية قائمة (الحالة/نسبة
/// الإنجاز/التاريخ) — `project_milestones.dart`.
class UpdateMilestoneUsecase {
  const UpdateMilestoneUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<ProjectMilestone>> call(ProjectMilestone milestone) {
    return _repository.updateMilestone(milestone);
  }
}
