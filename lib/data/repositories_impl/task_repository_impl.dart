import 'package:drift/drift.dart' show Value;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/task.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/repositories/i_task_repository.dart';
import '../dto/task_dto.dart';
import '../local/daos/task_dao.dart';
import '../local/local_database.dart' show TaskRow, TaskTableCompanion;
import '../sync/outbox/idempotency_helper.dart';
import '../sync/outbox/outbox_processor.dart' show LocalSyncStateWriter;
import '../sync/outbox/outbox_queue.dart';

/// تنفيذ [ITaskRepository] الموحَّد الذي يُحقَن فعلياً في `UseCases`
/// بدءاً من هذه الخطوة. يتّبع القاعدة العامة لهذه الخطوة حرفياً: كل
/// قراءة من `data/local/` فقط (سريعة، offline)، وكل كتابة تُنفَّذ
/// محلياً أولاً (تظهر فوراً في لوحة Kanban) ثم تُضاف إلى
/// `outbox_queue` ليتولى `sync_engine` إرسالها لاحقاً دون انتظار
/// تأكيد الخادم.
///
/// لا يوجد هنا أي تفويض لـ
/// `data/cloud/supabase/repositories/task_repository_impl.dart`
/// (Prompt 07) — على عكس الحضور، لا تتضمن عمليات المهام أي منطق
/// خادمي خاص (لا Edge Functions، لا تحقق جغرافي)، فالتنفيذ السحابي
/// أصبح تفصيلاً داخلياً يُستدعى فقط من `SupabaseOutboxRemoteWriter`
/// (Prompt 09) عبر اسم الجدول العام `ApiConstants.tableTasks`.
class TaskRepositoryImpl implements ITaskRepository, LocalSyncStateWriter {
  TaskRepositoryImpl({required TaskDao dao, required OutboxQueue outboxQueue})
      : _dao = dao,
        _outbox = outboxQueue;

  final TaskDao _dao;
  final OutboxQueue _outbox;

  // ── قراءات (محلية فقط) ──────────────────────────────────────────

  @override
  Future<ResultOf<Task>> getTaskById(String taskId) async {
    final TaskRow? row = await _dao.getById(taskId);
    if (row == null) {
      return const Left<Failure, Task>(
        ValidationFailure(
          message: 'المهمة غير موجودة في الذاكرة المحلية.',
          code: 'task.not_found_locally',
        ),
      );
    }
    return Right<Failure, Task>(_rowToEntity(row));
  }

  @override
  Future<ResultOf<List<Task>>> getMyTasks({
    required String userId,
    String? projectId,
  }) async {
    final List<TaskRow> rows = await _dao.getAssignedTo(userId);
    final Iterable<TaskRow> filtered = projectId == null
        ? rows
        : rows.where((TaskRow r) => r.projectId == projectId);
    return Right<Failure, List<Task>>(
      filtered.map(_rowToEntity).toList(growable: false),
    );
  }

  @override
  Future<ResultOf<List<Task>>> getProjectTasks(String projectId) async {
    final List<TaskRow> rows = await _dao.getAllForProject(projectId);
    return Right<Failure, List<Task>>(
      rows.map(_rowToEntity).toList(growable: false),
    );
  }

  // ── كتابات (محلي أولاً، ثم outbox) ──────────────────────────────

  @override
  Future<ResultOf<Task>> createTask(Task task) async {
    await _dao.upsertTask(_toCompanion(task, syncState: SyncState.pending));
    await _outbox.enqueue(
      entityType: ApiConstants.tableTasks,
      entityId: task.id,
      operationType: OutboxOperationType.insert,
      payload: TaskDto.fromEntity(task).toJson(),
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, Task>(task);
  }

  @override
  Future<ResultOf<Task>> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    int? kanbanOrder,
  }) async {
    final TaskRow? row = await _dao.getById(taskId);
    if (row == null) return _notFound(taskId);

    final DateTime now = DateTime.now().toUtc();
    final Task updated = _rowToEntity(row).copyWith(
      status: status,
      kanbanOrder: kanbanOrder,
      completedAt: status.isDone ? now : row.completedAt,
      updatedAt: now,
    );
    await _dao.upsertTask(_toCompanion(updated, syncState: SyncState.pending));
    await _outbox.enqueue(
      entityType: ApiConstants.tableTasks,
      entityId: taskId,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': taskId,
        'status': status.dbValue,
        'kanban_order': updated.kanbanOrder,
        'completed_at': updated.completedAt?.toIso8601String(),
        'updated_at': updated.updatedAt.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, Task>(updated);
  }

  @override
  Future<ResultOf<Task>> assignTask({
    required String taskId,
    String? assigneeId,
  }) async {
    final TaskRow? row = await _dao.getById(taskId);
    if (row == null) return _notFound(taskId);

    final DateTime now = DateTime.now().toUtc();
    final Task current = _rowToEntity(row);
    final Task updated = Task(
      id: current.id,
      companyId: current.companyId,
      projectId: current.projectId,
      title: current.title,
      description: current.description,
      status: current.status,
      priority: current.priority,
      kanbanOrder: current.kanbanOrder,
      createdAt: current.createdAt,
      updatedAt: now,
      assignedTo: assigneeId,
      createdBy: current.createdBy,
      dueDate: current.dueDate,
      completedAt: current.completedAt,
    );
    await _dao.upsertTask(_toCompanion(updated, syncState: SyncState.pending));
    await _outbox.enqueue(
      entityType: ApiConstants.tableTasks,
      entityId: taskId,
      operationType: OutboxOperationType.update,
      payload: <String, dynamic>{
        'id': taskId,
        'assigned_to': assigneeId,
        'updated_at': updated.updatedAt.toIso8601String(),
      },
      clientMutationId: IdempotencyHelper.newMutationId(),
    );
    return Right<Failure, Task>(updated);
  }

  // ── LocalSyncStateWriter (تُسجَّل لدى `OutboxProcessor` عبر
  //    `core/di/` في Prompt 11 تحت مفتاح `ApiConstants.tableTasks`) ──

  @override
  Future<void> markSynced(String entityId) =>
      _dao.markSyncState(entityId, SyncState.synced.name);

  @override
  Future<void> markFailed(String entityId, String error) =>
      _dao.markSyncState(entityId, SyncState.failed.name);

  @override
  Future<void> markConflict(
    String entityId,
    Map<String, dynamic> remotePayload,
  ) =>
      _dao.markSyncState(entityId, SyncState.conflict.name);

  @override
  Future<void> overwriteWithRemote(
    String entityId,
    Map<String, dynamic> remotePayload,
  ) {
    final Task remote = TaskDto.fromJson(remotePayload).toEntity();
    return _dao.upsertTask(_toCompanion(remote, syncState: SyncState.synced));
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  Left<Failure, Task> _notFound(String taskId) {
    return const Left<Failure, Task>(
      ValidationFailure(
        message: 'المهمة غير موجودة في الذاكرة المحلية.',
        code: 'task.not_found_locally',
      ),
    );
  }

  Task _rowToEntity(TaskRow row) {
    return TaskDto.fromJson(<String, dynamic>{
      'id': row.id,
      'company_id': row.companyId,
      'project_id': row.projectId,
      'title': row.title,
      'description': row.description,
      'status': row.status,
      'priority': row.priority,
      'assigned_to': row.assignedTo,
      'created_by': row.createdBy,
      'due_date': row.dueDate?.toIso8601String(),
      'kanban_order': row.kanbanOrder,
      'completed_at': row.completedAt?.toIso8601String(),
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    }).toEntity();
  }

  TaskTableCompanion _toCompanion(Task entity, {required SyncState syncState}) {
    return TaskTableCompanion(
      id: Value<String>(entity.id),
      companyId: Value<String>(entity.companyId),
      projectId: Value<String>(entity.projectId),
      title: Value<String>(entity.title),
      description: Value<String?>(entity.description),
      status: Value<String>(entity.status.dbValue),
      priority: Value<String>(entity.priority.dbValue),
      assignedTo: Value<String?>(entity.assignedTo),
      createdBy: Value<String?>(entity.createdBy),
      dueDate: Value<DateTime?>(entity.dueDate),
      kanbanOrder: Value<int>(entity.kanbanOrder),
      completedAt: Value<DateTime?>(entity.completedAt),
      createdAt: Value<DateTime>(entity.createdAt),
      updatedAt: Value<DateTime>(entity.updatedAt),
      syncState: Value<String>(syncState.name),
    );
  }
}
