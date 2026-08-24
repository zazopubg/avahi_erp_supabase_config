import '../../../core/errors/failure.dart';
import '../../entities/task.dart';
import '../../enums/task_status.dart';
import '../../repositories/i_task_repository.dart';
import '../../validators/task_validator.dart';

/// UseCase تحديث حالة/ترتيب مهمة ضمن لوحة Kanban، بعد التحقق من صحة
/// انتقال الحالة عبر [TaskValidator].
class UpdateTaskStatusUsecase {
  const UpdateTaskStatusUsecase(this._repository);

  final ITaskRepository _repository;

  Future<ResultOf<Task>> call({
    required Task currentTask,
    required TaskStatus newStatus,
    int? kanbanOrder,
  }) async {
    final ResultOf<void> transitionCheck = TaskValidator.validateStatusTransition(
      from: currentTask.status,
      to: newStatus,
    );
    if (transitionCheck.isLeft) {
      return transitionCheck.fold(
        (Failure f) => Left<Failure, Task>(f),
        (_) => throw StateError('unreachable'),
      );
    }

    if (kanbanOrder != null) {
      final ResultOf<void> orderCheck = TaskValidator.validateKanbanOrder(kanbanOrder);
      if (orderCheck.isLeft) {
        return orderCheck.fold(
          (Failure f) => Left<Failure, Task>(f),
          (_) => throw StateError('unreachable'),
        );
      }
    }

    return _repository.updateTaskStatus(
      taskId: currentTask.id,
      status: newStatus,
      kanbanOrder: kanbanOrder,
    );
  }
}
