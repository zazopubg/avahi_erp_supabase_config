import '../../../core/errors/failure.dart';
import '../../entities/project_member_detail.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase جلب فريق عمل مشروع محدد — `project_members.dart`.
class GetProjectMembersUsecase {
  const GetProjectMembersUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<List<ProjectMemberDetail>>> call(String projectId) {
    return _repository.getProjectMembers(projectId);
  }
}
