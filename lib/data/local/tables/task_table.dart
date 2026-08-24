import 'package:drift/drift.dart';

/// جدول محلي (Drift) مبسّط مطابق لبنية `public.tasks` (انظر
/// `backend/supabase/migrations/005_create_tasks.sql`)، ليدعم عرض/تعديل
/// المهام ولوحة Kanban (Prompt 16) دون اتصال بالإنترنت.
///
/// يضيف على المخطط السحابي عمودين لا يقابلهما عمود في Postgres:
/// - [syncState]: حالة مزامنة السجل محلياً ([SyncState] بصيغة نصية،
///   انظر `domain/enums/sync_state.dart`).
/// - [clientMutationId]: معرّف idempotency يُولَّد عند كل إنشاء/تعديل
///   محلي غير متزامن بعد، يُستخدم للربط مع صف مطابق في [OutboxTable]
///   (Prompt 09) ولمنع تكرار الإرسال عند إعادة المحاولة.
///
/// ⚠️ هذه الطبقة مستقلة تماماً عن Supabase؛ التحويل بين هذا الصف
/// والـ DTO/Entity السحابي سيتم في `data/repositories_impl/`
/// (Prompt 10)، وليس هنا.
@DataClassName('TaskRow')
class TaskTable extends Table {
  @override
  String get tableName => 'local_tasks';

  /// نفس معرّف `tasks.id` السحابي — يُولَّد محلياً عبر `IdGenerator`
  /// عند الإنشاء دون اتصال، فيصبح هو المعرّف النهائي بعد المزامنة
  /// (لا حاجة لإعادة تخصيص معرّف من الخادم).
  TextColumn get id => text()();

  TextColumn get companyId => text()();
  TextColumn get projectId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  /// قيمة [TaskStatus.dbValue] النصية (`todo`/`in_progress`/...).
  TextColumn get status => text().withDefault(const Constant('todo'))();

  /// قيمة [TaskPriority.dbValue] النصية.
  TextColumn get priority =>
      text().withDefault(const Constant('medium'))();

  TextColumn get assignedTo => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// ترتيب البطاقة ضمن عمودها في لوحة Kanban.
  IntColumn get kanbanOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get clientMutationId => text().nullable().unique()();

  TextColumn get syncState =>
      text().withDefault(const Constant('synced'))();

  /// صحيح إن حُذف السجل محلياً وينتظر مزامنة عملية الحذف مع السحابة
  /// (Soft-delete محلي بدل حذف فعلي فوري، لضمان عدم فقدان أثر
  /// العملية إن فشل الاتصال قبل تأكيد الحذف من الخادم).
  BoolColumn get isDeletedLocally =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
