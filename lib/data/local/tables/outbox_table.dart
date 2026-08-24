import 'package:drift/drift.dart';

/// جدول محلي (Drift) هو **قلب استراتيجية Offline-first القادمة**
/// (`lib/data/sync/`، Prompt 09). كل عملية كتابة (إنشاء/تعديل/حذف)
/// تحدث محلياً على أي من جداول هذه الطبقة تُسجَّل هنا كصف منفصل ينتظر
/// الإرسال إلى Supabase بالترتيب، مع دعم إعادة المحاولة والأولوية.
///
/// هذا الجدول لا يُقابله أي جدول سحابي — هو آلية داخلية بحتة على
/// الجهاز فقط، ولا تتم مزامنته هو نفسه أبداً.
@DataClassName('OutboxEntryRow')
class OutboxTable extends Table {
  @override
  String get tableName => 'local_outbox';

  /// معرّف الصف نفسه (UUID مولَّد محلياً)، مستقل عن [entityId].
  TextColumn get id => text()();

  /// اسم الكيان المستهدف، بقيم [ApiConstants] (`tasks`, `attendance`,
  /// `field_reports`, `photos`, `equipment`, `notifications`,
  /// `leave_requests`, ...).
  TextColumn get entityType => text()();

  /// معرّف السجل المتأثر (نفس `id` في الجدول المحلي المصدر، والذي
  /// سيكون أيضاً `id` الصف السحابي بعد المزامنة).
  TextColumn get entityId => text()();

  /// نوع العملية: `insert` / `update` / `delete`.
  TextColumn get operationType => text()();

  /// نسخة كاملة (JSON مُرمَّز كنص) من حمولة العملية وقت إنشائها،
  /// جاهزة للإرسال مباشرة إلى Supabase عبر `*RepositoryImpl` دون
  /// الحاجة لإعادة قراءة الجدول المحلي المصدر لاحقاً.
  TextColumn get payloadJson => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// عدد محاولات الإرسال الفاشلة حتى الآن؛ تستخدمها سياسة
  /// `data/sync/retry/` (Prompt 09) لحساب التأخير التصاعدي
  /// (Exponential Backoff) وتحديد نقطة "فشل نهائي".
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// أولوية المعالجة (رقم أكبر = أولوية أعلى)؛ تُستخدم مثلاً لإعطاء
  /// أولوية لعمليات الحضور على عمليات أقل حساسية زمنياً كالمهام.
  IntColumn get priority => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  /// نسخة من `clientMutationId` الخاص بالسجل المصدر عند توفره، لتسهيل
  /// عمليات إلغاء التكرار (Deduplication) دون فك ترميز [payloadJson].
  TextColumn get clientMutationId => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
