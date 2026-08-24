import '../../../core/errors/failure.dart';
import '../../entities/project.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase إنشاء مشروع جديد.
class CreateProjectUsecase {
  const CreateProjectUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<Project>> call(Project project) {
    return _repository.createProject(project);
  }
}
