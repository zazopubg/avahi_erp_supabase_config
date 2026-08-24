import 'dart:typed_data';

import '../errors/failure.dart';

/// واجهة خدمة الطباعة، تُستخدم أساساً لطباعة تقارير ميدانية (Prompt
/// 17) أو مستندات مُصدَّرة كـ PDF (`documents`، Prompt 21) مباشرة من
/// المتصفح عبر واجهة الطباعة الأصلية له.
///
/// ⚠️ نسخة Interface لهذه الخطوة، بلا تنفيذ فعلي بعد.
abstract class PrintService {
  /// يطبع مستند PDF جاهز (بايتات خام) عبر واجهة طباعة المتصفح.
  Future<ResultOf<void>> printPdfBytes(Uint8List pdfBytes);

  /// يطبع عنصر HTML/Widget مُعدّ مسبقاً كـ Snapshot (يُستخدم لاحقاً
  /// عند الحاجة لطباعة محتوى واجهة مباشرة دون توليد PDF أولاً).
  Future<ResultOf<void>> printHtmlContent(String htmlContent);
}
