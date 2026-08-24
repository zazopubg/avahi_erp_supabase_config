import 'package:drift/drift.dart';

import '../local_database.dart';
import '../tables/outbox_table.dart';

part 'outbox_dao.g.dart';

/// عمليات الوصول لجدول [OutboxTable] المحلي (`local_outbox`) — قلب
/// استراتيجية Offline-first القادمة في `data/sync/` (Prompt 09).
@DriftAccessor(tables: <Type>[OutboxTable])
class OutboxDao extends DatabaseAccessor<LocalDatabase>
    with _$OutboxDaoMixin {
  OutboxDao(super.db);

  Future<void> enqueue(OutboxTableCompanion entry) {
    return into(outboxTable).insert(entry);
  }

  /// كل العمليات المعلّقة، مرتّبة حسب الأولوية (الأعلى أولاً) ثم وقت
  /// الإنشاء (الأقدم أولاً) — ترتيب المعالجة الذي سيتبعه منفّذ
  /// المزامنة (`data/sync/strategies/`).
  Future<List<OutboxEntryRow>> getPending({int? limit}) {
    final SimpleSelectStatement<$OutboxTableTable, OutboxEntryRow> query =
        select(outboxTable)
          ..orderBy(<OrderingTerm Function(OutboxTable)>[
            (OutboxTable t) =>
                OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
            (OutboxTable t) => OrderingTerm(expression: t.createdAt),
          ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query.get();
  }

  /// بث حي لعدد العمليات المعلّقة في الطابور — لعرض شارة "غير متزامن"
  /// في واجهة المستخدم.
  Stream<int> watchPendingCount() {
    final Expression<int> countExp = outboxTable.id.count();
    return (selectOnly(outboxTable)
          ..addColumns(<Expression<Object>>[countExp]))
        .map((TypedResult row) => row.read(countExp) ?? 0)
        .watchSingle();
  }

  Future<List<OutboxEntryRow>> getByEntity(
    String entityType,
    String entityId,
  ) {
    return (select(outboxTable)
          ..where(
            (OutboxTable t) =>
                t.entityType.equals(entityType) & t.entityId.equals(entityId),
          ))
        .get();
  }

  /// يزيد عداد المحاولات ويسجّل سبب آخر فشل — تستدعيها سياسة
  /// `data/sync/retry/` بعد كل محاولة إرسال فاشلة.
  Future<void> recordFailedAttempt(String id, String error) async {
    final OutboxEntryRow? row = await (select(outboxTable)
          ..where((OutboxTable t) => t.id.equals(id)))
        .getSingleOrNull();
    final int nextRetry = (row?.retryCount ?? 0) + 1;

    await (update(outboxTable)..where((OutboxTable t) => t.id.equals(id)))
        .write(
      OutboxTableCompanion(
        retryCount: Value<int>(nextRetry),
        lastError: Value<String?>(error),
        lastAttemptAt: Value<DateTime?>(DateTime.now().toUtc()),
      ),
    );
  }

  /// يزيل صف الطابور بعد نجاح إرساله للسحابة.
  Future<void> remove(String id) {
    return (delete(outboxTable)..where((OutboxTable t) => t.id.equals(id)))
        .go();
  }

  Future<void> clearAll() {
    return delete(outboxTable).go();
  }
}
