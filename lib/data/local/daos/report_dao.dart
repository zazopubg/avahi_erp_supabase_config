import 'package:drift/drift.dart';

import '../local_database.dart';
import '../tables/report_table.dart';

part 'report_dao.g.dart';

/// عمليات الوصول لجدول [ReportTable] المحلي (`local_field_reports`).
@DriftAccessor(tables: <Type>[ReportTable])
class ReportDao extends DatabaseAccessor<LocalDatabase>
    with _$ReportDaoMixin {
  ReportDao(super.db);

  Future<List<ReportRow>> getAllForProject(String projectId) {
    return (select(reportTable)
          ..where((ReportTable t) => t.projectId.equals(projectId))
          ..where((ReportTable t) => t.isDeletedLocally.equals(false))
          ..orderBy(<OrderingTerm Function(ReportTable)>[
            (ReportTable t) =>
                OrderingTerm(expression: t.reportDate, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Stream<List<ReportRow>> watchAllForProject(String projectId) {
    return (select(reportTable)
          ..where((ReportTable t) => t.projectId.equals(projectId))
          ..where((ReportTable t) => t.isDeletedLocally.equals(false))
          ..orderBy(<OrderingTerm Function(ReportTable)>[
            (ReportTable t) =>
                OrderingTerm(expression: t.reportDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// المسوّدات (`status = draft`) التي أنشأها مستخدم معيّن — لعرض
  /// "تقاريري غير المرسلة" في الشاشة الرئيسية.
  Future<List<ReportRow>> getDraftsForUser(String userId) {
    return (select(reportTable)
          ..where((ReportTable t) => t.createdBy.equals(userId))
          ..where((ReportTable t) => t.status.equals('draft'))
          ..where((ReportTable t) => t.isDeletedLocally.equals(false)))
        .get();
  }

  Future<ReportRow?> getById(String id) {
    return (select(reportTable)..where((ReportTable t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<ReportRow>> getPendingSync() {
    return (select(reportTable)
          ..where((ReportTable t) => t.syncState.equals('synced').not()))
        .get();
  }

  Future<void> upsertReport(ReportTableCompanion entry) {
    return into(reportTable).insertOnConflictUpdate(entry);
  }

  Future<void> markSyncState(String id, String syncState) {
    return (update(reportTable)..where((ReportTable t) => t.id.equals(id)))
        .write(ReportTableCompanion(syncState: Value<String>(syncState)));
  }

  Future<void> markDeletedLocally(String id) {
    return (update(reportTable)..where((ReportTable t) => t.id.equals(id)))
        .write(
      const ReportTableCompanion(
        isDeletedLocally: Value<bool>(true),
        syncState: Value<String>('pending'),
      ),
    );
  }
}
