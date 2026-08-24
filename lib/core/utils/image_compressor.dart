import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// نتيجة عملية ضغط صورة واحدة.
class CompressedImageResult {
  const CompressedImageResult({
    required this.bytes,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final int width;
  final int height;

  /// نسبة التوفير في الحجم بعد الضغط (0.0 - 1.0).
  double get savedRatio => originalSizeBytes == 0
      ? 0
      : 1 - (compressedSizeBytes / originalSizeBytes);
}

/// واجهة ضغط الصور قبل رفعها إلى `photos` bucket (Prompt 18)، لتقليل
/// استهلاك البيانات وتسريع الرفع في مواقع العمل ضعيفة التغطية.
abstract class ImageCompressor {
  /// يضغط بايتات صورة خام إلى حجم/جودة مناسبين للرفع.
  ///
  /// [maxWidth]/[maxHeight] يحدّان الأبعاد القصوى بعد إعادة التحجيم،
  /// و[quality] بين 0-100 يتحكم بجودة ضغط JPEG/WebP الناتج.
  Future<CompressedImageResult> compress(
    Uint8List sourceBytes, {
    int maxWidth = 1600,
    int maxHeight = 1600,
    int quality = 80,
  });
}

/// تنفيذ مؤقت يُعيد البايتات الأصلية دون أي ضغط فعلي — يبقى مُعرَّفاً
/// هنا (منذ Prompt 02) لتوافقية أي اختبار/سياق مستقبلي يحتاج تنفيذاً
/// وهمياً صريحاً بلا أي اعتماد على حزمة `image`، لكنه **لم يعد**
/// التنفيذ المسجَّل فعلياً في `core/di/core_module.dart` بدءاً من
/// Prompt 18 — انظر [ImagePackageCompressor] أدناه.
class NoopImageCompressor implements ImageCompressor {
  const NoopImageCompressor();

  @override
  Future<CompressedImageResult> compress(
    Uint8List sourceBytes, {
    int maxWidth = 1600,
    int maxHeight = 1600,
    int quality = 80,
  }) async {
    return CompressedImageResult(
      bytes: sourceBytes,
      originalSizeBytes: sourceBytes.lengthInBytes,
      compressedSizeBytes: sourceBytes.lengthInBytes,
      width: 0,
      height: 0,
    );
  }
}

/// 🆕 (Prompt 18) أول تنفيذ فعلي لـ [ImageCompressor] — فوق حزمة
/// `image` (Dart خالص، تعمل على الويب دون أي اعتماد على مكتبات نظام
/// تشغيل أصلية، خلافاً لـ `flutter_image_compress` المذكورة سابقاً في
/// تعليق Prompt 02 كخيار محتمل، والتي تتطلب قنوات منصّة أصلية غير
/// متاحة على هدف الويب الحالي للمشروع). يعيد ترميز أي صورة (JPEG/PNG/
/// WebP...) إلى JPEG موحّد بعد تحجيمها لأقصى بُعد مسموح، محافظاً على
/// نسبة العرض للارتفاع.
///
/// ⚠️ تنفيذ متزامن (Synchronous) عمداً بلا `compute()`/Isolate: حزمة
/// `dart:isolate` غير مدعومة على الويب، و`compute()` نفسها تتراجع إلى
/// تنفيذ متزامن هناك أصلاً — تفادياً لتعقيد غير مجدٍ. بالنسبة لحجم صور
/// كاميرا هاتف نموذجي (بضعة ميغابايتات) يبقى زمن الضغط ضمن حدود
/// مقبولة لتجربة مستخدم متزامنة (يُعرض مؤشر تحميل صريح في
/// `camera_screen.dart` طوال هذه العملية على أي حال).
class ImagePackageCompressor implements ImageCompressor {
  const ImagePackageCompressor();

  @override
  Future<CompressedImageResult> compress(
    Uint8List sourceBytes, {
    int maxWidth = 1600,
    int maxHeight = 1600,
    int quality = 80,
  }) async {
    final int originalSize = sourceBytes.lengthInBytes;
    final img.Image? decoded = img.decodeImage(sourceBytes);

    // فشل فك الترميز (صيغة غير مدعومة/بيانات تالفة) — نُعيد البايتات
    // الأصلية كما هي بدل رمي استثناء يوقف كامل تدفّق الالتقاط؛
    // `PhotoStorageService` سيحاول رفعها كما وردت، والفشل الفعلي (إن
    // وُجد) يُعالَج لاحقاً بمنطق إعادة المحاولة القياسي في
    // `PhotoUploadProcessor`.
    if (decoded == null) {
      return CompressedImageResult(
        bytes: sourceBytes,
        originalSizeBytes: originalSize,
        compressedSizeBytes: originalSize,
        width: 0,
        height: 0,
      );
    }

    final bool needsResize = decoded.width > maxWidth || decoded.height > maxHeight;
    final img.Image resized = !needsResize
        ? decoded
        : (decoded.width >= decoded.height
            ? img.copyResize(decoded, width: maxWidth)
            : img.copyResize(decoded, height: maxHeight));

    final Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(resized, quality: quality.clamp(1, 100)),
    );

    return CompressedImageResult(
      bytes: encoded,
      originalSizeBytes: originalSize,
      compressedSizeBytes: encoded.lengthInBytes,
      width: resized.width,
      height: resized.height,
    );
  }
}
