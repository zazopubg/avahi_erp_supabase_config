import 'dart:typed_data';

import '../errors/failure.dart';

/// نتيجة التقاط صورة واحدة.
class CapturedImage {
  const CapturedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

/// واجهة خدمة الكاميرا/معرض الصور، مبنية فوق `image_picker` (يدعم
/// الويب عبر واجهة اختيار ملفات المتصفح). تُستخدم من
/// `features/field_reports/` و`features/photos/` (Prompt 17/18).
///
/// ⚠️ نسخة Interface لهذه الخطوة، بلا تنفيذ فعلي بعد.
abstract class CameraService {
  /// يفتح كاميرا الجهاز (إن كانت متاحة على المتصفح) لالتقاط صورة.
  Future<ResultOf<CapturedImage?>> captureFromCamera();

  /// يفتح منتقي الملفات لاختيار صورة موجودة من الجهاز.
  Future<ResultOf<CapturedImage?>> pickFromGallery();

  /// يفتح منتقي الملفات لاختيار عدة صور دفعة واحدة.
  Future<ResultOf<List<CapturedImage>>> pickMultipleFromGallery();
}
