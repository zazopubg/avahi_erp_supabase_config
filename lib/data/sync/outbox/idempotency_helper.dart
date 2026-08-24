import '../../../core/utils/id_generator.dart';
import '../../local/local_database.dart' show OutboxEntryRow;

/// أداة مساعدة لمنع ازدواجية عمليات الطابور (`local_outbox`، Prompt
/// 08) عند إعادة محاولة كتابة محلية لم تصل بعد نتيجتها من طبقة
/// العرض/Cubit (مثال: ضغط زر "حفظ" مرتين بسرعة أثناء انقطاع الاتصال).
///
/// الاعتماد هنا على `clientMutationId` وليس `entityId` وحده، لأن نفس
/// الكيان قد يكون له أكثر من عملية معلّقة شرعية متتالية (مثال: تعديل
/// ثم تعديل آخر لاحقاً على نفس المهمة)، بينما التكرار غير المرغوب هو
/// إعادة إرسال *نفس* عملية الكتابة بعينها.
abstract final class IdempotencyHelper {
  /// يولّد معرّف idempotency جديد لعملية كتابة محلية جديدة (يُخزَّن مع
  /// السجل المحلي نفسه، انظر عمود `clientMutationId` في جداول
  /// `data/local/tables/`).
  static String newMutationId() => IdGenerator.v4();

  /// هل توجد عملية معلّقة سابقة في [existingEntries] (نتيجة
  /// `OutboxDao.getByEntity`) بنفس [clientMutationId]؟ إن كانت
  /// الإجابة نعم، فمحاولة الإضافة الحالية هي تكرار يجب تجاهله بدل
  /// وضعه في الطابور مجدداً.
  static bool isDuplicate(
    List<OutboxEntryRow> existingEntries,
    String clientMutationId,
  ) {
    return existingEntries.any(
      (OutboxEntryRow entry) => entry.clientMutationId == clientMutationId,
    );
  }
}
