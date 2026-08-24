import '../../../core/errors/failure.dart';
import '../../entities/project.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase جلب مشروع واحد عبر معرّفه — تُستخدم عند
/// الدخول المباشر (Deep Link) لمسار `/projects/:id` دون المرور
/// أولاً بقائمة `myProjects` المُحمَّلة مسبقاً في `ProjectsCubit`.
class GetProjectByIdUsecase {
  const GetProjectByIdUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<Project>> call(String projectId) {
    return _repository.getProjectById(projectId);
  }
}
