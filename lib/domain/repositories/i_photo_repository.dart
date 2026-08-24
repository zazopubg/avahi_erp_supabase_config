import '../../core/errors/failure.dart';
import '../entities/site_photo.dart';
import '../enums/related_entity_type.dart';

/// عقد الوصول إلى الصور المرفقة بأي كيان (`public.photos`).
abstract interface class IPhotoRepository {
  /// يرفع صورة جديدة (ملف الصورة نفسه تُديره `data/storage/`، وهذا
  /// العقد يتعامل فقط مع صف بيانات الصورة الوصفية بعد الرفع).
  Future<ResultOf<SitePhoto>> uploadPhoto(SitePhoto photo);

  /// يجلب كل الصور المرتبطة بكيان محدد (تقرير، عنصر ملاحظات، مهمة...).
  Future<ResultOf<List<SitePhoto>>> getPhotosForEntity({
    required RelatedEntityType relatedEntityType,
    required String relatedEntityId,
  });

  /// 🆕 (Prompt 18) يجلب كل صور مشروع محدد دفعة واحدة (عبر كل أنواع
  /// الكيانات المرتبطة معاً)، مع فلاتر اختيارية — أساس تصفّح
  /// `features/photos/` نفسها (`my_photos_screen.dart`/`photo_gallery.dart`)
  /// التي تحتاج عرضاً موحّداً "كل صور المشروع" بخلاف
  /// [getPhotosForEntity] المخصّصة لعرض صور كيان واحد بعينه فقط
  /// (مثال: صور مرفقة بتقرير ميداني محدد ضمن `report_form_screen.dart`).
  ///
  /// [relatedEntityType]: يقيّد النتيجة لنوع كيان واحد فقط
  /// (`photo_gallery.dart` عند اختيار تبويب تصفية معيّن)، أو `null`
  /// لكل الأنواع معاً.
  /// [uploadedBy]: يقيّد النتيجة لمصوّر واحد فقط
  /// (`my_photos_screen.dart` يمرّر `AppUser.userId` دوماً)، أو `null`
  /// لكل المصوّرين (عرض إداري في `photo_gallery.dart`).
  /// [limit]: سقف عدد النتائج (200 افتراضياً) لتفادي جلب آلاف الصور
  /// دفعة واحدة في مشروع طويل الأمد.
  Future<ResultOf<List<SitePhoto>>> getPhotosForProject({
    required String projectId,
    RelatedEntityType? relatedEntityType,
    String? uploadedBy,
    int limit = 200,
  });

  /// يحذف صورة (يحذف الملف من التخزين والسجل معاً).
  Future<ResultOf<void>> deletePhoto(String photoId);
}
