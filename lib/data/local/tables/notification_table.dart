import 'package:drift/drift.dart';

/// جدول محلي (Drift) مطابق لبنية `public.notifications` (انظر
/// `backend/supabase/migrations/013_create_notifications.sql` و
/// `019_extend_notification_types.sql`)، يعمل بشكل أساسي كذاكرة
/// تخزين مؤقت (Cache) للإشعارات لعرضها فوراً دون اتصال، مع دعم تبديل
/// حالة "مقروء" محلياً بانتظار المزامنة (Prompt 23). 🆕
///
/// ⚠️ لا يوجد `updated_at` في `public.notifications` السحابي، لذا لا
/// يوجد عمود مقابل هنا أيضاً — [readAt] وحده يكفي لتتبّع آخر تعديل.
@DataClassName('NotificationRow')
class NotificationTable extends Table {
  @override
  String get tableName => 'local_notifications';

  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get userId => text()();

  TextColumn get title => text()();
  TextColumn get body => text().nullable()();

  /// قيمة [NotificationType.dbValue] النصية.
  TextColumn get type => text().withDefault(const Constant('general'))();

  /// قيمة [RelatedEntityType.dbValue] النصية، اختياري.
  TextColumn get relatedEntityType => text().nullable()();
  TextColumn get relatedEntityId => text().nullable()();

  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get readAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  /// يُستخدم فقط لمزامنة تبديل حالة "مقروء" محلياً (لا يوجد إنشاء
  /// إشعارات من العميل مباشرة — تصدر دائماً من Edge Functions).
  TextColumn get clientMutationId => text().nullable().unique()();
  TextColumn get syncState =>
      text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
