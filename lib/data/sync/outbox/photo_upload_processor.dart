import 'dart:typed_data';

import '../../../core/errors/failure.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/site_photo.dart';
import '../../../domain/enums/related_entity_type.dart';
import '../../../domain/repositories/i_photo_repository.dart';
import '../../local/daos/photo_dao.dart';
import '../../local/local_database.dart' show PhotoQueueRow;
import '../../storage/photo_storage_service.dart';
import '../retry/retry_policy.dart';

/// نتيجة معالجة صف طابور صور واحد.
enum PhotoUploadOutcome {
  /// رُفعت الصورة (+المصغّرة إن وُجدت) بنجاح وأُدرج صفها في
  /// `public.photos` — أُزيلت من `local_photo_queue` فعلياً (`markUploaded`
  /// يُبقي الصف لكن بحالة `synced`؛ انظر تعليق [PhotoDao.markUploaded]).
  uploaded,

  /// فشل عابر — سيُعاد المحاولة لاحقاً بحسب [RetryPolicy].
  retryScheduled,

  /// فشل دائم (مصادقة/صلاحيات/تحقق) — الصف باقٍ في الطابور بمعدل
  /// إعادة محاولة بطيء جداً (سقف [ExponentialBackoff]).
  permanentFailure,
}

class PhotoUploadResult {
  const PhotoUploadResult({
    required this.row,
    required this.outcome,
    this.failure,
  });

  final PhotoQueueRow row;
  final PhotoUploadOutcome outcome;
  final Failure? failure;

  bool get isSuccess => outcome == PhotoUploadOutcome.uploaded;
}

/// معالج مخصص لطابور رفع الصور (`local_photo_queue`، `PhotoDao`) —
/// نظير [OutboxProcessor] (`outbox_processor.dart`) لكن لكيان ثنائي
/// (بايتات صورة + مصغّرة) وليس صف JSON عام، ولذلك لا يعتمد إطلاقاً
/// على [OutboxRemoteWriter]/[ConflictResolver] العامَّين — لا معنى
/// لـ"تعارض" على رفع صورة جديدة بالكامل (لا تُعدَّل الصور بعد رفعها،
/// فقط تُرفَع أو تُحذَف)، فقط نجاح أو فشل الرفع نفسه.
///
/// يُشغَّل من [SyncEngine] بأولوية أقل صراحة من الطابور العام
/// (`OutboxProcessor`، الذي يخدم الحضور/التقارير الميدانية/المهام) —
/// انظر توثيق القرار الكامل حول هذه الأولوية في `sync_engine.dart`
/// (Prompt 18، `_syncPhotosInBackground`).
class PhotoUploadProcessor {
  PhotoUploadProcessor({
    required PhotoDao photoDao,
    required PhotoStorageService photoStorageService,
    required IPhotoRepository photoRepository,
  })  : _photoDao = photoDao,
        _photoStorageService = photoStorageService,
        _photoRepository = photoRepository;

  final PhotoDao _photoDao;
  final PhotoStorageService _photoStorageService;
  final IPhotoRepository _photoRepository;

  /// المشروع الافتراضي لصور غير مرتبطة بمشروع محدد (نادر عملياً —
  /// كل شاشات `features/photos/` اليوم تعمل ضمن "المشروع الحالي"
  /// دوماً، بنفس نمط `AttendanceCubit`/`TasksCubit`) — تفادياً لكسر
  /// `StoragePathBuilder.photoPath` الذي يتطلب `projectId` غير فارغ.
  static const String _fallbackProjectId = 'general';

  /// يعالج دفعة محدودة من الصفوف "المستحقة فعلياً" لإعادة المحاولة
  /// (بنفس منطق [RetryPolicy.isDueForRetry] المعتمد أصلاً في
  /// `OutboxProcessor.processPending`) — [limit] الافتراضي صغير عمداً
  /// (3) لإبقاء رفع الصور في الخلفية الحقيقية دون منافسة عمليات
  /// المزامنة الحرجة على عرض النطاق الترددي لموقع عمل ضعيف التغطية.
  Future<List<PhotoUploadResult>> processPending({int limit = 3}) async {
    final List<PhotoQueueRow> rows = await _photoDao.getPendingUploads();
    final DateTime now = DateTime.now().toUtc();

    final List<PhotoUploadResult> results = <PhotoUploadResult>[];
    for (final PhotoQueueRow row in rows) {
      if (results.length >= limit) break;

      final bool due = RetryPolicy.isDueForRetry(
        retryCount: row.uploadAttempts,
        lastAttemptAt: row.lastAttemptAt,
        now: now,
      );
      if (!due) continue;

      results.add(await processRow(row));
    }
    return results;
  }

  /// يعالج صفاً واحداً بمعزل عن البقية — تُستخدم أيضاً لإعادة معالجة
  /// صف بعينه يدوياً (زر "إعادة المحاولة" على صورة فشل رفعها نهائياً
  /// في `upload_progress_indicator.dart`).
  Future<PhotoUploadResult> processRow(PhotoQueueRow row) async {
    final String projectId = row.projectId ?? _fallbackProjectId;

    final ResultOf<String> uploadResult = await _photoStorageService.uploadPhoto(
      bytes: Uint8List.fromList(row.localFileBytes),
      companyId: row.companyId,
      projectId: projectId,
      relatedEntityId: row.relatedEntityId,
      originalFileName: row.localFilePath,
      contentType: row.mimeType,
    );

    final String? remoteStoragePath = uploadResult.getOrNull();
    if (remoteStoragePath == null) {
      return _handleFailure(row, uploadResult);
    }

    // رفع المصغّرة اختياري تماماً — فشلها لا يُفشل رفع الصورة الأصل
    // نفسها (يبقى `thumbnailStoragePath` فارغاً، والعرض يتراجع
    // لاستخدام الصورة الأصل نفسها كمصغّرة، انظر `photo_thumbnail.dart`).
    String? thumbnailStoragePath;
    final List<int>? localThumbnailBytes = row.localThumbnailBytes;
    if (localThumbnailBytes != null && localThumbnailBytes.isNotEmpty) {
      final ResultOf<String> thumbUpload = await _photoStorageService.uploadThumbnail(
        bytes: Uint8List.fromList(localThumbnailBytes),
        originalStoragePath: remoteStoragePath,
        contentType: row.mimeType,
      );
      thumbnailStoragePath = thumbUpload.getOrNull();
    }

    final SitePhoto photo = SitePhoto(
      id: row.id,
      companyId: row.companyId,
      projectId: row.projectId,
      relatedEntityType: RelatedEntityType.fromDbValue(row.relatedEntityType),
      relatedEntityId: row.relatedEntityId,
      storagePath: remoteStoragePath,
      thumbnailPath: thumbnailStoragePath,
      caption: row.caption,
      fileSizeBytes: row.fileSizeBytes,
      takenAt: row.takenAt,
      latitude: row.latitude,
      longitude: row.longitude,
      uploadedBy: row.uploadedBy,
      createdAt: row.createdAt,
    );

    final ResultOf<SitePhoto> saveResult = await _photoRepository.uploadPhoto(photo);
    if (saveResult.getOrNull() == null) {
      return _handleFailure(row, saveResult);
    }

    await _photoDao.markUploaded(
      row.id,
      remoteStoragePath: remoteStoragePath,
      thumbnailStoragePath: thumbnailStoragePath,
    );

    AppLogger.info('PhotoUploadProcessor: رُفعت صورة ${row.id} بنجاح.');
    return PhotoUploadResult(row: row, outcome: PhotoUploadOutcome.uploaded);
  }

  Future<PhotoUploadResult> _handleFailure<T>(
    PhotoQueueRow row,
    ResultOf<T> failedResult,
  ) async {
    final Failure failure = failedResult.fold(
      (Failure f) => f,
      (_) => const UnknownFailure(
        message: 'فشل غير متوقع أثناء رفع الصورة.',
        code: 'photos.upload_unknown',
      ),
    );

    final RetryDecision decision = RetryPolicy.classify(failure, row.uploadAttempts);
    await _photoDao.recordFailedAttempt(row.id, failure.message);

    AppLogger.error(
      'PhotoUploadProcessor: فشل رفع صورة ${row.id} '
      '(محاولة رقم ${row.uploadAttempts + 1}, ${decision.verdict.name}).',
      error: failure,
    );

    return PhotoUploadResult(
      row: row,
      outcome: decision.isPermanent
          ? PhotoUploadOutcome.permanentFailure
          : PhotoUploadOutcome.retryScheduled,
      failure: failure,
    );
  }
}
