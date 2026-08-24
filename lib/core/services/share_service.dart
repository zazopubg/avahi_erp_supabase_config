import 'dart:typed_data';

import '../errors/failure.dart';

/// واجهة خدمة مشاركة المحتوى (نص، رابط، أو ملف) عبر واجهة المشاركة
/// الأصلية للمتصفح (Web Share API عند توفرها) أو نسخ إلى الحافظة
/// كخيار احتياطي. تُستخدم من عدة وحدات (تقارير، صور، مستندات).
///
/// ⚠️ نسخة Interface لهذه الخطوة، بلا تنفيذ فعلي بعد.
abstract class ShareService {
  Future<ResultOf<void>> shareText(String text, {String? subject});

  Future<ResultOf<void>> shareFile({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    String? subject,
  });
}
