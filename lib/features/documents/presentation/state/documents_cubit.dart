import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../../core/utils/file_helper.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../data/storage/document_storage_service.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/document.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/usecases/documents/archive_document_usecase.dart';
import '../../../../domain/usecases/documents/get_document_by_id_usecase.dart';
import '../../../../domain/usecases/documents/get_documents_usecase.dart';
import '../../../../domain/usecases/documents/upload_document_usecase.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import 'documents_state.dart';

/// `Cubit` ميزة `features/documents/` (Prompt 21) — يقود كل شاشات
/// الميزة معاً (`documents_list.dart` على الهاتف — عرض فقط،
/// `documents_manager.dart`/`document_viewer.dart`/`document_categories.dart`
/// على سطح المكتب) عبر [DocumentsData] واحدة مجمّعة، بنفس فلسفة
/// `PunchCubit`/`ProjectsCubit`.
///
/// ⚠️ قرار تصميم جوهري: بخلاف `features/photos/` (طابور رفع محلي
/// Offline-first كامل عبر `PhotoDao`/`SyncEngine`/`OutboxQueue`)، طبقة
/// `data/` المبنية مسبقاً لهذه الميزة (`IDocumentRepository` +
/// `DocumentRepositoryImpl` السحابي الخالص، Prompt 07) **لا تملك أي**
/// جدول محلي (Drift) أو مسار Outbox مخصّص لها — لا يوجد `document_dao.dart`
/// ولا `document_queue_table.dart` ضمن `data/local/` أصلاً. الرفع/الأرشفة
/// هنا عمليتان مباشرتان عبر الشبكة دائماً (بنفس أسلوب `PunchCubit`
/// الموثَّق هناك)، مع تحديثات تفاؤلية على القائمة المحلية للـ `Cubit`
/// فقط بعد تأكيد الخادم — يتطابق هذا تماماً مع طبيعة المستندات نفسها
/// (ملفات رسمية يجب أن يعكس كل تعديل عليها حالة الخادم الفعلية فوراً،
/// لا معنى لـ"مستند معلّق محلياً" بلا اتصال).
///
/// ⚠️ قرار تصميم ثانٍ (تجميع النطاق "الكل"): [IDocumentRepository.getDocuments]
/// يستقبل `projectId` واحداً فقط لكل استدعاء (مستندات مشروع واحد، أو
/// مستندات الشركة العامة عبر `projectId == null` — لا يوجد أي
/// UseCase/استعلام "كل مستندات الشركة عبر كل المشاريع دفعة واحدة" في
/// طبقة `domain/`). فلتر النطاق الافتراضي "الكل" ([DocumentsData.scopeFilter]
/// == `null`) يُنفَّذ إذن عبر استدعاء منفصل لكل نطاق (الشركة + كل
/// مشروع من [DocumentsData.myProjects]) ثم دمج النتائج — بالضبط نفس
/// نمط `PunchCubit.loadDashboard` الموثَّق هناك حرفياً.
class DocumentsCubit extends Cubit<DocumentsState> {
  DocumentsCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required GetDocumentsUsecase getDocumentsUsecase,
    required GetDocumentByIdUsecase getDocumentByIdUsecase,
    required UploadDocumentUsecase uploadDocumentUsecase,
    required ArchiveDocumentUsecase archiveDocumentUsecase,
    required DocumentStorageService documentStorageService,
    required FilePickerService filePickerService,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _getDocumentsUsecase = getDocumentsUsecase,
        _getDocumentByIdUsecase = getDocumentByIdUsecase,
        _uploadDocumentUsecase = uploadDocumentUsecase,
        _archiveDocumentUsecase = archiveDocumentUsecase,
        _documentStorageService = documentStorageService,
        _filePickerService = filePickerService,
        super(const DocumentsLoading());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final GetDocumentsUsecase _getDocumentsUsecase;
  final GetDocumentByIdUsecase _getDocumentByIdUsecase;
  final UploadDocumentUsecase _uploadDocumentUsecase;
  final ArchiveDocumentUsecase _archiveDocumentUsecase;
  final DocumentStorageService _documentStorageService;
  final FilePickerService _filePickerService;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى عند دخول `documents_list.dart` (الهاتف) أو
  /// `documents_manager.dart` (سطح المكتب) — يجلب مشاريع المستخدم ثم
  /// مستندات النطاق الافتراضي "الكل" (انظر توثيق القرار الكامل أعلى
  /// الصنف).
  Future<void> loadInitial(AppUser user) async {
    emit(const DocumentsLoading());

    final ResultOf<List<Project>> projectsResult = await _getMyProjectsUsecase(
      user.userId,
    );
    final List<Project> projects = projectsResult.fold(
      (Failure _) => const <Project>[],
      (List<Project> p) => p,
    );
    final Map<String, Project> projectsById = <String, Project>{
      for (final Project p in projects) p.id: p,
    };

    final List<Document> documents = await _fetchDocumentsForScope(
      scope: null,
      projects: projects,
    );

    emit(
      DocumentsLoaded(
        DocumentsData(
          currentUser: user,
          myProjects: projects,
          projectsById: projectsById,
          documents: documents,
        ),
      ),
    );
  }

  /// يجلب مستندات [scope] الحالي: `null` = الكل (استدعاء مستندات
  /// الشركة العامة + استدعاء مستقل لكل مشروع ضمن [projects]، ثم دمج
  /// النتائج)، [kDocumentScopeCompanyWide] = مستندات الشركة العامة
  /// فقط، أو معرّف مشروع محدد.
  Future<List<Document>> _fetchDocumentsForScope({
    required String? scope,
    required List<Project> projects,
  }) async {
    if (scope == kDocumentScopeCompanyWide) {
      return _fetchDocuments();
    }
    if (scope != null) {
      return _fetchDocuments(projectId: scope);
    }

    // النطاق "الكل": مستندات الشركة العامة + مستندات كل مشروع، مُجمَّعة.
    final List<Document> all = <Document>[];
    all.addAll(await _fetchDocuments());
    for (final Project project in projects) {
      all.addAll(await _fetchDocuments(projectId: project.id));
    }
    return all;
  }

  Future<List<Document>> _fetchDocuments({String? projectId}) async {
    final ResultOf<List<Document>> result = await _getDocumentsUsecase(
      projectId: projectId,
    );
    return result.fold((Failure _) => const <Document>[], (List<Document> d) => d);
  }

  /// يعيد تحميل [DocumentsData.documents] فقط بحسب [DocumentsData.scopeFilter]
  /// الحالي — سحب للتحديث في `documents_manager.dart`/`documents_list.dart`.
  Future<void> refresh() async {
    final DocumentsData? current = state.dataOrNull;
    if (current == null) return;

    emit(DocumentsLoaded(current.copyWith(isDocumentsLoading: true)));
    final List<Document> documents = await _fetchDocumentsForScope(
      scope: current.scopeFilter,
      projects: current.myProjects,
    );
    final DocumentsData latest = state.dataOrNull ?? current;
    emit(
      DocumentsLoaded(
        latest.copyWith(documents: documents, isDocumentsLoading: false),
      ),
    );
  }

  /// يُستدعى عند الدخول المباشر (Deep Link) لمسار `/documents/:id`
  /// دون المرور أولاً بـ [loadInitial] — يجلب المستخدم الحالي مسبقاً
  /// من `AuthCubit` (المستدعي، `document_viewer.dart`) ويجلب المستند
  /// المطلوب مباشرة عبر [GetDocumentByIdUsecase] بلا تحميل بقية
  /// المستندات/المشاريع.
  Future<void> loadSingleDocument({
    required AppUser user,
    required String documentId,
  }) async {
    emit(const DocumentsLoading());

    final ResultOf<Document> result = await _getDocumentByIdUsecase(documentId);

    result.fold(
      (Failure failure) => emit(DocumentsError(failure)),
      (Document document) => emit(
        DocumentsLoaded(
          DocumentsData(
            currentUser: user,
            documents: <Document>[document],
            selectedDocument: document,
          ),
        ),
      ),
    );
  }

  // ── فلاتر العرض ─────────────────────────────────────────────────

  /// يغيّر فلتر النطاق ويُعيد جلب [DocumentsData.documents] بحسبه —
  /// قائمة اختيار النطاق في `documents_manager.dart` (سطح المكتب
  /// فقط؛ `documents_list.dart` الهاتف يبقى دوماً على النطاق
  /// الافتراضي "الكل").
  Future<void> setScopeFilter(String? scope) async {
    final DocumentsData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      DocumentsLoaded(
        current.copyWith(
          scopeFilter: scope,
          clearScopeFilter: scope == null,
          isDocumentsLoading: true,
        ),
      ),
    );
    final List<Document> documents = await _fetchDocumentsForScope(
      scope: scope,
      projects: current.myProjects,
    );
    final DocumentsData latest = state.dataOrNull ?? current;
    emit(
      DocumentsLoaded(
        latest.copyWith(documents: documents, isDocumentsLoading: false),
      ),
    );
  }

  void setCategoryFilter(String? category) {
    final DocumentsData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      DocumentsLoaded(
        category == null
            ? current.copyWith(clearCategoryFilter: true)
            : current.copyWith(categoryFilter: category),
      ),
    );
  }

  void setSearchQuery(String query) {
    final DocumentsData? current = state.dataOrNull;
    if (current == null) return;
    emit(DocumentsLoaded(current.copyWith(searchQuery: query)));
  }

  void setIncludeArchived(bool value) {
    final DocumentsData? current = state.dataOrNull;
    if (current == null) return;
    emit(DocumentsLoaded(current.copyWith(includeArchived: value)));
  }

  void selectDocument(Document? document) {
    final DocumentsData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      DocumentsLoaded(
        document == null
            ? current.copyWith(clearSelectedDocument: true)
            : current.copyWith(selectedDocument: document),
      ),
    );
  }

  // ── الرفع (`documents_manager.dart`، سطح المكتب فقط) ─────────────

  /// يفتح منتقي ملفات مقيَّداً بامتدادات المستندات المدعومة
  /// ([AppConstants.supportedDocumentExtensions]) — الخطوة الأولى من
  /// تدفّق الرفع، تستدعيها `documents_manager.dart` مباشرة قبل
  /// [uploadPickedFile].
  Future<PickedFile?> pickDocumentFile() async {
    final ResultOf<PickedFile?> result = await _filePickerService.pickSingle(
      allowedExtensions: AppConstants.supportedDocumentExtensions,
    );
    return result.getOrNull();
  }

  /// يرفع [file] المُختار عبر [pickDocumentFile] كمستند جديد تماماً
  /// (`version = 1`، بلا `previousVersionId`) مرتبط اختيارياً بمشروع
  /// [projectId] (`null` = مستند عام على مستوى الشركة). يُعيد
  /// [Document] الناتج عند النجاح، أو `null` عند فشل أي خطوة (تجاوز
  /// الحجم الأقصى، فشل الرفع الفعلي للتخزين، أو فشل حفظ الصف الوصفي).
  Future<Document?> uploadPickedFile({
    required PickedFile file,
    String? projectId,
    String? category,
    String? description,
  }) {
    return _uploadInternal(
      file: file,
      projectId: projectId,
      category: category,
      description: description,
      title: FileHelper.baseNameOf(file.fileName),
      version: 1,
      previousVersionId: null,
    );
  }

  /// يرفع [file] كإصدار جديد (Version Bump) لمستند [previousVersion]
  /// قائم — نفس العنوان/التصنيف/المشروع، `version` مُزادة بواحد،
  /// و[Document.previousVersionId] يشير للإصدار السابق. يؤرشف الإصدار
  /// السابق تلقائياً عند نجاح رفع الجديد (انظر توثيق [Document.previousVersionId]
  /// في `domain/entities/document.dart` — "دعم أرشفة وإصدارات بسيطة").
  Future<Document?> uploadNewVersion({
    required Document previousVersion,
    required PickedFile file,
  }) async {
    final Document? uploaded = await _uploadInternal(
      file: file,
      projectId: previousVersion.projectId,
      category: previousVersion.category,
      description: previousVersion.description,
      title: previousVersion.title,
      version: previousVersion.version + 1,
      previousVersionId: previousVersion.id,
    );

    if (uploaded == null) return null;

    // أرشفة الإصدار السابق — لا تُفشل عملية الرفع نفسها إن فشلت
    // الأرشفة وحدها (الإصدار الجديد أُنشئ بنجاح فعلياً بهذه المرحلة).
    await archiveDocument(previousVersion);

    return uploaded;
  }

  Future<Document?> _uploadInternal({
    required PickedFile file,
    required String title,
    required int version,
    required String? previousVersionId,
    String? projectId,
    String? category,
    String? description,
  }) async {
    final DocumentsData? current = state.dataOrNull;
    if (current == null) return null;

    if (!FileHelper.isWithinSizeLimit(file.sizeBytes)) {
      return null;
    }

    emit(DocumentsLoaded(current.copyWith(isUploading: true)));

    final ResultOf<String> uploadResult = await _documentStorageService.uploadDocument(
      bytes: file.bytes,
      companyId: current.currentUser.companyId,
      projectId: projectId,
      originalFileName: file.fileName,
      contentType: file.mimeType ?? 'application/octet-stream',
    );

    final String? storagePath = uploadResult.getOrNull();
    if (storagePath == null) {
      final DocumentsData latest = state.dataOrNull ?? current;
      emit(DocumentsLoaded(latest.copyWith(isUploading: false)));
      return null;
    }

    final DateTime now = DateTime.now().toUtc();
    final Document document = Document(
      id: IdGenerator.v4(),
      companyId: current.currentUser.companyId,
      projectId: projectId,
      title: title,
      description: description,
      category: category,
      storagePath: storagePath,
      fileType: FileHelper.extensionOf(file.fileName),
      fileSizeBytes: file.sizeBytes,
      version: version,
      previousVersionId: previousVersionId,
      isArchived: false,
      uploadedBy: current.currentUser.userId,
      createdAt: now,
      updatedAt: now,
    );

    final ResultOf<Document> result = await _uploadDocumentUsecase(document);

    final DocumentsData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(DocumentsLoaded(latest.copyWith(isUploading: false)));
        return null;
      },
      (Document created) {
        emit(
          DocumentsLoaded(
            latest.copyWith(
              documents: <Document>[created, ...latest.documents],
              isUploading: false,
            ),
          ),
        );
        return created;
      },
    );
  }

  // ── أرشفة (`documents_manager.dart`) ──────────────────────────────

  /// يؤرشف [document] (`isArchived = true`، بلا حذف فعلي للملف —
  /// انظر توثيق [IDocumentRepository.archiveDocument]). يُطبَّق تحديث
  /// تفاؤلي فوري على القائمة المحلية عند نجاح الاستدعاء. يُعيد `true`
  /// عند النجاح.
  Future<bool> archiveDocument(Document document) async {
    final ResultOf<void> result = await _archiveDocumentUsecase(document.id);
    final bool success = result.fold((Failure _) => false, (_) => true);
    if (!success) return false;

    final DocumentsData? current = state.dataOrNull;
    if (current != null) {
      final Document archived = document.copyWith(isArchived: true);
      emit(
        DocumentsLoaded(
          current.copyWith(
            documents: current.documents
                .map((Document d) => d.id == document.id ? archived : d)
                .toList(growable: false),
            selectedDocument: current.selectedDocument?.id == document.id
                ? archived
                : current.selectedDocument,
          ),
        ),
      );
    }
    return true;
  }

  // ── معاينة/تنزيل (`document_viewer.dart` + `documents_list.dart`) ─

  /// يولّد رابطاً موقّعاً مؤقتاً لمعاينة/تنزيل [document] — يُستدعى من
  /// `document_viewer.dart` (سطح المكتب) و`documents_list.dart`
  /// (الهاتف، زر "فتح"/"تنزيل" فقط، بلا أي رفع — انظر توثيق القرار في
  /// `documents_list.dart` نفسها).
  Future<String?> getPreviewUrl(Document document) async {
    final ResultOf<String> result = await _documentStorageService.getSignedUrl(
      document.storagePath,
    );
    return result.getOrNull();
  }
}
