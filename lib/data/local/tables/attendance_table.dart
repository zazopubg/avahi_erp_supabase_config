import 'package:drift/drift.dart';

/// جدول محلي (Drift) مطابق لبنية `public.attendance` (انظر
/// `backend/supabase/migrations/006_create_attendance.sql`). أهم جدول
/// في هذه الطبقة عملياً: تسجيل الحضور (Prompt 15) يجب أن ينجح دائماً
/// حتى دون تغطية شبكة في الموقع الميداني، لذا كل الحقول الجغرافية
/// وطريقة التسجيل تُحفظ محلياً فوراً وتُزامَن لاحقاً عبر `data/sync/`
/// (Prompt 09).
///
/// [clientMutationId] هنا غير قابل للـ null (خلافاً لبقية الجداول)
/// لأن الحقل المقابل في الكيان السحابي [AttendanceRecord] نفسه مطلوب
/// دائماً (idempotency لمنع تكرار سجل حضور عند إعادة محاولة إرسال
/// فشلت جزئياً).
@DataClassName('AttendanceRow')
class AttendanceTable extends Table {
  @override
  String get tableName => 'local_attendance';

  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get projectId => text()();
  TextColumn get userId => text()();

  TextColumn get clientMutationId => text().unique()();

  DateTimeColumn get checkInAt => dateTime()();
  DateTimeColumn get checkOutAt => dateTime().nullable()();

  RealColumn get checkInLatitude => real().nullable()();
  RealColumn get checkInLongitude => real().nullable()();
  RealColumn get checkOutLatitude => real().nullable()();
  RealColumn get checkOutLongitude => real().nullable()();

  BoolColumn get geofenceValid =>
      boolean().withDefault(const Constant(true))();
  RealColumn get distanceMeters => real().nullable()();

  /// قيمة [CheckMethod.dbValue] النصية (`gps`/`qr`).
  TextColumn get checkMethod =>
      text().withDefault(const Constant('gps'))();
  TextColumn get qrCodeId => text().nullable()();

  /// قيمة [AttendanceType.dbValue] النصية (`pending`/`approved`/
  /// `rejected`) — حالة اعتماد السجل، وليست طريقة تسجيله.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  TextColumn get notes => text().nullable()();
  TextColumn get approvedBy => text().nullable()();
  DateTimeColumn get approvedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get syncState =>
      text().withDefault(const Constant('pending'))();

  BoolColumn get isDeletedLocally =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
