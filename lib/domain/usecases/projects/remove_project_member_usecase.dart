import '../../../core/errors/failure.dart';
import '../../repositories/i_project_repository.dart';

/// 🆕 (Prompt 20) UseCase إزالة إسناد عضو عن مشروع — `project_members.dart`.
class RemoveProjectMemberUsecase {
  const RemoveProjectMemberUsecase(this._repository);

  final IProjectRepository _repository;

  Future<ResultOf<void>> call(String projectMemberId) {
    return _repository.removeProjectMember(projectMemberId);
  }
}
