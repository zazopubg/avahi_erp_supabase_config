import '../../../core/errors/failure.dart';
import '../../entities/task.dart';
import '../../repositories/i_task_repository.dart';

/// UseCase جلب كل مهام مشروع محدد (Prompt 16) — يُستخدم لتغذية لوحة
/// Kanban الكاملة (`tasks_board_screen.dart`) وجدول المهام على سطح
/// المكتب (`tasks_list_screen.dart`)، بخلاف [GetMyTasksUsecase] الذي
/// يقتصر على مهام المستخدم الحالي فقط.
class GetProjectTasksUsecase {
  const GetProjectTasksUsecase(this._repository);

  final ITaskRepository _repository;

  Future<ResultOf<List<Task>>> call(String projectId) {
    return _repository.getProjectTasks(projectId);
  }
}
