import '../../../core/errors/failure.dart';
import '../../entities/task.dart';
import '../../repositories/i_task_repository.dart';

/// UseCase إسناد مهمة إلى مستخدم (أو إلغاء إسنادها).
class AssignTaskUsecase {
  const AssignTaskUsecase(this._repository);

  final ITaskRepository _repository;

  Future<ResultOf<Task>> call({
    required String taskId,
    String? assigneeId,
  }) {
    return _repository.assignTask(taskId: taskId, assigneeId: assigneeId);
  }
}
