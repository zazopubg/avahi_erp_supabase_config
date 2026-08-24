import 'package:drift/drift.dart';

import '../local_database.dart';
import '../tables/photo_queue_table.dart';

part 'photo_dao.g.dart';

/// عمليات الوصول لجدول [PhotoQueueTable] المحلي (`local_photo_queue`):
/// طابور رفع الصور الملتقطة دون اتصال.
@DriftAccessor(tables: <Type>[PhotoQueueTable])
class PhotoDao extends DatabaseAccessor<LocalDatabase>
    with _$PhotoDaoMixin {
  PhotoDao(super.db);

  /// يضيف صورة جديدة إلى الطابور (`syncState = pending` افتراضياً).
  Future<void> enqueue(PhotoQueueTableCompanion entry) {
    return into(photoQueueTable).insertOnConflictUpdate(entry);
  }

  /// كل الصور التي لم تُرفَع بعد، مرتّبة حسب وقت الالتقاط (الأقدم
  /// أولاً)، جاهزة لمعالجتها ضمن `data/sync/` (`PhotoUploadProcessor`).
  /// تشمل عمداً حالتي `pending` و`failed` معاً — [PhotoUploadProcessor]
  /// نفسه هو من يقرر لاحقاً أي صف "مستحق فعلياً" لإعادة محاولة عبر
  /// `RetryPolicy.isDueForRetry(uploadAttempts, lastAttemptAt)`، بنفس
  /// فصل المسؤوليات المعتمد أصلاً بين `OutboxDao.getPending`/
  /// `OutboxProcessor.processPending`.
  Future<List<PhotoQueueRow>> getPendingUploads() {
    return (select(photoQueueTable)
          ..where((PhotoQueueTable t) => t.syncState.equals('synced').not())
          ..orderBy(<OrderingTerm Function(PhotoQueueTable)>[
            (PhotoQueueTable t) => OrderingTerm(expression: t.takenAt),
          ]))
        .get();
  }

  /// بث حي لعدد الصور المعلّقة — لعرض شارة "N صورة بانتظار الرفع" في
  /// `upload_progress_indicator.dart`.
  Stream<int> watchPendingCount() {
    final Expression<int> countExp = photoQueueTable.id.count();
    return (selectOnly(photoQueueTable)
          ..addColumns(<Expression<Object>>[countExp])
          ..where(photoQueueTable.syncState.equals('synced').not()))
        .map((TypedResult row) => row.read(countExp) ?? 0)
        .watchSingle();
  }

  /// بث حي لكل صفوف الطابور غير المرفوعة بعد (وليس العدد فقط) —
  /// `PhotosCubit` يشترك به مباشرة لعرض `UploadQueueState.items` محدَّثاً
  /// لحظياً في `upload_progress_indicator.dart` دون استطلاع (Polling)
  /// يدوي متكرر.
  Stream<List<PhotoQueueRow>> watchPendingUploads() {
    return (select(photoQueueTable)
          ..where((PhotoQueueTable t) => t.syncState.equals('synced').not())
          ..orderBy(<OrderingTerm Function(PhotoQueueTable)>[
            (PhotoQueueTable t) =>
                OrderingTerm(expression: t.takenAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<PhotoQueueRow>> getForEntity(
    String relatedEntityType,
    String relatedEntityId,
  ) {
    return (select(photoQueueTable)
          ..where(
            (PhotoQueueTable t) =>
                t.relatedEntityType.equals(relatedEntityType) &
                t.relatedEntityId.equals(relatedEntityId),
          ))
        .get();
  }

  Future<PhotoQueueRow?> getById(String id) {
    return (select(photoQueueTable)
          ..where((PhotoQueueTable t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// يعلّم صورة كمرفوعة بنجاح ويحفظ مسارها السحابي النهائي.
  Future<void> markUploaded(
    String id, {
    required String remoteStoragePath,
    String? thumbnailStoragePath,
  }) {
    return (update(photoQueueTable)
          ..where((PhotoQueueTable t) => t.id.equals(id)))
        .write(
      PhotoQueueTableCompanion(
        remoteStoragePath: Value<String?>(remoteStoragePath),
        thumbnailStoragePath: Value<String?>(thumbnailStoragePath),
        syncState: const Value<String>('synced'),
      ),
    );
  }

  /// يسجّل محاولة رفع فاشلة (يزيد [PhotoQueueTable.uploadAttempts]،
  /// يحفظ سبب الفشل، ويختم [PhotoQueueTable.lastAttemptAt] بالوقت
  /// الحالي — أساس حساب `RetryPolicy.isDueForRetry` التالي) — تُستخدم
  /// من `data/sync/outbox/photo_upload_processor.dart`.
  Future<void> recordFailedAttempt(String id, String error) async {
    final PhotoQueueRow? row = await (select(photoQueueTable)
          ..where((PhotoQueueTable t) => t.id.equals(id)))
        .getSingleOrNull();
    final int nextAttempts = (row?.uploadAttempts ?? 0) + 1;

    await (update(photoQueueTable)
          ..where((PhotoQueueTable t) => t.id.equals(id)))
        .write(
      PhotoQueueTableCompanion(
        uploadAttempts: Value<int>(nextAttempts),
        lastError: Value<String?>(error),
        lastAttemptAt: Value<DateTime?>(DateTime.now().toUtc()),
        syncState: const Value<String>('failed'),
      ),
    );
  }

  Future<void> deletePhoto(String id) {
    return (delete(photoQueueTable)
          ..where((PhotoQueueTable t) => t.id.equals(id)))
        .go();
  }
}
