import '../../../core/errors/failure.dart';
import '../../entities/project_member_detail.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase إسناد عضو شركة إلى مشروع — `project_members.dart`.
class AddProjectMemberUsecase {
  const AddProjectMemberUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<ProjectMemberDetail>> call({
    required String projectId,
    required String companyId,
    required String userId,
  }) {
    return _repository.addProjectMember(
      projectId: projectId,
      companyId: companyId,
      userId: userId,
    );
  }
}
