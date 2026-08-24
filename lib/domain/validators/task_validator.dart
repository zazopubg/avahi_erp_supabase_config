import '../../core/errors/failure.dart';
import '../enums/task_status.dart';

/// تحقّقات نطاق `tasks/`، أهمها ضبط انتقالات حالة المهمة ضمن لوحة
/// Kanban (Prompt 16) بحيث لا تُنقل مهمة "منجزة" رجوعاً بغير قصد عبر
/// خلل واجهة، وضبط صحة ترتيب البطاقات.
abstract final class TaskValidator {
  /// خريطة الانتقالات المسموحة بين حالات المهمة. مهمة `done` يمكن
  /// إعادة فتحها فقط إلى `review` (تصحيح بعد الإغلاق)، ومهمة `blocked`
  /// يمكن العودة منها إلى أي حالة عمل أخرى.
  static const Map<TaskStatus, Set<TaskStatus>> _allowedTransitions =
      <TaskStatus, Set<TaskStatus>>{
    TaskStatus.todo: <TaskStatus>{TaskStatus.inProgress, TaskStatus.blocked},
    TaskStatus.inProgress: <TaskStatus>{
      TaskStatus.review,
      TaskStatus.blocked,
      TaskStatus.todo,
    },
    TaskStatus.review: <TaskStatus>{
      TaskStatus.done,
      TaskStatus.inProgress,
      TaskStatus.blocked,
    },
    TaskStatus.blocked: <TaskStatus>{
      TaskStatus.todo,
      TaskStatus.inProgress,
      TaskStatus.review,
    },
    TaskStatus.done: <TaskStatus>{TaskStatus.review},
  };

  /// يتحقق من أن الانتقال من [from] إلى [to] مسموح به.
  static ResultOf<void> validateStatusTransition({
    required TaskStatus from,
    required TaskStatus to,
  }) {
    if (from == to) return const Right<Failure, void>(null);

    final bool allowed = _allowedTransitions[from]?.contains(to) ?? false;
    if (!allowed) {
      return Left<Failure, void>(
        ValidationFailure(
          message:
              'لا يمكن نقل المهمة من "${from.dbValue}" إلى "${to.dbValue}" مباشرة.',
          code: 'task.invalid_status_transition',
        ),
      );
    }
    return const Right<Failure, void>(null);
  }

  /// يتحقق من أن ترتيب Kanban قيمة غير سالبة.
  static ResultOf<void> validateKanbanOrder(int kanbanOrder) {
    if (kanbanOrder < 0) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'ترتيب البطاقة ضمن العمود لا يمكن أن يكون سالباً.',
          code: 'task.negative_kanban_order',
        ),
      );
    }
    return const Right<Failure, void>(null);
  }
}
