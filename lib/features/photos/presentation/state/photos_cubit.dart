import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../data/local/daos/photo_dao.dart';
import '../../../../data/local/local_database.dart'
    show PhotoQueueRow, PhotoQueueTableCompanion;
import '../../../../data/sync/outbox/photo_upload_processor.dart';
import '../../../../data/sync/sync_engine.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/site_photo.dart';
import '../../../../domain/enums/related_entity_type.dart';
import '../../../../domain/repositories/i_photo_repository.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import 'photos_state.dart';
import 'upload_queue_state.dart';

/// `Cubit` ميزة `features/photos/` (Prompt 18) — يدير معاً وبالتوازي:
/// 1) [PhotosState]/[PhotosData]: تصفّح صور المشروع المرفوعة فعلياً
///    (`my_photos_screen.dart` على الجوال، `photo_gallery.dart` +
///    `photo_details_panel.dart` على سطح المكتب).
/// 2) [UploadQueueState] (كحقل ضمن [PhotosData]): طابور الالتقاط
///    المحلي — كاميرا/معرض → ضغط فوري (`ImageCompressor`) → إدراج في
///    `PhotoDao` (Outbox صور مستقل) → رفع تلقائي في الخلفية عبر
///    [SyncEngine]/[PhotoUploadProcessor] عند توفر الاتصال، بأولوية
///    أقل صراحةً من الحضور/التقارير الميدانية (انظر توثيق القرار
///    الكامل في `sync_engine.dart`).
///
/// بخلاف `ReportFormCubit.attachPhotoFromCamera` (`features/field_reports/`،
/// Prompt 17) الذي يرفع مباشرة أونلاين بلا ضغط ولا طابور (مناسب هناك
/// لأن نموذج التقرير أصلاً يفترض اتصالاً فعلياً وقت الإرسال)، تدفّق
/// الالتقاط هنا **Offline-first بالكامل** دوماً: كل صورة تُدرَج محلياً
/// أولاً بصرف النظر عن حالة الاتصال، ثم تُرفَع لاحقاً — بالضبط الفرق
/// المطلوب صراحة بين المسارين في مهمة Prompt 18.
class PhotosCubit extends Cubit<PhotosState> {
  PhotosCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required IPhotoRepository photoRepository,
    required PhotoDao photoDao,
    required CameraService cameraService,
    required ImageCompressor imageCompressor,
    required SyncEngine syncEngine,
    required PhotoUploadProcessor photoUploadProcessor,
    LocationService? locationService,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _photoRepository = photoRepository,
        _photoDao = photoDao,
        _cameraService = cameraService,
        _imageCompressor = imageCompressor,
        _syncEngine = syncEngine,
        _photoUploadProcessor = photoUploadProcessor,
        _locationService = locationService,
        super(const PhotosLoading());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final IPhotoRepository _photoRepository;
  final PhotoDao _photoDao;
  final CameraService _cameraService;
  final ImageCompressor _imageCompressor;
  final SyncEngine _syncEngine;
  final PhotoUploadProcessor _photoUploadProcessor;
  final LocationService? _locationService;

  StreamSubscription<List<PhotoQueueRow>>? _queueSubscription;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى عند دخول `my_photos_screen.dart` (الجوال) أو
  /// `photo_gallery.dart` (سطح المكتب) — يحدّد "المشروع الحالي" (نفس
  /// منطق `AttendanceCubit.loadInitial`/`TasksCubit.loadInitial`)، يجلب
  /// صوره، ويشترك ببث طابور الرفع المحلي الحي.
  ///
  /// [onlyMine]: `true` من `my_photos_screen.dart` (كل عامل يرى صوره
  /// هو فقط افتراضياً)، `false` من `photo_gallery.dart` الإداري (يرى
  /// كل صور المشروع افتراضياً، مع فلاتر إضافية اختيارية).
  Future<void> loadInitial(AppUser user, {bool onlyMine = false}) async {
    emit(const PhotosLoading());

    final ResultOf<List<Project>> projectsResult =
        await _getMyProjectsUsecase(user.userId);

    final Project? project = projectsResult.fold(
      (Failure _) => null,
      (List<Project> projects) {
        if (projects.isEmpty) return null;
        return projects.firstWhere(
          (Project p) => p.status.isActive,
          orElse: () => projects.first,
        );
      },
    );

    if (project == null) {
      emit(
        const PhotosError(
          ValidationFailure(
            message: 'لا يوجد مشروع نشط مرتبط بحسابك لعرض صوره.',
            code: 'photos.no_project',
          ),
        ),
      );
      return;
    }

    final List<SitePhoto> photos = await _fetchPhotos(
      projectId: project.id,
      onlyMine: onlyMine ? user.userId : null,
    );

    emit(
      PhotosLoaded(
        PhotosData(
          currentUser: user,
          project: project,
          uploadQueue: UploadQueueState.empty,
          photos: photos,
          filterUploadedByMeOnly: onlyMine,
        ),
      ),
    );

    await _queueSubscription?.cancel();
    _queueSubscription = _photoDao.watchPendingUploads().listen(_onQueueChanged);
  }

  Future<List<SitePhoto>> _fetchPhotos({
    required String projectId,
    RelatedEntityType? relatedEntityType,
    String? onlyMine,
  }) async {
    final ResultOf<List<SitePhoto>> result = await _photoRepository.getPhotosForProject(
      projectId: projectId,
      relatedEntityType: relatedEntityType,
      uploadedBy: onlyMine,
    );
    return result.fold((Failure _) => const <SitePhoto>[], (List<SitePhoto> p) => p);
  }

  void _onQueueChanged(List<PhotoQueueRow> rows) {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return;

    final UploadQueueState updated = UploadQueueState(
      items: rows.map((PhotoQueueRow r) => UploadQueueItem.fromRow(r)).toList(),
    );
    emit(PhotosLoaded(current.data.copyWith(uploadQueue: updated)));
  }

  /// يُعاد تحميل الصور فقط (بدون إعادة تحديد المشروع) — سحب للتحديث
  /// (Pull-to-refresh) في `my_photos_screen.dart`/`photo_gallery.dart`.
  Future<void> refresh() async {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return;

    emit(PhotosLoaded(current.data.copyWith(isRefreshing: true)));
    final List<SitePhoto> photos = await _fetchPhotos(
      projectId: current.data.project.id,
      relatedEntityType: current.data.filterEntityType,
      onlyMine: current.data.filterUploadedByMeOnly ? current.data.currentUser.userId : null,
    );
    final PhotosState latest = state;
    if (latest is! PhotosLoaded) return;
    emit(PhotosLoaded(latest.data.copyWith(photos: photos, isRefreshing: false)));
  }

  // ── فلاتر العرض ─────────────────────────────────────────────────

  void setFilterEntityType(RelatedEntityType? type) {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return;
    emit(
      PhotosLoaded(
        type == null
            ? current.data.copyWith(clearFilterEntityType: true)
            : current.data.copyWith(filterEntityType: type),
      ),
    );
    unawaited(refresh());
  }

  void setFilterUploadedByMeOnly(bool onlyMine) {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return;
    emit(PhotosLoaded(current.data.copyWith(filterUploadedByMeOnly: onlyMine)));
    unawaited(refresh());
  }

  void setSearchQuery(String query) {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return;
    emit(PhotosLoaded(current.data.copyWith(searchQuery: query)));
  }

  void selectPhoto(SitePhoto? photo) {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return;
    emit(
      PhotosLoaded(
        photo == null
            ? current.data.copyWith(clearSelectedPhoto: true)
            : current.data.copyWith(selectedPhoto: photo),
      ),
    );
  }

  // ── الالتقاط + الضغط + الإدراج في الطابور ──────────────────────

  /// الخطوة الأولى فقط من تدفّق الالتقاط: يفتح الكاميرا أو منتقي
  /// الملفات (`image_picker`، يدعم الويب/الديسكتاوب تلقائياً) ويُعيد
  /// البايتات الخام دون أي ضغط أو إدراج في الطابور بعد — تستدعيها
  /// `camera_screen.dart` مباشرة، ثم تُمرِّر الناتج (`extra` في
  /// `go_router`) إلى `photo_attach_screen.dart` لاختيار الكيان
  /// المرتبط والوسوم قبل [enqueueCapturedImage] الفعلية.
  Future<CapturedImage?> captureImage({required bool fromCamera}) async {
    final ResultOf<CapturedImage?> result = fromCamera
        ? await _cameraService.captureFromCamera()
        : await _cameraService.pickFromGallery();
    return result.getOrNull();
  }

  /// تدفّق مختصر بخطوة واحدة: التقاط + ضغط + إدراج مباشرة بكيان/وسوم
  /// معروفين مسبقاً (مثال: زر التقاط سريع من `my_photos_screen.dart`
  /// يرتبط تلقائياً بالمشروع الحالي نفسه دون المرور بـ
  /// `photo_attach_screen.dart`). يُعيد `true` عند نجاح الإدراج في
  /// الطابور (وليس نجاح الرفع السحابي نفسه — انظر توثيق
  /// [enqueueCapturedImage]).
  Future<bool> captureAndEnqueue({
    required bool fromCamera,
    required RelatedEntityType relatedEntityType,
    required String relatedEntityId,
    List<String> tags = const <String>[],
    String captionText = '',
  }) async {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return false;

    emit(PhotosLoaded(current.data.copyWith(isCapturing: true)));
    final CapturedImage? captured = await captureImage(fromCamera: fromCamera);
    if (captured == null) {
      _stopCapturing();
      return false;
    }

    final bool enqueued = await enqueueCapturedImage(
      captured: captured,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      tags: tags,
      captionText: captionText,
    );
    _stopCapturing();
    return enqueued;
  }

  /// نظير [captureAndEnqueue] لاختيار عدة صور دفعة واحدة من المعرض
  /// (`photo_attach_screen.dart` على سطح المكتب/الويب، حيث اختيار عدة
  /// ملفات دفعة واحدة تجربة طبيعية ومتوقعة). يُعيد عدد الصور التي
  /// أُدرجت بنجاح.
  Future<int> pickAndEnqueueMultiple({
    required RelatedEntityType relatedEntityType,
    required String relatedEntityId,
    List<String> tags = const <String>[],
  }) async {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return 0;

    emit(PhotosLoaded(current.data.copyWith(isCapturing: true)));

    final ResultOf<List<CapturedImage>> pickResult =
        await _cameraService.pickMultipleFromGallery();
    final List<CapturedImage> images =
        pickResult.fold((Failure _) => const <CapturedImage>[], (List<CapturedImage> l) => l);

    int successCount = 0;
    for (final CapturedImage captured in images) {
      final bool ok = await enqueueCapturedImage(
        captured: captured,
        relatedEntityType: relatedEntityType,
        relatedEntityId: relatedEntityId,
        tags: tags,
        captionText: '',
      );
      if (ok) successCount++;
    }

    _stopCapturing();
    return successCount;
  }

  /// الخطوة الثانية (بعد [captureImage]): يضغط بايتات الصورة الخام
  /// فوراً (أصل + مصغّرة)، يقرأ الموقع الجغرافي الاختياري، ثم يُدرج
  /// الصف في طابور الرفع المحلي (`PhotoDao.enqueue`) مرتبطاً بالكيان
  /// المحدَّد مع الوسوم/التعليق النهائيين — `photo_attach_screen.dart`
  /// تستدعيها مباشرة بعد اختيار المستخدم لكيان الربط والوسوم.
  Future<bool> enqueueCapturedImage({
    required CapturedImage captured,
    required RelatedEntityType relatedEntityType,
    required String relatedEntityId,
    required List<String> tags,
    required String captionText,
  }) async {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return false;
    final PhotosData data = current.data;

    try {
      final CompressedImageResult compressed = await _imageCompressor.compress(
        captured.bytes,
      );
      final CompressedImageResult thumbnail = await _imageCompressor.compress(
        captured.bytes,
        maxWidth: 320,
        maxHeight: 320,
        quality: 70,
      );

      // موقع جغرافي اختياري تماماً — فشل قراءته (إذن مرفوض/جهاز بلا
      // GPS على الديسكتاوب) لا يُفشل الالتقاط نفسه إطلاقاً.
      GeoPoint? location;
      if (_locationService != null) {
        final ResultOf<GeoPoint> locationResult =
            await _locationService.currentLocation();
        location = locationResult.getOrNull();
      }

      final String id = IdGenerator.v4();
      final DateTime now = DateTime.now().toUtc();

      await _photoDao.enqueue(
        PhotoQueueTableCompanion.insert(
          id: id,
          clientMutationId: id,
          companyId: data.currentUser.companyId,
          projectId: Value<String?>(data.project.id),
          relatedEntityType: relatedEntityType.dbValue,
          relatedEntityId: relatedEntityId,
          localFilePath: captured.fileName,
          mimeType: Value<String>(
            compressed.width == 0 && compressed.height == 0
                ? captured.mimeType
                : 'image/jpeg',
          ),
          localFileBytes: Uint8List.fromList(compressed.bytes),
          localThumbnailBytes: Value<Uint8List?>(Uint8List.fromList(thumbnail.bytes)),
          caption: Value<String?>(
            PhotosData.buildCaption(tags: tags, captionText: captionText),
          ),
          fileSizeBytes: Value<int?>(compressed.compressedSizeBytes),
          takenAt: now,
          latitude: Value<double?>(location?.latitude),
          longitude: Value<double?>(location?.longitude),
          uploadedBy: Value<String?>(data.currentUser.userId),
          createdAt: now,
        ),
      );

      // محاولة رفع فورية إن كان الاتصال متاحاً الآن (خلفية بحتة،
      // `unawaited` عمداً — انظر توثيق `SyncEngine.triggerManualSync`
      // حول أولوية طابور الصور المنخفضة). بلا اتصال، يبقى العنصر في
      // الطابور بانتظار [ContinuousSyncStrategy] التالية تلقائياً.
      unawaited(_syncEngine.triggerManualSync());

      return true;
    } catch (error) {
      return false;
    }
  }

  void _stopCapturing() {
    final PhotosState current = state;
    if (current is! PhotosLoaded) return;
    emit(PhotosLoaded(current.data.copyWith(isCapturing: false)));
  }

  // ── إعادة محاولة/حذف ────────────────────────────────────────────

  /// إعادة محاولة فورية ويدوية لصورة فشل رفعها — زر "إعادة المحاولة"
  /// في `upload_progress_indicator.dart`. بخلاف إعادة المحاولة
  /// التلقائية عبر [SyncEngine] (التي تحترم `RetryPolicy`/التأخير
  /// التصاعدي)، هذه تتجاوز التأخير عمداً بناءً على طلب صريح من
  /// المستخدم نفسه.
  Future<void> retryUpload(String queueItemId) async {
    final PhotoQueueRow? row = await _photoDao.getById(queueItemId);
    if (row == null) return;
    await _photoUploadProcessor.processRow(row);
  }

  /// يحذف صورة — تعمل مع كلا المصدرين معاً بشفافية: صورة لا تزال في
  /// طابور الرفع المحلي (تُحذف من [PhotoDao] فقط، لم تصل للسحابة بعد)،
  /// أو صورة مرفوعة فعلياً (تُحذف من `IPhotoRepository`، ملف+سجل معاً).
  Future<bool> deletePhoto(SitePhoto photo) async {
    final ResultOf<void> result = await _photoRepository.deletePhoto(photo.id);
    final bool success = result.fold((Failure _) => false, (_) => true);
    if (!success) return false;

    final PhotosState current = state;
    if (current is PhotosLoaded) {
      emit(
        PhotosLoaded(
          current.data.copyWith(
            photos: current.data.photos
                .where((SitePhoto p) => p.id != photo.id)
                .toList(growable: false),
          ),
        ),
      );
    }
    return true;
  }

  /// يحذف عنصراً لم يُرفَع بعد من الطابور مباشرة (قبل وصوله للسحابة
  /// أصلاً) — "إلغاء" التقاط بدل "حذف" فعلي.
  Future<void> cancelQueuedUpload(String queueItemId) {
    return _photoDao.deletePhoto(queueItemId);
  }

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    return super.close();
  }
}
