import '../../core/utils/id_generator.dart';

/// يبني مسارات ملفات Supabase Storage بشكل موحّد ومتوقّع عبر كل خدمات
/// `data/storage/`، بالصيغة المطلوبة صراحة في هذه الخطوة:
/// `/companies/{cid}/projects/{pid}/...`.
///
/// ⚠️ المسارات هنا **لا** تبدأ بشرطة مائلة `/` فعلياً (رغم ورودها هكذا
/// في وصف المهمة) لأن Supabase Storage تتعامل مع المسارات كمفاتيح
/// نسبية داخل الـ Bucket (`bucket.upload('companies/x/...', ...)`)،
/// وشرطة بادئة قد تُنشئ مجلداً فارغاً باسم مضلِّل في بعض عملاء S3
/// المتوافقين. القيمة المنطقية (البنية الهرمية) مطابقة تماماً للمطلوب.
abstract final class StoragePathBuilder {
  /// يستخرج الامتداد من اسم ملف (بدون النقطة)، أو نص فارغ إن لم يوجد.
  static String _extensionOf(String fileName) {
    final int dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  /// اسم ملف فريد يحافظ على الامتداد الأصلي، لتفادي أي تعارض تسمية
  /// عند رفع ملفين بنفس الاسم من مستخدمين مختلفين في نفس اللحظة.
  static String _uniqueFileName(String originalFileName) {
    final String ext = _extensionOf(originalFileName);
    final String id = IdGenerator.v4();
    return ext.isEmpty ? id : '$id.$ext';
  }

  /// مسار صورة موقع مرتبطة بكيان (تقرير/عنصر ملاحظات/مهمة...) ضمن
  /// مشروع: `companies/{cid}/projects/{pid}/photos/{relatedEntityId}/{uuid}.ext`.
  static String photoPath({
    required String companyId,
    required String projectId,
    required String relatedEntityId,
    required String originalFileName,
  }) {
    return 'companies/$companyId/projects/$projectId/photos/'
        '$relatedEntityId/${_uniqueFileName(originalFileName)}';
  }

  /// مسار صورة مصغّرة (Thumbnail) مطابق لصورة أصل، بنفس مجلد الصورة
  /// الأصلية مع بادئة `thumb_`.
  static String photoThumbnailPath(String originalPhotoPath) {
    final int lastSlash = originalPhotoPath.lastIndexOf('/');
    final String dir = lastSlash == -1 ? '' : originalPhotoPath.substring(0, lastSlash + 1);
    final String fileName =
        lastSlash == -1 ? originalPhotoPath : originalPhotoPath.substring(lastSlash + 1);
    return '${dir}thumb_$fileName';
  }

  /// مسار مستند رسمي: إن وُجد [projectId] يُخزَّن ضمن مجلد المشروع،
  /// وإلا يُعتبر مستنداً عاماً على مستوى الشركة
  /// (`companies/{cid}/documents/...`).
  static String documentPath({
    required String companyId,
    required String originalFileName,
    String? projectId,
  }) {
    final String base = projectId == null
        ? 'companies/$companyId/documents'
        : 'companies/$companyId/projects/$projectId/documents';
    return '$base/${_uniqueFileName(originalFileName)}';
  }

  /// مسار توقيع رقمي (مشرف أو عميل) مرتبط بتقرير ميداني ضمن مشروع:
  /// `companies/{cid}/projects/{pid}/reports/{reportId}/signatures/{role}_{uuid}.ext`.
  static String signaturePath({
    required String companyId,
    required String projectId,
    required String reportId,
    required String signerRole,
    String originalFileName = 'signature.png',
  }) {
    final String ext = _extensionOf(originalFileName).isEmpty
        ? 'png'
        : _extensionOf(originalFileName);
    return 'companies/$companyId/projects/$projectId/reports/$reportId/'
        'signatures/${signerRole}_${IdGenerator.v4()}.$ext';
  }

  /// مسار الصورة الرمزية (Avatar) لعضو شركة:
  /// `companies/{cid}/avatars/{userId}.ext`. يُثبَّت الاسم على
  /// `userId` عمداً (وليس UUID عشوائياً) بحيث يستبدل الرفع الجديد
  /// القديم تلقائياً بدل تكديس صور رمزية يتيمة.
  static String avatarPath({
    required String companyId,
    required String userId,
    required String originalFileName,
  }) {
    final String ext = _extensionOf(originalFileName).isEmpty
        ? 'jpg'
        : _extensionOf(originalFileName);
    return 'companies/$companyId/avatars/$userId.$ext';
  }
}
