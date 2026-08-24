import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/document.dart';
import '../../../../domain/entities/project.dart';

/// حزمة تصنيفات المستندات الثابتة (Categories) — قائمة مغلقة (وليست
/// من قاعدة البيانات، بنفس منطق `kAvailablePhotoTags` في
/// `features/photos/presentation/state/photos_state.dart`) تُستخدم في
/// `document_categories.dart` (سطح المكتب) وفلتر التصنيف في كل من
/// `documents_manager.dart`/`documents_list.dart`. [Document.category]
/// نفسه نص حر تماماً (`domain/entities/document.dart`)، لذا هذه مجرد
/// قيم مقترحة موحّدة عبر الواجهة، وليست تعداداً (`enum`) ملزماً على
/// مستوى قاعدة البيانات.
const List<String> kDocumentCategories = <String>[
  'مخططات هندسية',
  'عقود',
  'تقارير',
  'مواصفات فنية',
  'تصاريح',
  'فواتير',
  'أخرى',
];

/// قيمة مميِّزة (Sentinel) لفلتر النطاق [DocumentsData.scopeFilter] —
/// تعني "مستندات الشركة العامة فقط" (`projectId == null` عند استدعاء
/// [IDocumentRepository.getDocuments]، انظر `i_document_repository.dart`)،
/// بخلاف `null` نفسها التي تعني هنا "الكل" (كل المستندات، الشركة +
/// كل المشاريع معاً) — تمييز ضروري لأن `null` وحدها لا تكفي للتعبير عن
/// حالتين مختلفتين (لا فلتر إطلاقاً / فلتر على النطاق العام تحديداً).
const String kDocumentScopeCompanyWide = '__company__';

/// حالة `DocumentsCubit` الكاملة — Union Type مكتوب يدوياً، بنفس نمط
/// `PunchState`/`TasksState` تماماً (بلا `freezed`، ثلاث حالات فقط).
sealed class DocumentsState {
  const DocumentsState();

  T when<T>({
    required T Function() loading,
    required T Function(DocumentsData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final DocumentsState state = this;
    return switch (state) {
      DocumentsLoading() => loading(),
      DocumentsLoaded(:final data) => loaded(data),
      DocumentsError(:final failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(DocumentsData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [DocumentsData] الحالية إن كانت الحالة [DocumentsLoaded]، أو
  /// `null` — مختصر مفيد للشاشات، بنفس نمط `PunchState.dataOrNull`.
  DocumentsData? get dataOrNull => maybeWhen<DocumentsData?>(
        orElse: () => null,
        loaded: (DocumentsData d) => d,
      );
}

/// جارٍ التحميل الأولي (مشاريع المستخدم + مستندات النطاق الافتراضي
/// "الكل").
final class DocumentsLoading extends DocumentsState {
  const DocumentsLoading();
}

/// جاهزة لعرض كل شاشات الميزة (`documents_list.dart` على الهاتف،
/// `documents_manager.dart`/`document_viewer.dart`/`document_categories.dart`
/// على سطح المكتب) — الفرق بينها بصري بحت حسب `ShellMode`، بنفس فلسفة
/// `ProjectsCubit`/`PunchCubit`.
final class DocumentsLoaded extends DocumentsState {
  const DocumentsLoaded(this.data);

  final DocumentsData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً — يعتمد `Retry` في الشاشة
/// لإعادة `DocumentsCubit.loadInitial`.
final class DocumentsError extends DocumentsState {
  const DocumentsError(this.failure);

  final Failure failure;
}

/// حزمة بيانات ميزة المستندات المجمّعة — يحملها [DocumentsLoaded] وحدها.
class DocumentsData {
  const DocumentsData({
    required this.currentUser,
    this.myProjects = const <Project>[],
    this.projectsById = const <String, Project>{},
    this.documents = const <Document>[],
    this.isDocumentsLoading = false,
    this.scopeFilter,
    this.categoryFilter,
    this.searchQuery = '',
    this.includeArchived = false,
    this.selectedDocument,
    this.isUploading = false,
  });

  final AppUser currentUser;

  /// كل مشاريع المستخدم — تغذّي قائمة اختيار النطاق في
  /// `documents_manager.dart` (فلتر "مشروع محدد") ونموذج الرفع (اختيار
  /// المشروع المرتبط بالمستند الجديد، أو تركه فارغاً لمستند عام على
  /// مستوى الشركة).
  final List<Project> myProjects;
  final Map<String, Project> projectsById;

  /// المستندات المُحمَّلة فعلياً بحسب [scopeFilter] الحالي (قبل تطبيق
  /// [categoryFilter]/[searchQuery]/[includeArchived] — انظر
  /// [filteredDocuments]).
  final List<Document> documents;
  final bool isDocumentsLoading;

  /// فلتر النطاق الحالي: `null` = الكل (الشركة + كل المشاريع معاً)،
  /// [kDocumentScopeCompanyWide] = مستندات الشركة العامة فقط، أو معرّف
  /// مشروع محدد ضمن [myProjects] — انظر توثيق القرار الكامل أعلى
  /// [kDocumentScopeCompanyWide].
  final String? scopeFilter;

  /// فلتر تصنيف اختياري ([kDocumentCategories]) — `null` يعني كل
  /// التصنيفات.
  final String? categoryFilter;

  /// نص بحث حر يُطابَق مقابل [Document.title]/[Document.description] —
  /// فلترة جانب العميل بحتة، بنفس منطق `PhotosData.searchQuery`.
  final String searchQuery;

  /// `true` يُظهر المستندات المؤرشفة أيضاً ضمن [filteredDocuments]
  /// (افتراضياً مخفية) — يعتمدها زر تبديل في `documents_manager.dart`
  /// فقط (لا معنى له في `documents_list.dart` عرض الهاتف).
  final bool includeArchived;

  /// المستند المختار حالياً لعرض تفاصيله/معاينته — `document_viewer.dart`
  /// (سطح المكتب، كلوحة جانبية أو عبر `/documents/:id`).
  final Document? selectedDocument;

  /// عملية رفع جارية حالياً — `documents_manager.dart`.
  final bool isUploading;

  bool get hasActiveFilters =>
      categoryFilter != null || searchQuery.trim().isNotEmpty;

  /// [documents] بعد تطبيق كل الفلاتر الحالية — القائمة الفعلية
  /// المعروضة في `documents_manager.dart`/`documents_list.dart`.
  List<Document> get filteredDocuments {
    Iterable<Document> result = documents;

    if (!includeArchived) {
      result = result.where((Document d) => !d.isArchived);
    }
    if (categoryFilter != null) {
      result = result.where((Document d) => d.category == categoryFilter);
    }
    if (searchQuery.trim().isNotEmpty) {
      final String query = searchQuery.trim().toLowerCase();
      result = result.where((Document d) {
        final bool titleMatch = d.title.toLowerCase().contains(query);
        final bool descMatch =
            d.description?.toLowerCase().contains(query) ?? false;
        return titleMatch || descMatch;
      });
    }

    return result.toList(growable: false)
      ..sort((Document a, Document b) => b.createdAt.compareTo(a.createdAt));
  }

  /// يُجمِّع [filteredDocuments] حسب [Document.category] (`'بلا تصنيف'`
  /// لما لا يحمل تصنيفاً) — أساس `document_categories.dart`.
  Map<String, List<Document>> get documentsByCategory {
    final Map<String, List<Document>> grouped = <String, List<Document>>{};
    for (final Document doc in filteredDocuments) {
      final String key = doc.category ?? 'بلا تصنيف';
      grouped.putIfAbsent(key, () => <Document>[]).add(doc);
    }
    return grouped;
  }

  DocumentsData copyWith({
    AppUser? currentUser,
    List<Project>? myProjects,
    Map<String, Project>? projectsById,
    List<Document>? documents,
    bool? isDocumentsLoading,
    String? scopeFilter,
    bool clearScopeFilter = false,
    String? categoryFilter,
    bool clearCategoryFilter = false,
    String? searchQuery,
    bool? includeArchived,
    Document? selectedDocument,
    bool clearSelectedDocument = false,
    bool? isUploading,
  }) {
    return DocumentsData(
      currentUser: currentUser ?? this.currentUser,
      myProjects: myProjects ?? this.myProjects,
      projectsById: projectsById ?? this.projectsById,
      documents: documents ?? this.documents,
      isDocumentsLoading: isDocumentsLoading ?? this.isDocumentsLoading,
      scopeFilter:
          clearScopeFilter ? null : (scopeFilter ?? this.scopeFilter),
      categoryFilter: clearCategoryFilter
          ? null
          : (categoryFilter ?? this.categoryFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      includeArchived: includeArchived ?? this.includeArchived,
      selectedDocument: clearSelectedDocument
          ? null
          : (selectedDocument ?? this.selectedDocument),
      isUploading: isUploading ?? this.isUploading,
    );
  }
}
