import 'package:drift/drift.dart';

import '../local_database.dart';
import '../tables/task_table.dart';

part 'task_dao.g.dart';

/// عمليات الوصول لجدول [TaskTable] المحلي (`local_tasks`): قراءة/كتابة
/// أساسية إضافة إلى استعلامات مخصّصة للوحة Kanban (Prompt 16).
@DriftAccessor(tables: <Type>[TaskTable])
class TaskDao extends DatabaseAccessor<LocalDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// كل مهام مشروع معيّن، مرتّبة حسب موضع البطاقة في Kanban.
  Future<List<TaskRow>> getAllForProject(String projectId) {
    return (select(taskTable)
          ..where((TaskTable t) => t.projectId.equals(projectId))
          ..where((TaskTable t) => t.isDeletedLocally.equals(false))
          ..orderBy(<OrderingTerm Function(TaskTable)>[
            (TaskTable t) => OrderingTerm(expression: t.kanbanOrder),
          ]))
        .get();
  }

  /// بث حي (Stream) لمهام مشروع معيّن، لتحديث لوحة Kanban فورياً عند
  /// أي تعديل محلي.
  Stream<List<TaskRow>> watchAllForProject(String projectId) {
    return (select(taskTable)
          ..where((TaskTable t) => t.projectId.equals(projectId))
          ..where((TaskTable t) => t.isDeletedLocally.equals(false))
          ..orderBy(<OrderingTerm Function(TaskTable)>[
            (TaskTable t) => OrderingTerm(expression: t.kanbanOrder),
          ]))
        .watch();
  }

  /// مهام مُسندة لمستخدم معيّن عبر كل الشركة.
  Future<List<TaskRow>> getAssignedTo(String userId) {
    return (select(taskTable)
          ..where((TaskTable t) => t.assignedTo.equals(userId))
          ..where((TaskTable t) => t.isDeletedLocally.equals(false)))
        .get();
  }

  Future<TaskRow?> getById(String id) {
    return (select(taskTable)..where((TaskTable t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// كل السجلات التي تنتظر مزامنة (`syncState != synced`)، تُستهلك من
  /// `data/sync/` (Prompt 09).
  Future<List<TaskRow>> getPendingSync() {
    return (select(taskTable)
          ..where((TaskTable t) => t.syncState.equals('synced').not()))
        .get();
  }

  Future<void> upsertTask(TaskTableCompanion entry) {
    return into(taskTable).insertOnConflictUpdate(entry);
  }

  Future<void> upsertAll(List<TaskTableCompanion> entries) {
    return batch((Batch batch) {
      batch.insertAllOnConflictUpdate(taskTable, entries);
    });
  }

  /// يحدّث ترتيب Kanban لمهمة واحدة (سحب وإفلات) ويعلّمها كمعلّقة
  /// المزامنة.
  Future<void> updateKanbanOrder(
    String id, {
    required int newOrder,
    required String newStatus,
  }) {
    return (update(taskTable)..where((TaskTable t) => t.id.equals(id)))
        .write(
      TaskTableCompanion(
        kanbanOrder: Value<int>(newOrder),
        status: Value<String>(newStatus),
        syncState: const Value<String>('pending'),
        updatedAt: Value<DateTime>(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markSyncState(String id, String syncState) {
    return (update(taskTable)..where((TaskTable t) => t.id.equals(id)))
        .write(TaskTableCompanion(syncState: Value<String>(syncState)));
  }

  /// حذف ناعم محلي بانتظار مزامنة الحذف (انظر [TaskTable.isDeletedLocally]).
  Future<void> markDeletedLocally(String id) {
    return (update(taskTable)..where((TaskTable t) => t.id.equals(id)))
        .write(
      const TaskTableCompanion(
        isDeletedLocally: Value<bool>(true),
        syncState: Value<String>('pending'),
      ),
    );
  }

  /// حذف فعلي نهائي من قاعدة البيانات المحلية (بعد تأكيد المزامنة).
  Future<void> deletePermanently(String id) {
    return (delete(taskTable)..where((TaskTable t) => t.id.equals(id))).go();
  }
}
