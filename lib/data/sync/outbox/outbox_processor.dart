import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/sync_exception.dart';
import '../../../core/utils/logger.dart';
import '../../local/local_database.dart' show OutboxEntryRow;
import '../conflict/conflict_resolver.dart';
import '../conflict/last_write_wins.dart';
import '../retry/retry_policy.dart';
import 'outbox_queue.dart';
import 'outbox_remote_writer.dart';

/// نتيجة معالجة عنصر طابور واحد.
enum OutboxEntryOutcome {
  /// أُرسل بنجاح (أو حُسم تعارضه تلقائياً بنجاح) وأُزيل من الطابور.
  synced,

  /// فشل بخطأ عابر — سيُعاد المحاولة لاحقاً بحسب `RetryPolicy`.
  retryScheduled,

  /// تعارض يتطلب حلاً يدوياً — العنصر باقٍ في الطابور بحالة
  /// `SyncState.conflict`.
  conflictPending,

  /// فشل دائم (مصادقة/صلاحيات/تحقق) — العنصر باقٍ في الطابور لكن
  /// بمعدل إعادة محاولة بطيء جداً (سقف `ExponentialBackoff`).
  permanentFailure,
}

class OutboxProcessResult {
  const OutboxProcessResult({
    required this.entry,
    required this.outcome,
    this.failure,
  });

  final OutboxEntryRow entry;
  final OutboxEntryOutcome outcome;
  final Failure? failure;

  bool get isSuccess => outcome == OutboxEntryOutcome.synced;
  bool get isConflict => outcome == OutboxEntryOutcome.conflictPending;
}

/// منفذ محلي اختياري لكل نوع كيان (`entityType`)، يُحدِّث عمود
/// `SyncState` (`domain/enums/sync_state.dart`) على جدول Drift المصدر
/// نفسه بعد نتيجة المزامنة الفعلية، ويكتب النسخة السحابية محلياً عند
/// حسم تعارض لصالحها.
///
/// ⚠️ التنفيذ الفعلي لكل كيان (بحسب DAO الخاص به: `TaskDao`،
/// `AttendanceDao`...) سيُبنى في `data/repositories_impl/` (Prompt 10)
/// ويُسجَّل عبر `core/di/` (Prompt 11). [OutboxProcessor] يعمل بشكل
/// كامل ووظيفي حتى بدون أي منفّذ مسجَّل — يكتفي حينها بتحديث
/// `OutboxTable` نفسه (الطابور)، وتبقى أعمدة `syncState` على الجداول
/// المصدر كما هي حتى تُربَط لاحقاً (لا يتوقف عمل المزامنة على ذلك).
abstract class LocalSyncStateWriter {
  Future<void> markSynced(String entityId);
  Future<void> markFailed(String entityId, String error);
  Future<void> markConflict(String entityId, Map<String, dynamic> remotePayload);
  Future<void> overwriteWithRemote(String entityId, Map<String, dynamic> remotePayload);
}

/// المعالج الفعلي لعناصر [OutboxQueue] — قلب استراتيجية Offline-first:
/// يرسل كل عملية معلّقة عبر [OutboxRemoteWriter]، يحلّ أي تعارض عبر
/// [ConflictResolver] المسجَّل لنوع الكيان، ويطبّق [RetryPolicy] عند
/// الفشل. لا يعرف شيئاً عن *متى* يُستدعى (ذلك دور `strategies/`) ولا
/// عن *تنسيق* الحالة العامة للتطبيق (ذلك دور `sync_engine.dart`).
class OutboxProcessor {
  OutboxProcessor({
    required OutboxQueue queue,
    required OutboxRemoteWriter remoteWriter,
    Map<String, ConflictResolver> conflictResolvers =
        const <String, ConflictResolver>{},
    ConflictResolver defaultResolver = const LastWriteWinsResolver(),
    Map<String, LocalSyncStateWriter> localWriters =
        const <String, LocalSyncStateWriter>{},
  })  : _queue = queue,
        _remoteWriter = remoteWriter,
        _conflictResolvers = conflictResolvers,
        _defaultResolver = defaultResolver,
        _localWriters = localWriters;

  final OutboxQueue _queue;
  final OutboxRemoteWriter _remoteWriter;
  final Map<String, ConflictResolver> _conflictResolvers;
  final ConflictResolver _defaultResolver;
  final Map<String, LocalSyncStateWriter> _localWriters;

  /// يعالج كل العناصر المعلّقة *الجاهزة فعلياً* لإعادة المحاولة —
  /// تُستبعَد العناصر التي ما زالت داخل نافذة التأخير التصاعدي (انظر
  /// [RetryPolicy.isDueForRetry]) لتفادي إغراق الخادم بمحاولات متكررة
  /// بلا فائدة.
  Future<List<OutboxProcessResult>> processPending({int? limit}) async {
    final List<OutboxEntryRow> entries = await _queue.pending(limit: limit);
    final DateTime now = DateTime.now().toUtc();

    final List<OutboxProcessResult> results = <OutboxProcessResult>[];
    for (final OutboxEntryRow entry in entries) {
      final bool due = RetryPolicy.isDueForRetry(
        retryCount: entry.retryCount,
        lastAttemptAt: entry.lastAttemptAt,
        now: now,
      );
      if (!due) continue;
      results.add(await processEntry(entry));
    }
    return results;
  }

  /// يعالج عنصر طابور واحد بمعزل عن البقية — تُستخدم أيضاً لإعادة
  /// معالجة عنصر بعينه يدوياً (مثال: زر "إعادة المحاولة" في واجهة
  /// المستخدم لعنصر فشل بشكل دائم).
  Future<OutboxProcessResult> processEntry(OutboxEntryRow entry) async {
    final Map<String, dynamic> payload =
        jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final OutboxOperationType operation =
        OutboxOperationType.values.byName(entry.operationType);

    try {
      final OutboxPushResult pushResult = await _remoteWriter.push(
        entityType: entry.entityType,
        entityId: entry.entityId,
        operation: operation,
        payload: payload,
      );

      if (pushResult is OutboxPushConflict) {
        return _resolveConflict(entry, payload, pushResult.remotePayload);
      }

      await _queue.remove(entry.id);
      await _localWriters[entry.entityType]?.markSynced(entry.entityId);
      return OutboxProcessResult(
        entry: entry,
        outcome: OutboxEntryOutcome.synced,
      );
    } catch (error, stackTrace) {
      return _handleFailure(entry, error, stackTrace);
    }
  }

  Future<OutboxProcessResult> _resolveConflict(
    OutboxEntryRow entry,
    Map<String, dynamic> localPayload,
    Map<String, dynamic> remotePayload,
  ) async {
    final ConflictResolver resolver =
        _conflictResolvers[entry.entityType] ?? _defaultResolver;
    final ConflictResolution resolution = resolver.resolve(
      local: localPayload,
      remote: remotePayload,
    );

    switch (resolution.outcome) {
      case ConflictOutcome.keepLocal:
        AppLogger.info(
          'OutboxProcessor: تعارض على ${entry.entityType}/${entry.entityId} '
          '— الأولوية للنسخة المحلية (${resolver.runtimeType}).',
        );
        await _remoteWriter.forcePush(
          entityType: entry.entityType,
          payload: resolution.mergedPayload ?? localPayload,
        );
        await _queue.remove(entry.id);
        await _localWriters[entry.entityType]?.markSynced(entry.entityId);
        return OutboxProcessResult(
          entry: entry,
          outcome: OutboxEntryOutcome.synced,
        );

      case ConflictOutcome.keepRemote:
        AppLogger.info(
          'OutboxProcessor: تعارض على ${entry.entityType}/${entry.entityId} '
          '— الأولوية للنسخة السحابية (${resolver.runtimeType}).',
        );
        await _queue.remove(entry.id);
        await _localWriters[entry.entityType]
            ?.overwriteWithRemote(entry.entityId, remotePayload);
        return OutboxProcessResult(
          entry: entry,
          outcome: OutboxEntryOutcome.synced,
        );

      case ConflictOutcome.needsManual:
        final SyncException conflict = SyncException.conflict(
          entityType: entry.entityType,
          entityId: entry.entityId,
        );
        AppLogger.warning(
          'OutboxProcessor: تعارض يتطلب حلاً يدوياً على '
          '${entry.entityType}/${entry.entityId}.',
        );
        await _queue.recordFailure(entry.id, conflict.message);
        await _localWriters[entry.entityType]
            ?.markConflict(entry.entityId, remotePayload);
        return OutboxProcessResult(
          entry: entry,
          outcome: OutboxEntryOutcome.conflictPending,
          failure: Failure.fromException(conflict),
        );
    }
  }

  Future<OutboxProcessResult> _handleFailure(
    OutboxEntryRow entry,
    Object error,
    StackTrace stackTrace,
  ) async {
    final AppException appError = error is AppException
        ? error
        : UnexpectedAppException(cause: error, stackTrace: stackTrace);
    final Failure failure = Failure.fromException(appError);
    final RetryDecision decision = RetryPolicy.classify(failure, entry.retryCount);

    await _queue.recordFailure(entry.id, failure.message);
    await _localWriters[entry.entityType]
        ?.markFailed(entry.entityId, failure.message);

    AppLogger.error(
      'OutboxProcessor: فشلت مزامنة ${entry.entityType}/${entry.entityId} '
      '(محاولة رقم ${entry.retryCount + 1}, ${decision.verdict.name}).',
      error: error,
      stackTrace: stackTrace,
    );

    final OutboxEntryOutcome outcome = decision.isPermanent
        ? OutboxEntryOutcome.permanentFailure
        : OutboxEntryOutcome.retryScheduled;
    return OutboxProcessResult(entry: entry, outcome: outcome, failure: failure);
  }
}
