import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/site_photo.dart';
import '../../../../domain/enums/related_entity_type.dart';
import 'upload_queue_state.dart';

/// بادئة هاشتاغ ثابتة تُميّز الوسوم (Tags) المُدمَجة داخل نص
/// [SitePhoto.caption] — انظر توثيق القرار الكامل في `PhotoQueueTable`
/// (`data/local/tables/photo_queue_table.dart`) حول غياب عمود وسوم
/// مخصص في مخطط `public.photos` السحابي.
const String _kTagPrefix = '#';

/// حالة `features/photos/` الكلية — نمط `sealed`/`when` نفسه المعتمد
/// أصلاً في `features/tasks/presentation/state/tasks_state.dart`
/// (Prompt 16).
sealed class PhotosState extends Equatable {
  const PhotosState();

  T when<T>({
    required T Function() loading,
    required T Function(PhotosData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final PhotosState self = this;
    return switch (self) {
      PhotosLoading() => loading(),
      PhotosLoaded(:final PhotosData data) => loaded(data),
      PhotosError(:final Failure failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(PhotosData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    final PhotosState self = this;
    return switch (self) {
      PhotosLoading() => loading?.call() ?? orElse(),
      PhotosLoaded(:final PhotosData data) => loaded?.call(data) ?? orElse(),
      PhotosError(:final Failure failure) => error?.call(failure) ?? orElse(),
    };
  }
}

class PhotosLoading extends PhotosState {
  const PhotosLoading();

  @override
  List<Object?> get props => const <Object?>[];
}

class PhotosLoaded extends PhotosState {
  const PhotosLoaded(this.data);

  final PhotosData data;

  @override
  List<Object?> get props => <Object?>[data];
}

class PhotosError extends PhotosState {
  const PhotosError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}

/// وسم تصنيفي جاهز واحد لاختيار سريع في `photo_tag_selector.dart` —
/// قائمة ثابتة (وليست من قاعدة البيانات، تماشياً مع عدم وجود عمود
/// وسوم فعلي، انظر توثيق `PhotoQueueTable`) لكنها بديهية لطبيعة عمل
/// ميداني/إنشائي.
const List<String> kAvailablePhotoTags = <String>[
  'سلامة',
  'جودة',
  'تقدم العمل',
  'عيب',
  'خرسانة',
  'كهرباء',
  'سباكة',
  'تشطيبات',
  'معدات',
  'قبل',
  'بعد',
];

/// الحمولة الفعلية عند اكتمال التحميل — يُدير **معاً** (بالتوازي، كما
/// طُلب صراحة في مهمة Prompt 18) كلاً من: قائمة الصور المحمَّلة فعلياً
/// من السحابة (أو الطابور المحلي حسب الفلتر)، وحالة طابور الرفع
/// [UploadQueueState] الحية.
class PhotosData extends Equatable {
  const PhotosData({
    required this.currentUser,
    required this.project,
    required this.uploadQueue,
    this.photos = const <SitePhoto>[],
    this.selectedPhoto,
    this.filterEntityType,
    this.filterUploadedByMeOnly = false,
    this.searchQuery = '',
    this.isRefreshing = false,
    this.isCapturing = false,
  });

  final AppUser currentUser;
  final Project project;

  /// حالة طابور الرفع المحلي — انظر `upload_queue_state.dart`.
  final UploadQueueState uploadQueue;

  /// الصور المحمَّلة فعلياً من `IPhotoRepository.getPhotosForProject`
  /// (بحسب الفلاتر الحالية أدناه) — **لا تشمل** عناصر [uploadQueue]
  /// التي لم تُرفَع بعد؛ `photo_grid.dart` يعرض القائمتين معاً بصرياً
  /// (صور مؤكدة + صور "جارٍ رفعها" بشارة تمييز واضحة) لكن كمصدرين
  /// منفصلين تماماً في الحالة، تماشياً مع فصل [PhotosData]/[UploadQueueState].
  final List<SitePhoto> photos;

  /// الصورة المختارة حالياً لعرض تفاصيلها — `photo_details_panel.dart`
  /// (سطح المكتب) أو `photo_viewer.dart` (تكبير كامل الشاشة، الجوال
  /// والديسكتاوب معاً).
  final SitePhoto? selectedPhoto;

  /// فلتر نوع الكيان الحالي (`null` = كل الأنواع) — تبويبات
  /// `photo_gallery.dart` على سطح المكتب.
  final RelatedEntityType? filterEntityType;

  /// `true` يقيّد العرض لصور المستخدم الحالي فقط — الوضع الافتراضي
  /// الفعلي في `my_photos_screen.dart` على الجوال.
  final bool filterUploadedByMeOnly;

  /// نص بحث حر يُطابَق مقابل [SitePhoto.caption] (بعد استبعاد الوسوم
  /// المُدمَجة عبر [captionTextOf]) — فلترة جانب العميل بحتة (لا يوجد
  /// بحث نصي كامل على مستوى Supabase لهذه الميزة).
  final String searchQuery;

  final bool isRefreshing;

  /// `true` أثناء تنفيذ تدفّق الالتقاط الكامل (فتح الكاميرا → ضغط →
  /// إدراج في الطابور) — يعرض مؤشر تحميل صريح في `camera_screen.dart`.
  final bool isCapturing;

  /// يستخرج الوسوم (Tags) المُدمَجة داخل بداية [SitePhoto.caption] —
  /// انظر توثيق القرار في `PhotoQueueTable`. مثال: `#سلامة #جودة ملاحظة
  /// حول الأساسات` → `['سلامة', 'جودة']`.
  static List<String> tagsOf(SitePhoto photo) {
    final String? caption = photo.caption;
    if (caption == null || !caption.trimLeft().startsWith(_kTagPrefix)) {
      return const <String>[];
    }
    final List<String> tags = <String>[];
    for (final String word in caption.trim().split(RegExp(r'\s+'))) {
      if (!word.startsWith(_kTagPrefix)) break;
      final String tag = word.substring(_kTagPrefix.length);
      if (tag.isNotEmpty) tags.add(tag);
    }
    return tags;
  }

  /// نص التعليق الفعلي بعد استبعاد بادئة الوسوم — ما يُعرَض فعلياً
  /// كتعليق نصي في `photo_details_panel.dart`/`photo_viewer.dart`.
  static String captionTextOf(SitePhoto photo) {
    final String? caption = photo.caption;
    if (caption == null) return '';
    final List<String> tags = tagsOf(photo);
    if (tags.isEmpty) return caption.trim();
    // نحذف كل كلمة-وسم من البداية فقط (بنفس منطق [tagsOf]).
    final List<String> words = caption.trim().split(RegExp(r'\s+'));
    return words.skip(tags.length).join(' ').trim();
  }

  /// يبني نص [SitePhoto.caption] النهائي من وسوم + نص تعليق حر —
  /// عكس [tagsOf]/[captionTextOf] معاً، تُستدعى من `PhotosCubit` عند
  /// الالتقاط/التعديل.
  static String buildCaption({
    required List<String> tags,
    required String captionText,
  }) {
    final String tagsPart =
        tags.map((String t) => '$_kTagPrefix$t').join(' ');
    if (tagsPart.isEmpty) return captionText.trim();
    if (captionText.trim().isEmpty) return tagsPart;
    return '$tagsPart ${captionText.trim()}';
  }

  /// الصور بعد تطبيق كل الفلاتر الحالية (نوع كيان + "صوري فقط" + بحث)
  /// — القائمة الفعلية المعروضة في `photo_grid.dart`.
  List<SitePhoto> get filteredPhotos {
    Iterable<SitePhoto> result = photos;

    if (filterEntityType != null) {
      result = result.where(
        (SitePhoto p) => p.relatedEntityType == filterEntityType,
      );
    }
    if (filterUploadedByMeOnly) {
      result = result.where((SitePhoto p) => p.uploadedBy == currentUser.userId);
    }
    if (searchQuery.trim().isNotEmpty) {
      final String query = searchQuery.trim().toLowerCase();
      result = result.where((SitePhoto p) {
        final String caption = captionTextOf(p).toLowerCase();
        final bool tagMatch = tagsOf(p).any(
          (String t) => t.toLowerCase().contains(query),
        );
        return caption.contains(query) || tagMatch;
      });
    }
    return result.toList(growable: false);
  }

  PhotosData copyWith({
    AppUser? currentUser,
    Project? project,
    UploadQueueState? uploadQueue,
    List<SitePhoto>? photos,
    SitePhoto? selectedPhoto,
    bool clearSelectedPhoto = false,
    RelatedEntityType? filterEntityType,
    bool clearFilterEntityType = false,
    bool? filterUploadedByMeOnly,
    String? searchQuery,
    bool? isRefreshing,
    bool? isCapturing,
  }) {
    return PhotosData(
      currentUser: currentUser ?? this.currentUser,
      project: project ?? this.project,
      uploadQueue: uploadQueue ?? this.uploadQueue,
      photos: photos ?? this.photos,
      selectedPhoto:
          clearSelectedPhoto ? null : (selectedPhoto ?? this.selectedPhoto),
      filterEntityType: clearFilterEntityType
          ? null
          : (filterEntityType ?? this.filterEntityType),
      filterUploadedByMeOnly: filterUploadedByMeOnly ?? this.filterUploadedByMeOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCapturing: isCapturing ?? this.isCapturing,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        currentUser,
        project,
        uploadQueue,
        photos,
        selectedPhoto,
        filterEntityType,
        filterUploadedByMeOnly,
        searchQuery,
        isRefreshing,
        isCapturing,
      ];
}
