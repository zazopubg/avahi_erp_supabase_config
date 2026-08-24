import 'package:drift/drift.dart';

/// جدول محلي (Drift) مطابق لبنية `public.leave_requests` (انظر
/// `backend/supabase/migrations/014_create_leave_requests.sql`)، لدعم
/// تقديم طلبات الإجازة ومتابعة حالتها دون اتصال (Prompt 24). 🆕
@DataClassName('LeaveRequestRow')
class LeaveRequestTable extends Table {
  @override
  String get tableName => 'local_leave_requests';

  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get userId => text()();

  /// قيمة [LeaveType.dbValue] النصية.
  TextColumn get leaveType => text().withDefault(const Constant('other'))();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get reason => text().nullable()();

  /// قيمة [LeaveStatus.dbValue] النصية.
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get reviewedBy => text().nullable()();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  TextColumn get reviewNote => text().nullable()();

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
