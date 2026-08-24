import '../../../core/errors/failure.dart';
import '../../entities/task.dart';
import '../../repositories/i_task_repository.dart';

/// UseCase جلب مهام المستخدم الحالي، اختيارياً ضمن مشروع محدد.
class GetMyTasksUsecase {
  const GetMyTasksUsecase(this._repository);

  final ITaskRepository _repository;

  Future<ResultOf<List<Task>>> call({
    required String userId,
    String? projectId,
  }) {
    return _repository.getMyTasks(userId: userId, projectId: projectId);
  }
}
