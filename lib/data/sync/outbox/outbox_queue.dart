import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/utils/id_generator.dart';
import '../../../core/utils/logger.dart';
import '../../local/daos/outbox_dao.dart';
import '../../local/local_database.dart';
import 'idempotency_helper.dart';

/// نوع عملية الكتابة المعلّقة — نفس دلالة عمود
/// `OutboxTable.operationType` النصي (`insert`/`update`/`delete`)، لكن
/// بصيغة Dart آمنة النوع لتفادي الاعتماد على نصوص خام عبر بقية
/// `data/sync/`.
enum OutboxOperationType { insert, update, delete }

/// واجهة عالية المستوى فوق [OutboxDao] (`data/local/daos/`، Prompt
/// 08) — نقطة الدخول *الوحيدة* التي يجب أن تعتمدها أي طبقة أعلى
/// (`data/repositories_impl/`، Prompt 10) لوضع عملية كتابة محلية في
/// طابور المزامنة، بدل التعامل المباشر مع [OutboxDao]/`OutboxTable`.
///
/// كل ما يخصّ *ترتيب* المعالجة (أولوية + FIFO) وإلغاء التكرار
/// (Idempotency) محصور هنا؛ [OutboxProcessor] (`outbox_processor.dart`)
/// مسؤول فقط عن *تنفيذ* كل عملية مسحوبة من هذا الطابور.
class OutboxQueue {
  OutboxQueue(this._dao);

  final OutboxDao _dao;

  /// يضيف عملية كتابة معلّقة جديدة للطابور.
  ///
  /// إذا زُوِّد [clientMutationId] ووُجدت عملية معلّقة سابقة بنفس
  /// المعرّف لنفس [entityType]/[entityId]، تُتجاهَل الإضافة صامتة
  /// (انظر [IdempotencyHelper.isDuplicate]) بدل تكرارها في الطابور.
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required OutboxOperationType operationType,
    required Map<String, dynamic> payload,
    String? clientMutationId,
    int priority = 0,
  }) async {
    if (clientMutationId != null) {
      final List<OutboxEntryRow> existing =
          await _dao.getByEntity(entityType, entityId);
      if (IdempotencyHelper.isDuplicate(existing, clientMutationId)) {
        AppLogger.debug(
          'OutboxQueue: تجاهل عملية مكررة (idempotent) لـ '
          '$entityType/$entityId (clientMutationId: $clientMutationId).',
        );
        return;
      }
    }

    await _dao.enqueue(
      OutboxTableCompanion.insert(
        id: IdGenerator.v4(),
        entityType: entityType,
        entityId: entityId,
        operationType: operationType.name,
        payloadJson: jsonEncode(payload),
        createdAt: DateTime.now().toUtc(),
        priority: Value<int>(priority),
        clientMutationId: Value<String?>(clientMutationId),
      ),
    );

    AppLogger.debug(
      'OutboxQueue: أُضيفت عملية ${operationType.name} على '
      '$entityType/$entityId (أولوية: $priority).',
    );
  }

  /// العمليات المعلّقة مرتّبة حسب الأولوية ثم الأقدم أولاً (FIFO ضمن
  /// نفس الأولوية) — انظر ترتيب `OutboxDao.getPending`.
  Future<List<OutboxEntryRow>> pending({int? limit}) =>
      _dao.getPending(limit: limit);

  /// بثّ حي بعدد العمليات المعلّقة — لعرض شارة "غير متزامن" في واجهة
  /// المستخدم (`ui/widgets/common/`، خطوات لاحقة).
  Stream<int> watchPendingCount() => _dao.watchPendingCount();

  /// يزيل عملية من الطابور بعد نجاح إرسالها (أو بعد حلّ تعارضها
  /// نهائياً — انظر `conflict/`).
  Future<void> remove(String id) => _dao.remove(id);

  /// يسجّل محاولة فاشلة (يزيد `retryCount` ويحفظ [error]) — يستدعيها
  /// [OutboxProcessor] عند كل فشل إرسال، قبل تطبيق `retry/` policy.
  Future<void> recordFailure(String id, String error) =>
      _dao.recordFailedAttempt(id, error);

  Future<void> clearAll() => _dao.clearAll();
}
