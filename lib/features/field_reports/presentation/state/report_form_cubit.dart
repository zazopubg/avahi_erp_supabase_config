import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../data/storage/photo_storage_service.dart';
import '../../../../data/storage/signature_storage_service.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/field_report.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/site_photo.dart';
import '../../../../domain/enums/related_entity_type.dart';
import '../../../../domain/enums/report_status.dart';
import '../../../../domain/enums/weather_condition.dart';
import '../../../../domain/repositories/i_photo_repository.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import '../../../../domain/usecases/reports/get_project_reports_usecase.dart';
import '../../../../domain/usecases/reports/save_draft_report_usecase.dart';
import '../../../../domain/usecases/reports/sign_report_usecase.dart';
import '../../../../domain/usecases/reports/submit_report_usecase.dart';
import '../../core/services/weather_api_service.dart';
import 'report_form_state.dart';

/// `Cubit` جانب "العامل الميداني" الكامل من ميزة التقارير — يقود كل
/// شاشات `features/field_reports/presentation/screens/mobile/`: تعبئة
/// نموذج تقرير مع حفظ تلقائي (Debounce)، قائمة المسوّدات، كل تقاريري،
/// المعاينة النهائية، والتوقيع الرقمي ثم التقديم — عبر [ReportFormData]
/// واحدة مجمّعة، بنفس فلسفة `AttendanceCubit`/`TasksCubit`.
class ReportFormCubit extends Cubit<ReportFormState> {
  ReportFormCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required SaveDraftReportUsecase saveDraftReportUsecase,
    required SubmitReportUsecase submitReportUsecase,
    required SignReportUsecase signReportUsecase,
    required GetProjectReportsUsecase getProjectReportsUsecase,
    required WeatherApiService weatherApiService,
    required LocationService locationService,
    required CameraService cameraService,
    required SignatureStorageService signatureStorageService,
    required PhotoStorageService photoStorageService,
    required IPhotoRepository photoRepository,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _saveDraftReportUsecase = saveDraftReportUsecase,
        _submitReportUsecase = submitReportUsecase,
        _signReportUsecase = signReportUsecase,
        _getProjectReportsUsecase = getProjectReportsUsecase,
        _weatherApiService = weatherApiService,
        _locationService = locationService,
        _cameraService = cameraService,
        _signatureStorageService = signatureStorageService,
        _photoStorageService = photoStorageService,
        _photoRepository = photoRepository,
        super(const ReportFormLoading());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final SaveDraftReportUsecase _saveDraftReportUsecase;
  final SubmitReportUsecase _submitReportUsecase;
  final SignReportUsecase _signReportUsecase;
  final GetProjectReportsUsecase _getProjectReportsUsecase;
  final WeatherApiService _weatherApiService;
  final LocationService _locationService;
  final CameraService _cameraService;
  final SignatureStorageService _signatureStorageService;
  final PhotoStorageService _photoStorageService;
  final IPhotoRepository _photoRepository;

  /// مؤقّت الحفظ التلقائي (Debounce) — يُعاد ضبطه عند كل تعديل حقل،
  /// ويُنفَّذ الحفظ الفعلي فقط بعد توقّف المستخدم عن الكتابة لهذه
  /// المدة، تفادياً لطلب حفظ منفصل على كل ضغطة مفتاح.
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 1200);

  // ── تحميل أولي (نقطة الدخول الوحيدة من `field_reports_screen.dart`) ─

  /// يُستدعى مرة واحدة عند دخول الفرع الهاتفي من `field_reports_screen.dart`:
  /// يحدّد "المشروع الحالي" (نفس منطق `AttendanceCubit.loadInitial`)،
  /// يجلب كل تقارير المستخدم ضمنه، ويبدأ مسوّدة تقرير فارغة جاهزة إن
  /// أراد المستخدم إنشاء تقرير جديد فوراً دون خطوة وسيطة — بنفس فلسفة
  /// `AttendanceData.todayRecord` (سجل حاضر دوماً في الحالة، تُبنى
  /// الشاشات فوقه مباشرة).
  Future<void> loadInitial(AppUser user) async {
    emit(const ReportFormLoading());

    final ResultOf<List<Project>> projectsResult = await _getMyProjectsUsecase(user.userId);

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
        const ReportFormError(
          ValidationFailure(
            message: 'لا يوجد مشروع نشط مرتبط بحسابك لإنشاء تقرير ميداني ضمنه.',
            code: 'field_reports.no_project',
          ),
        ),
      );
      return;
    }

    _startNew(user: user, project: project);
    unawaited(_autoFillWeather());
    unawaited(loadMyReports());
  }

  /// يُنشئ مسوّدة تقرير فارغة جديدة (معرّف مُولَّد محلياً عبر
  /// [IdGenerator] — Offline-first، بنفس نمط `RequestLeaveUsecase`) —
  /// `report_form_screen.dart` عند اختيار "تقرير جديد" (سواء أول دخول
  /// عبر [loadInitial]، أو لاحقاً فوق نفس المشروع المحمَّل عبر زر
  /// صريح في `my_reports_screen.dart`).
  void startNewDraft() {
    final ReportFormData? current = state.dataOrNull;
    if (current == null) return;
    _startNew(user: current.currentUser, project: current.project);
    unawaited(_autoFillWeather());
  }

  void _startNew({required AppUser user, required Project project}) {
    final DateTime now = DateTime.now();
    final FieldReport blank = FieldReport(
      id: IdGenerator.v4(),
      companyId: user.companyId,
      projectId: project.id,
      reportDate: now,
      status: ReportStatus.draft,
      laborCount: 0,
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
      createdBy: user.userId,
    );

    final ReportFormData? existing = state.dataOrNull;
    emit(
      ReportFormReady(
        existing == null
            ? ReportFormData(currentUser: user, project: project, report: blank)
            : existing.copyWith(report: blank, photos: const <SitePhoto>[]),
      ),
    );
  }

  /// يستأنف تحرير/عرض تقرير قائم عبر كائنه الكامل — `report_form_screen.dart`
  /// عند الدخول من `report_drafts_screen.dart` (متابعة مسوّدة)، أو
  /// `report_preview_screen.dart`/`report_signature_screen.dart` عند
  /// فتح تقرير من `my_reports_screen.dart`. لا يُعيد تعبئة الطقس (تقرير
  /// له بيانات موجودة أصلاً، بخلاف [startNewDraft]).
  Future<void> resumeExisting(FieldReport report) async {
    final ReportFormData? current = state.dataOrNull;
    if (current == null) return;

    emit(ReportFormReady(current.copyWith(report: report, photos: const <SitePhoto>[])));
    await _loadPhotos();
  }

  /// يجلب تعبئة طقس تلقائية بناءً على موقع الجهاز الحالي (أفضل تقريب
  /// متاح لموقع المشروع الفعلي وقت التعبئة) — لا يمنع أي تعديل يدوي
  /// لاحق للحقلين، ولا يفشل تعبئة النموذج بالكامل عند تعذّره (يُسجَّل
  /// [ReportFormData.weatherError] فقط، والحقلان يبقيان قابلين للتعبئة
  /// اليدوية دوماً).
  Future<void> _autoFillWeather() async {
    final ReportFormData? current = state.dataOrNull;
    if (current == null) return;

    emit(ReportFormReady(current.copyWith(isWeatherLoading: true, clearWeatherError: true)));

    final ResultOf<GeoPoint> locationResult = await _locationService.currentLocation();
    final GeoPoint? point = locationResult.getOrNull();

    if (point == null) {
      final ReportFormData latest = state.dataOrNull ?? current;
      emit(
        ReportFormReady(
          latest.copyWith(
            isWeatherLoading: false,
            weatherError: 'تعذّر تحديد الموقع لتعبئة الطقس تلقائياً — يمكن تعبئته يدوياً.',
          ),
        ),
      );
      return;
    }

    final ResultOf<WeatherReading> weatherResult = await _weatherApiService.fetchCurrentWeather(
      latitude: point.latitude,
      longitude: point.longitude,
    );

    final ReportFormData latest = state.dataOrNull ?? current;
    weatherResult.fold(
      (Failure _) => emit(
        ReportFormReady(
          latest.copyWith(
            isWeatherLoading: false,
            weatherError: 'تعذّر جلب بيانات الطقس تلقائياً — يمكن تعبئته يدوياً.',
          ),
        ),
      ),
      (WeatherReading reading) => emit(
        ReportFormReady(
          latest.copyWith(
            isWeatherLoading: false,
            report: latest.report.copyWith(
              weatherCondition: reading.condition,
              temperatureC: reading.temperatureC,
            ),
          ),
        ),
      ),
    );
  }

  /// يعيد محاولة تعبئة الطقس يدوياً — زر إعادة محاولة في
  /// `weather_selector.dart` عند فشل [_autoFillWeather] الأولي.
  Future<void> retryWeatherFill() => _autoFillWeather();

  // ── تعديل حقول النموذج (كل تعديل يُشغّل حفظاً تلقائياً مؤجَّلاً) ──

  void updateReportDate(DateTime date) => _updateReport((FieldReport r) => r.copyWith(reportDate: date));

  void updateWeatherCondition(WeatherCondition condition) =>
      _updateReport((FieldReport r) => r.copyWith(weatherCondition: condition));

  void updateTemperature(double celsius) =>
      _updateReport((FieldReport r) => r.copyWith(temperatureC: celsius));

  void updateLaborCount(int count) =>
      _updateReport((FieldReport r) => r.copyWith(laborCount: count < 0 ? 0 : count));

  void updateWorkPerformed(String value) =>
      _updateReport((FieldReport r) => r.copyWith(workPerformed: value));

  void updateMaterialsUsed(String value) =>
      _updateReport((FieldReport r) => r.copyWith(materialsUsed: value));

  void updateEquipmentUsed(String value) =>
      _updateReport((FieldReport r) => r.copyWith(equipmentUsed: value));

  void updateIssues(String value) => _updateReport((FieldReport r) => r.copyWith(issues: value));

  void updateNotes(String value) => _updateReport((FieldReport r) => r.copyWith(notes: value));

  void _updateReport(FieldReport Function(FieldReport current) mutate) {
    final ReportFormData? current = state.dataOrNull;
    if (current == null || !current.report.status.isDraft) return;

    emit(ReportFormReady(current.copyWith(report: mutate(current.report))));
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      unawaited(saveNow());
    });
  }

  // ── حفظ مسوّدة ────────────────────────────────────────────────────

  /// يحفظ [ReportFormData.report] فوراً (يتجاوز الحفظ التلقائي المؤجَّل)
  /// — يُستدعى من [_scheduleAutoSave] بعد انتهاء المهلة، ومن الشاشات
  /// نفسها عند مغادرتها (`onPop`) لضمان عدم فقدان آخر تعديل.
  Future<bool> saveNow() async {
    _debounceTimer?.cancel();

    final ReportFormData? current = state.dataOrNull;
    if (current == null || !current.report.status.isDraft) return false;

    emit(ReportFormReady(current.copyWith(isSaving: true)));

    final ResultOf<FieldReport> result = await _saveDraftReportUsecase(current.report);

    final ReportFormData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(ReportFormReady(latest.copyWith(isSaving: false)));
        return false;
      },
      (FieldReport saved) {
        emit(ReportFormReady(latest.copyWith(report: saved, isSaving: false)));
        return true;
      },
    );
  }

  // ── صور مرفقة ────────────────────────────────────────────────────

  Future<void> _loadPhotos() async {
    final ReportFormData? current = state.dataOrNull;
    if (current == null) return;

    final ResultOf<List<SitePhoto>> result = await _photoRepository.getPhotosForEntity(
      relatedEntityType: RelatedEntityType.fieldReport,
      relatedEntityId: current.report.id,
    );

    final ReportFormData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) {},
      (List<SitePhoto> photos) => emit(ReportFormReady(latest.copyWith(photos: photos))),
    );
  }

  /// يفتح كاميرا الجهاز (أو منتقي الملفات إن تعذّرت) ويرفع الصورة
  /// الملتقطة مرتبطةً بالتقرير الحالي — `report_photo_attach.dart`.
  Future<bool> attachPhotoFromCamera() => _attachPhoto(fromCamera: true);

  /// يفتح منتقي معرض الصور بدل الكاميرا — زر بديل في نفس الودجة.
  Future<bool> attachPhotoFromGallery() => _attachPhoto(fromCamera: false);

  Future<bool> _attachPhoto({required bool fromCamera}) async {
    final ReportFormData? current = state.dataOrNull;
    if (current == null) return false;

    final ResultOf<CapturedImage?> captureResult = fromCamera
        ? await _cameraService.captureFromCamera()
        : await _cameraService.pickFromGallery();

    final CapturedImage? image = captureResult.getOrNull();
    if (image == null) return false;

    final ReportFormData afterCapture = state.dataOrNull ?? current;
    emit(ReportFormReady(afterCapture.copyWith(isUploadingPhoto: true)));

    final ResultOf<String> uploadResult = await _photoStorageService.uploadPhoto(
      bytes: image.bytes,
      companyId: current.currentUser.companyId,
      projectId: current.project.id,
      relatedEntityId: current.report.id,
      originalFileName: image.fileName,
      contentType: image.mimeType,
    );

    final String? storagePath = uploadResult.getOrNull();
    if (storagePath == null) {
      final ReportFormData latest = state.dataOrNull ?? afterCapture;
      emit(ReportFormReady(latest.copyWith(isUploadingPhoto: false)));
      return false;
    }

    final DateTime now = DateTime.now();
    final SitePhoto photo = SitePhoto(
      id: IdGenerator.v4(),
      companyId: current.currentUser.companyId,
      projectId: current.project.id,
      relatedEntityType: RelatedEntityType.fieldReport,
      relatedEntityId: current.report.id,
      storagePath: storagePath,
      takenAt: now,
      createdAt: now,
      uploadedBy: current.currentUser.userId,
    );

    final ResultOf<SitePhoto> saveResult = await _photoRepository.uploadPhoto(photo);

    final ReportFormData latest = state.dataOrNull ?? afterCapture;
    return saveResult.fold(
      (Failure _) {
        emit(ReportFormReady(latest.copyWith(isUploadingPhoto: false)));
        return false;
      },
      (SitePhoto saved) {
        emit(
          ReportFormReady(
            latest.copyWith(
              photos: <SitePhoto>[...latest.photos, saved],
              isUploadingPhoto: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  /// يحذف صورة مرفقة (ملف + سجل معاً) — `report_photo_attach.dart`.
  Future<bool> removePhoto(String photoId) async {
    final ReportFormData? current = state.dataOrNull;
    if (current == null) return false;

    final ResultOf<void> result = await _photoRepository.deletePhoto(photoId);

    return result.fold(
      (Failure _) => false,
      (_) {
        final ReportFormData latest = state.dataOrNull ?? current;
        emit(
          ReportFormReady(
            latest.copyWith(
              photos: latest.photos.where((SitePhoto p) => p.id != photoId).toList(growable: false),
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── توقيع رقمي ثم تقديم (`report_signature_screen.dart`) ─────────

  /// يرفع توقيع المشرف (إلزامي) وتوقيع العميل (اختياري) عبر
  /// [SignatureStorageService]، يستدعي [SignReportUsecase] لربطهما
  /// بالتقرير، ثم [SubmitReportUsecase] مباشرة (`draft` → `submitted`)
  /// — استدعاء واحد يغلّف تسلسل "توقيع ثم تقديم" الموصوف في مواصفة
  /// هذه الميزة بالكامل. يُعيد `true`/`false` بنفس أسلوب بقية دوال هذا
  /// الـ Cubit؛ عند الفشل، تبقى المسوّدة كما هي (لا حالة وسيطة معلَّقة).
  Future<bool> signAndSubmit({
    required Uint8List supervisorSignatureBytes,
    Uint8List? clientSignatureBytes,
  }) async {
    final ReportFormData? current = state.dataOrNull;
    if (current == null) return false;

    // آخر حفظ فوري قبل التقديم — يضمن أن كل حقول النموذج (بما فيها أي
    // تعديل لم يُحفَظ بعد بسبب مهلة الحفظ التلقائي) مُثبَّتة أولاً.
    final bool draftSaved = await saveNow();
    if (!draftSaved) return false;

    final ReportFormData afterSave = state.dataOrNull ?? current;
    emit(ReportFormReady(afterSave.copyWith(isSigningAndSubmitting: true)));

    final ResultOf<String> supervisorUpload = await _signatureStorageService.uploadSignature(
      bytes: supervisorSignatureBytes,
      companyId: current.currentUser.companyId,
      projectId: current.project.id,
      reportId: current.report.id,
      signerRole: 'supervisor',
    );

    final String? supervisorUrl = supervisorUpload.getOrNull();
    if (supervisorUrl == null) {
      _resetSigningFlag();
      return false;
    }

    String? clientUrl;
    if (clientSignatureBytes != null && clientSignatureBytes.isNotEmpty) {
      final ResultOf<String> clientUpload = await _signatureStorageService.uploadSignature(
        bytes: clientSignatureBytes,
        companyId: current.currentUser.companyId,
        projectId: current.project.id,
        reportId: current.report.id,
        signerRole: 'client',
      );
      clientUrl = clientUpload.getOrNull();
    }

    final ResultOf<FieldReport> signResult = await _signReportUsecase(
      reportId: current.report.id,
      supervisorSignatureUrl: supervisorUrl,
      clientSignatureUrl: clientUrl,
    );

    final FieldReport? signedReport = signResult.getOrNull();
    if (signedReport == null) {
      _resetSigningFlag();
      return false;
    }

    final ResultOf<FieldReport> submitResult = await _submitReportUsecase(signedReport);

    return submitResult.fold(
      (Failure _) {
        _resetSigningFlag();
        return false;
      },
      (FieldReport submitted) {
        final ReportFormData latest = state.dataOrNull ?? afterSave;
        emit(
          ReportFormReady(
            latest.copyWith(report: submitted, isSigningAndSubmitting: false),
          ),
        );
        return true;
      },
    );
  }

  void _resetSigningFlag() {
    final ReportFormData? latest = state.dataOrNull;
    if (latest == null) return;
    emit(ReportFormReady(latest.copyWith(isSigningAndSubmitting: false)));
  }

  // ── كل تقاريري / مسوّداتي ──────────────────────────────────────────

  /// يجلب كل تقارير المستخدم الحالي ضمن [ReportFormData.project] —
  /// `my_reports_screen.dart` (كل الحالات) و`report_drafts_screen.dart`
  /// (عبر [ReportFormData.draftReports] المُشتقّة). يُصفّي محلياً حسب
  /// `createdBy` لأن `GetProjectReportsUsecase` يُعيد كل تقارير المشروع
  /// (مفيدة أيضاً لاحقاً لدور مشرف يراجع فريقه دون نطاق `field_reports/`
  /// الإداري الكامل الموجود على سطح المكتب فقط اليوم).
  Future<void> loadMyReports() async {
    final ReportFormData? current = state.dataOrNull;
    if (current == null) return;

    emit(ReportFormReady(current.copyWith(isMyReportsLoading: true)));

    final ResultOf<List<FieldReport>> result = await _getProjectReportsUsecase(current.project.id);

    final ReportFormData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) => emit(ReportFormReady(latest.copyWith(isMyReportsLoading: false))),
      (List<FieldReport> reports) => emit(
        ReportFormReady(
          latest.copyWith(
            myReports: reports
                .where((FieldReport r) => r.createdBy == current.currentUser.userId)
                .toList(growable: false),
            isMyReportsLoading: false,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
