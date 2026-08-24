import '../constants/app_constants.dart';

/// تصنيف عام لنوع الملف بحسب امتداده، مفيد لاختيار الأيقونة المناسبة
/// في `lib/features/documents/` و`lib/features/photos/`.
enum FileKind { image, document, other }

/// مساعد عام للتعامل مع أسماء ومسارات ومقاسات الملفات، مستقل تماماً
/// عن أي واجهة اختيار ملفات فعلية (تلك مسؤولية `file_picker_service`).
abstract final class FileHelper {
  /// يستخرج الامتداد (بدون نقطة، بحروف صغيرة) من اسم ملف، أو سلسلة
  /// فارغة إن لم يوجد امتداد.
  static String extensionOf(String fileName) {
    final int dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  /// يستخرج اسم الملف بدون الامتداد.
  static String baseNameOf(String fileName) {
    final int dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) return fileName;
    return fileName.substring(0, dotIndex);
  }

  /// يصنّف الملف بحسب امتداده إلى [FileKind].
  static FileKind kindOf(String fileName) {
    final String ext = extensionOf(fileName);
    if (AppConstants.supportedImageExtensions.contains(ext)) {
      return FileKind.image;
    }
    if (AppConstants.supportedDocumentExtensions.contains(ext)) {
      return FileKind.document;
    }
    return FileKind.other;
  }

  /// يتحقق من أن حجم الملف (بالبايت) لا يتجاوز الحد الأقصى المسموح.
  static bool isWithinSizeLimit(
    int sizeBytes, {
    int maxBytes = AppConstants.maxUploadFileSizeBytes,
  }) {
    return sizeBytes <= maxBytes;
  }

  /// يبني اسم ملف فريداً (Slug) اعتماداً على الاسم الأصلي ومعرّف زمني،
  /// مفيد لتفادي تعارض الأسماء داخل Storage Buckets.
  static String uniqueStorageName(String originalFileName) {
    final String ext = extensionOf(originalFileName);
    final String base = _slugify(baseNameOf(originalFileName));
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    return ext.isEmpty ? '${base}_$timestamp' : '${base}_$timestamp.$ext';
  }

  static String _slugify(String input) {
    final String lower = input.trim().toLowerCase();
    final String replaced = lower.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '-');
    return replaced.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }
}
