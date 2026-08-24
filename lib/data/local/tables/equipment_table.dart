import 'package:drift/drift.dart';

/// جدول محلي (Drift) مطابق لبنية `public.equipment` (انظر
/// `backend/supabase/migrations/012_create_equipment.sql`)، لعرض قائمة
/// المعدات وتحديث حالتها/إسنادها دون اتصال (Prompt 22). 🆕
@DataClassName('EquipmentRow')
class EquipmentTable extends Table {
  @override
  String get tableName => 'local_equipment';

  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get projectId => text().nullable()();

  TextColumn get name => text()();
  TextColumn get nameAr => text().nullable()();
  TextColumn get type => text()();
  TextColumn get serialNumber => text().nullable()();

  /// قيمة [EquipmentStatus.dbValue] النصية.
  TextColumn get status =>
      text().withDefault(const Constant('available'))();
  TextColumn get assignedTo => text().nullable()();

  RealColumn get usageHours => real().withDefault(const Constant(0))();

  DateTimeColumn get purchaseDate => dateTime().nullable()();
  DateTimeColumn get lastMaintenanceDate => dateTime().nullable()();
  DateTimeColumn get nextMaintenanceDue => dateTime().nullable()();

  TextColumn get notes => text().nullable()();
  TextColumn get createdBy => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get clientMutationId => text().nullable().unique()();
  TextColumn get syncState =>
      text().withDefault(const Constant('synced'))();
  BoolColumn get isDeletedLocally =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
