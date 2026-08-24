import 'package:drift/drift.dart';

import '../local_database.dart';
import '../tables/equipment_table.dart';

part 'equipment_dao.g.dart';

/// عمليات الوصول لجدول [EquipmentTable] المحلي (`local_equipment`). 🆕
@DriftAccessor(tables: <Type>[EquipmentTable])
class EquipmentDao extends DatabaseAccessor<LocalDatabase>
    with _$EquipmentDaoMixin {
  EquipmentDao(super.db);

  Future<List<EquipmentRow>> getAllForCompany(String companyId) {
    return (select(equipmentTable)
          ..where((EquipmentTable t) => t.companyId.equals(companyId))
          ..where((EquipmentTable t) => t.isDeletedLocally.equals(false)))
        .get();
  }

  Stream<List<EquipmentRow>> watchAllForCompany(String companyId) {
    return (select(equipmentTable)
          ..where((EquipmentTable t) => t.companyId.equals(companyId))
          ..where((EquipmentTable t) => t.isDeletedLocally.equals(false)))
        .watch();
  }

  Future<List<EquipmentRow>> getAssignedTo(String userId) {
    return (select(equipmentTable)
          ..where((EquipmentTable t) => t.assignedTo.equals(userId))
          ..where((EquipmentTable t) => t.isDeletedLocally.equals(false)))
        .get();
  }

  /// المعدات التي يستحق موعد صيانتها القادم قبل تاريخ معيّن — لدعم
  /// تنبيهات الصيانة المحلية (تُكمّل تنبيه `equipment-alert` السحابي).
  Future<List<EquipmentRow>> getDueForMaintenanceBefore(DateTime date) {
    return (select(equipmentTable)
          ..where(
            (EquipmentTable t) =>
                t.nextMaintenanceDue.isSmallerOrEqualValue(date) &
                t.nextMaintenanceDue.isNotNull(),
          ))
        .get();
  }

  Future<EquipmentRow?> getById(String id) {
    return (select(equipmentTable)
          ..where((EquipmentTable t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<EquipmentRow>> getPendingSync() {
    return (select(equipmentTable)
          ..where((EquipmentTable t) => t.syncState.equals('synced').not()))
        .get();
  }

  Future<void> upsertEquipment(EquipmentTableCompanion entry) {
    return into(equipmentTable).insertOnConflictUpdate(entry);
  }

  Future<void> markSyncState(String id, String syncState) {
    return (update(equipmentTable)
          ..where((EquipmentTable t) => t.id.equals(id)))
        .write(EquipmentTableCompanion(syncState: Value<String>(syncState)));
  }
}
