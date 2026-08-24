import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../data/storage/photo_storage_service.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/punch_item.dart';
import '../../../../domain/entities/site_photo.dart';
import '../../../../domain/enums/punch_status.dart';
import '../../../../domain/enums/related_entity_type.dart';
import '../../../../domain/enums/task_priority.dart';
import '../../../../domain/repositories/i_photo_repository.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import '../../../../domain/usecases/punch/close_punch_item_usecase.dart';
import '../../../../domain/usecases/punch/create_punch_item_usecase.dart';
import '../../../../domain/usecases/punch/get_project_punch_items_usecase.dart';
import 'punch_state.dart';

/// `Cubit` ميزة `features/punch_list/` (Prompt 19) — يقود كل شاشات
/// الميزة (تصفّح/تصفية العيوب على الهاتف، لوحة متابعة سطح المكتب عبر
/// كل المشاريع، إنشاء عنصر جديد، وإغلاقه رسمياً) عبر [PunchData] واحدة
/// مجمّعة، بنفس فلسفة `TasksCubit`/`PhotosCubit`.
///
/// ⚠️ قرار تصميم مهم: بخلاف `features/photos/` (طابور رفع محلي
/// Offline-first كامل عبر `PhotoDao`/`SyncEngine`)، طبقة `data/` المبنية
/// مسبقاً لـ Punch List (`PunchRepositoryImpl`، Prompt 07/10) **لا**
/// تملك جدول Outbox محلي مخصّص لها (انظر غياب أي `punch_queue_table.dart`
/// ضمن `data/local/`) — الإنشاء/الإغلاق هنا عمليتان مباشرتان عبر
/// الشبكة (بنفس أسلوب `ReportFormCubit.submitReport`)، مع **تحديثات
/// تفاؤلية** فقط (إدراج/استبدال فوري في القائمة المحلية للـ `Cubit`
/// نفسها، بلا انتظار الخادم لتحديث الواجهة) — لا مع طابور Outbox حقيقي
/// يبقى عبر إعادة تشغيل التطبيق. أي دعم Offline حقيقي لهذه الميزة
/// يتطلب أولاً توسيع طبقة `data/` (خارج نطاق Prompt 19 هذا).
///
/// ⚠️ قرار تصميم ثانٍ: [PunchItem] (`domain/entities/punch_item.dart`)
/// لا يحمل حقلي إحداثيات جغرافية منفصلين ولا حقل "ملاحظة إغلاق" نصياً
/// مخصصاً (مطابقةً لعمودي `punch_items` الفعليين في قاعدة البيانات،
/// Prompt 03) — فقط [PunchItem.locationNote] نصي حر. لذا:
/// 1) الموقع الملتقط تلقائياً عبر [captureCurrentLocation] (GPS) يُدمَج
///    كنص إحداثيات ضمن [PunchItem.locationNote] نفسه عند الإنشاء
///    (انظر [_formatLocationNote]) بدل تجاهله أو افتراض عمود غير
///    موجود أصلاً.
/// 2) "ملاحظة المعالجة الإلزامية" في نموذج الإغلاق (`punch_close_form.dart`)
///    تُحفَظ كـ [SitePhoto.caption] لصورة المعالجة **الإلزامية** نفسها
///    (حقل موجود فعلاً في `public.photos`، Prompt 09) بدل اختراع عمود
///    جديد على `punch_items` — وهو أيضاً سبب جعل صورة المعالجة إلزامية
///    فعلياً في [closePunchItemWithEvidence]: هي الوعاء الوحيد المتاح
///    لحمل نص الملاحظة نفسها.
class PunchCubit extends Cubit<PunchState> {
  PunchCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required GetProjectPunchItemsUsecase getProjectPunchItemsUsecase,
    required CreatePunchItemUsecase createPunchItemUsecase,
    required ClosePunchItemUsecase closePunchItemUsecase,
    required CameraService cameraService,
    required PhotoStorageService photoStorageService,
    required IPhotoRepository photoRepository,
    LocationService? locationService,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _getProjectPunchItemsUsecase = getProjectPunchItemsUsecase,
        _createPunchItemUsecase = createPunchItemUsecase,
        _closePunchItemUsecase = closePunchItemUsecase,
        _cameraService = cameraService,
        _photoStorageService = photoStorageService,
        _photoRepository = photoRepository,
        _locationService = locationService,
        super(const PunchLoading());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final GetProjectPunchItemsUsecase _getProjectPunchItemsUsecase;
  final CreatePunchItemUsecase _createPunchItemUsecase;
  final ClosePunchItemUsecase _closePunchItemUsecase;
  final CameraService _cameraService;
  final PhotoStorageService _photoStorageService;
  final IPhotoRepository _photoRepository;
  final LocationService? _locationService;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى مرة واحدة عند دخول `punch_list_screen.dart`: يحدّد
  /// "المشروع الحالي" (نفس منطق `TasksCubit.loadInitial`) ثم يجلب
  /// عناصر Punch List الخاصة به فقط. لا يجلب [PunchData.dashboardItems]
  /// (لوحة سطح المكتب) هنا — تحميل كسول منفصل عبر [loadDashboard].
  Future<void> loadInitial(AppUser user) async {
    emit(const PunchLoading());

    final ResultOf<List<Project>> projectsResult = await _getMyProjectsUsecase(
      user.userId,
    );

    final List<Project> projects = projectsResult.fold(
      (Failure _) => const <Project>[],
      (List<Project> p) => p,
    );

    final Project? project = projects.isEmpty
        ? null
        : projects.firstWhere(
            (Project p) => p.status.isActive,
            orElse: () => projects.first,
          );

    if (project == null) {
      emit(
        PunchLoaded(
          PunchData(currentUser: user, myProjects: projects),
        ),
      );
      return;
    }

    final List<PunchItem> items = await _fetchItems(project.id);

    emit(
      PunchLoaded(
        PunchData(
          currentUser: user,
          project: project,
          items: items,
          myProjects: projects,
        ),
      ),
    );
  }

  Future<List<PunchItem>> _fetchItems(String projectId) async {
    final ResultOf<List<PunchItem>> result = await _getProjectPunchItemsUsecase(
      projectId,
    );
    return result.fold(
      (Failure _) => const <PunchItem>[],
      (List<PunchItem> items) => items,
    );
  }

  /// يعيد تحميل [PunchData.items] فقط (سحب للتحديث في
  /// `punch_list_screen.dart`) دون إعادة تحديد المشروع الحالي.
  Future<void> refresh() async {
    final PunchData? current = state.dataOrNull;
    if (current == null || current.project == null) return;

    emit(PunchLoaded(current.copyWith(isItemsLoading: true)));
    final List<PunchItem> items = await _fetchItems(current.project!.id);
    final PunchData latest = state.dataOrNull ?? current;
    emit(PunchLoaded(latest.copyWith(items: items, isItemsLoading: false)));
  }

  // ── لوحة المتابعة (سطح المكتب، كل المشاريع معاً) ─────────────────

  /// يجلب عناصر Punch List لكل مشروع ضمن [PunchData.myProjects]
  /// (استدعاء واحد منفصل لكل مشروع عبر [GetProjectPunchItemsUsecase]
  /// — لا يوجد حالياً أي UseCase/استعلام "كل مشاريع الشركة دفعة واحدة"
  /// في طبقة `domain/` لهذه الميزة تحديداً)، ثم يجمعها ويصفّي العناصر
  /// المفتوحة فقط (`!status.isClosed`) ويرتّبها تصاعدياً حسب
  /// `createdAt` (الأقدم أولاً) — `punch_dashboard.dart` مباشرة.
  Future<void> loadDashboard() async {
    final PunchData? current = state.dataOrNull;
    if (current == null) return;

    emit(PunchLoaded(current.copyWith(isDashboardLoading: true)));

    List<Project> projects = current.myProjects;
    if (projects.isEmpty) {
      final ResultOf<List<Project>> projectsResult =
          await _getMyProjectsUsecase(current.currentUser.userId);
      projects = projectsResult.fold(
        (Failure _) => const <Project>[],
        (List<Project> p) => p,
      );
    }

    final List<PunchItem> allItems = <PunchItem>[];
    for (final Project project in projects) {
      allItems.addAll(await _fetchItems(project.id));
    }

    final List<PunchItem> openSortedOldestFirst = allItems
        .where((PunchItem i) => !i.status.isClosed)
        .toList(growable: false)
      ..sort((PunchItem a, PunchItem b) => a.createdAt.compareTo(b.createdAt));

    final Map<String, Project> projectsById = <String, Project>{
      for (final Project p in projects) p.id: p,
    };

    final PunchData latest = state.dataOrNull ?? current;
    emit(
      PunchLoaded(
        latest.copyWith(
          myProjects: projects,
          projectsById: projectsById,
          dashboardItems: openSortedOldestFirst,
          isDashboardLoading: false,
        ),
      ),
    );
  }

  // ── تصفية (`punch_status_filter.dart`) ──────────────────────────

  void setStatusFilter(PunchStatus? status) {
    final PunchData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      PunchLoaded(
        current.copyWith(
          statusFilter: status,
          clearStatusFilter: status == null,
        ),
      ),
    );
  }

  void setSearchQuery(String query) {
    final PunchData? current = state.dataOrNull;
    if (current == null) return;
    emit(PunchLoaded(current.copyWith(searchQuery: query)));
  }

  void clearFilters() {
    final PunchData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      PunchLoaded(
        current.copyWith(clearStatusFilter: true, searchQuery: ''),
      ),
    );
  }

  // ── التقاط كاميرا/موقع مشترَكان (إنشاء + إغلاق) ──────────────────

  /// يفتح الكاميرا (أو منتقي الملفات) ويُعيد البايتات الخام دون أي
  /// رفع بعد — تستدعيها `punch_item_create.dart`/`punch_close_form.dart`
  /// معاً قبل الاستدعاء الفعلي لـ [createPunchItem]/
  /// [closePunchItemWithEvidence]، بنفس نمط `PhotosCubit.captureImage`.
  Future<CapturedImage?> captureImage({required bool fromCamera}) async {
    final ResultOf<CapturedImage?> result = fromCamera
        ? await _cameraService.captureFromCamera()
        : await _cameraService.pickFromGallery();
    return result.getOrNull();
  }

  /// يقرأ الموقع الجغرافي الحالي (GPS) — `punch_item_create.dart` عند
  /// فتح نموذج تسجيل عيب جديد. فشل القراءة (إذن مرفوض، أو جهاز بلا
  /// GPS على سطح المكتب) اختياري تماماً ولا يُفشل تعبئة النموذج نفسه؛
  /// يُعاد `null` بصمت في هذه الحالة.
  Future<GeoPoint?> captureCurrentLocation() async {
    final LocationService? service = _locationService;
    if (service == null) return null;
    final ResultOf<GeoPoint> result = await service.currentLocation();
    return result.getOrNull();
  }

  // ── إنشاء عنصر ملاحظات جديد (`punch_item_create.dart`) ───────────

  /// ينشئ عنصر ملاحظات جديداً ضمن مشروع المستخدم الحالي، مع رفع أي
  /// [photos] مرفقة (اختيارية) مرتبطة بمعرّف العنصر الجديد نفسه —
  /// [RelatedEntityType.punchItem]. يُعيد [PunchItem] المُنشأ فعلياً
  /// عند النجاح، أو `null` عند الفشل (لا مشروع حالي، أو فشل
  /// [CreatePunchItemUsecase] نفسها).
  ///
  /// يُطبَّق **تحديث تفاؤلي جزئي**: عنصر القائمة الجديد لا يظهر إلا
  /// بعد تأكيد الخادم فعلياً (بخلاف `TasksCubit.updateStatus` الذي
  /// يُظهر فوراً قبل الرد) لأن الإنشاء هنا مرتبط أصلاً برفع صور قد
  /// تفشل جزئياً — يُفضَّل عرض حالة تحميل واضحة ([PunchData.isSubmitting])
  /// على عنصر قد يُحذف فجأة عند فشل لاحق.
  Future<PunchItem?> createPunchItem({
    required String title,
    required TaskPriority priority,
    String? description,
    String? locationNote,
    GeoPoint? location,
    DateTime? dueDate,
    List<CapturedImage> photos = const <CapturedImage>[],
  }) async {
    final PunchData? current = state.dataOrNull;
    final Project? project = current?.project;
    if (current == null || project == null) return null;

    emit(PunchLoaded(current.copyWith(isSubmitting: true)));

    final String id = IdGenerator.v4();
    final DateTime now = DateTime.now().toUtc();

    for (final CapturedImage image in photos) {
      await _uploadEvidence(
        image: image,
        companyId: current.currentUser.companyId,
        projectId: project.id,
        relatedEntityId: id,
        caption: null,
        uploadedBy: current.currentUser.userId,
        location: location,
      );
    }

    final PunchItem item = PunchItem(
      id: id,
      companyId: current.currentUser.companyId,
      projectId: project.id,
      title: title.trim(),
      description: (description == null || description.trim().isEmpty)
          ? null
          : description.trim(),
      locationNote: _formatLocationNote(
        note: locationNote,
        location: location,
      ),
      status: PunchStatus.open,
      priority: priority,
      createdBy: current.currentUser.userId,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );

    final ResultOf<PunchItem> result = await _createPunchItemUsecase(item);

    final PunchData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(PunchLoaded(latest.copyWith(isSubmitting: false)));
        return null;
      },
      (PunchItem created) {
        emit(
          PunchLoaded(
            latest.copyWith(
              items: <PunchItem>[created, ...latest.items],
              isSubmitting: false,
            ),
          ),
        );
        return created;
      },
    );
  }

  /// يدمج نص [note] الحر مع إحداثيات [location] الملتقطة تلقائياً (إن
  /// وُجدت) ضمن حقل [PunchItem.locationNote] النصي الوحيد المتاح —
  /// انظر توثيق القرار الكامل أعلى الصنف.
  String? _formatLocationNote({required String? note, GeoPoint? location}) {
    final String trimmedNote = (note ?? '').trim();
    if (location == null) {
      return trimmedNote.isEmpty ? null : trimmedNote;
    }
    final String coordinates =
        'الإحداثيات: ${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)}';
    if (trimmedNote.isEmpty) return coordinates;
    return '$trimmedNote — $coordinates';
  }

  // ── إغلاق عنصر (`punch_close_form.dart`) ──────────────────────────

  /// يغلق [item] رسمياً بعد رفع صورة معالجة **إلزامية** ([evidence])
  /// تحمل [note] كـ [SitePhoto.caption] (انظر توثيق القرار الكامل أعلى
  /// الصنف)، ثم يستدعي [ClosePunchItemUsecase] نفسها. يُعيد `true` عند
  /// النجاح الكامل (رفع الصورة + الإغلاق معاً) و`false` عند فشل أي
  /// منهما — لا إغلاق جزئياً بلا دليل مرفق أبداً.
  Future<bool> closePunchItemWithEvidence({
    required PunchItem item,
    required String note,
    required CapturedImage evidence,
  }) async {
    final PunchData? current = state.dataOrNull;
    if (current == null) return false;

    emit(PunchLoaded(current.copyWith(isClosing: true)));

    final SitePhoto? uploaded = await _uploadEvidence(
      image: evidence,
      companyId: current.currentUser.companyId,
      projectId: item.projectId,
      relatedEntityId: item.id,
      caption: note.trim(),
      uploadedBy: current.currentUser.userId,
    );

    if (uploaded == null) {
      final PunchData latest = state.dataOrNull ?? current;
      emit(PunchLoaded(latest.copyWith(isClosing: false)));
      return false;
    }

    final ResultOf<PunchItem> result = await _closePunchItemUsecase(
      item: item,
      closedBy: current.currentUser.userId,
    );

    final PunchData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(PunchLoaded(latest.copyWith(isClosing: false)));
        return false;
      },
      (PunchItem closed) {
        emit(
          PunchLoaded(
            latest.copyWith(
              items: _replaceItem(latest.items, closed),
              dashboardItems: latest.dashboardItems
                  .where((PunchItem i) => i.id != closed.id)
                  .toList(growable: false),
              isClosing: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  /// يرفع [image] عبر [PhotoStorageService] ثم يحفظ صفّه الوصفي عبر
  /// [IPhotoRepository.uploadPhoto] — منطق مشترك بين [createPunchItem]
  /// (صور اختيارية متعددة بلا تعليق) و[closePunchItemWithEvidence]
  /// (صورة معالجة إلزامية واحدة، بتعليق = ملاحظة الإغلاق)، بنفس أسلوب
  /// `ReportFormCubit._attachPhoto`. يُعيد `null` بصمت عند أي فشل (رفع
  /// الملف أو حفظ السجل) — المستدعي يقرر كيف يتعامل مع الفشل حسب
  /// إلزامية الصورة في سياقه.
  Future<SitePhoto?> _uploadEvidence({
    required CapturedImage image,
    required String companyId,
    required String projectId,
    required String relatedEntityId,
    required String? caption,
    String? uploadedBy,
    GeoPoint? location,
  }) async {
    final ResultOf<String> uploadResult = await _photoStorageService.uploadPhoto(
      bytes: image.bytes,
      companyId: companyId,
      projectId: projectId,
      relatedEntityId: relatedEntityId,
      originalFileName: image.fileName,
      contentType: image.mimeType,
    );

    final String? storagePath = uploadResult.getOrNull();
    if (storagePath == null) return null;

    final DateTime now = DateTime.now().toUtc();
    final SitePhoto photo = SitePhoto(
      id: IdGenerator.v4(),
      companyId: companyId,
      projectId: projectId,
      relatedEntityType: RelatedEntityType.punchItem,
      relatedEntityId: relatedEntityId,
      storagePath: storagePath,
      caption: caption,
      latitude: location?.latitude,
      longitude: location?.longitude,
      uploadedBy: uploadedBy,
      takenAt: now,
      createdAt: now,
    );

    final ResultOf<SitePhoto> saveResult = await _photoRepository.uploadPhoto(
      photo,
    );
    return saveResult.getOrNull();
  }

  List<PunchItem> _replaceItem(List<PunchItem> source, PunchItem updated) {
    return source
        .map((PunchItem i) => i.id == updated.id ? updated : i)
        .toList(growable: false);
  }
}
