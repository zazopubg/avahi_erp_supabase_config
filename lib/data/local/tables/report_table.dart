import 'package:drift/drift.dart';

/// جدول محلي (Drift) مطابق لبنية `public.field_reports` (انظر
/// `backend/supabase/migrations/007_create_field_reports.sql`)، لدعم
/// تعبئة التقرير الميداني اليومي (Prompt 17) دون اتصال، بما فيه
/// التوقيعان الرقميان (مشرف/عميل) وحقول الطقس التي تُملأ تلقائياً
/// لاحقاً عند توفر الاتصال.
///
/// ملاحظة: [supervisorSignatureUrl]/[clientSignatureUrl] يحفظان محلياً
/// **مسار ملف الجهاز المؤقت** (قبل الرفع) وليس رابط Supabase Storage
/// النهائي؛ يستبدله `data/sync/` بالمسار السحابي الفعلي بعد نجاح
/// الرفع إلى Bucket `signatures`.
@DataClassName('ReportRow')
class ReportTable extends Table {
  @override
  String get tableName => 'local_field_reports';

  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get projectId => text()();
  TextColumn get createdBy => text().nullable()();

  DateTimeColumn get reportDate => dateTime()();

  /// قيمة [ReportStatus.dbValue] النصية.
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// قيمة [WeatherCondition.dbValue] النصية، اختياري.
  TextColumn get weatherCondition => text().nullable()();
  RealColumn get temperatureC => real().nullable()();

  IntColumn get laborCount => integer().withDefault(const Constant(0))();
  TextColumn get workPerformed => text().nullable()();
  TextColumn get materialsUsed => text().nullable()();
  TextColumn get equipmentUsed => text().nullable()();
  TextColumn get issues => text().nullable()();
  TextColumn get notes => text().nullable()();

  TextColumn get supervisorSignatureUrl => text().nullable()();
  DateTimeColumn get supervisorSignedAt => dateTime().nullable()();
  TextColumn get clientSignatureUrl => text().nullable()();
  DateTimeColumn get clientSignedAt => dateTime().nullable()();

  TextColumn get reviewedBy => text().nullable()();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  TextColumn get rejectionReason => text().nullable()();

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
