import '../../../core/errors/failure.dart';
import '../../entities/project.dart';
import '../../repositories/i_project_repository.dart';

/// UseCase جلب مشاريع المستخدم الحالي.
class GetMyProjectsUsecase {
  const GetMyProjectsUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<List<Project>>> call(String userId) {
    return _repository.getMyProjects(userId);
  }
}
