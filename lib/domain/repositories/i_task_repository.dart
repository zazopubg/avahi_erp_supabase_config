import '../../core/errors/failure.dart';
import '../entities/task.dart';
import '../enums/task_status.dart';

/// عقد الوصول إلى المهام (`public.tasks`)، بما يشمل ترتيب Kanban.
abstract interface class ITaskRepository {
  /// يجلب مهمة واحدة عبر معرّفها.
  Future<ResultOf<Task>> getTaskById(String taskId);

  /// يجلب المهام المُسندة للمستخدم الحالي، اختيارياً ضمن مشروع محدد.
  Future<ResultOf<List<Task>>> getMyTasks({
    required String userId,
    String? projectId,
  });

  /// يجلب كل مهام مشروع محدد (لعرض لوحة Kanban كاملة).
  Future<ResultOf<List<Task>>> getProjectTasks(String projectId);

  /// يحدّث حالة/ترتيب مهمة ضمن لوحة Kanban.
  Future<ResultOf<Task>> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    int? kanbanOrder,
  });

  /// يُسند مهمة إلى مستخدم محدد (أو يلغي الإسناد عند `assigneeId == null`).
  Future<ResultOf<Task>> assignTask({
    required String taskId,
    String? assigneeId,
  });

  /// ينشئ مهمة جديدة.
  Future<ResultOf<Task>> createTask(Task task);
}
