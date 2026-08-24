import 'dart:typed_data';

import '../errors/failure.dart';

/// نتيجة اختيار ملف واحد من الجهاز.
class PickedFile {
  const PickedFile({
    required this.bytes,
    required this.fileName,
    required this.sizeBytes,
    this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final int sizeBytes;
  final String? mimeType;
}

/// واجهة خدمة اختيار الملفات العامة (مستندات PDF/Word/Excel وغيرها)،
/// مستقلة عن [CameraService] المخصصة للصور تحديداً. تُستخدم من
/// `features/documents/` (Prompt 21).
///
/// ⚠️ نسخة Interface لهذه الخطوة، بلا تنفيذ فعلي بعد (سيُبنى فوق
/// `file_picker` أو ما يعادلها المتوافق مع الويب).
abstract class FilePickerService {
  /// يفتح منتقي ملفات مقيّداً بالامتدادات المسموحة، أو بلا قيود إن
  /// تُرك [allowedExtensions] فارغاً.
  Future<ResultOf<PickedFile?>> pickSingle({
    List<String> allowedExtensions = const <String>[],
  });

  Future<ResultOf<List<PickedFile>>> pickMultiple({
    List<String> allowedExtensions = const <String>[],
  });
}
