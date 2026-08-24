import '../../../core/errors/failure.dart';
import '../../entities/project.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase تحديث بيانات مشروع قائم (الإعدادات الأساسية،
/// النطاق الجغرافي، الحالة...) — `project_settings.dart`.
class UpdateProjectUsecase {
  const UpdateProjectUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<Project>> call(Project project) {
    return _repository.updateProject(project);
  }
}
