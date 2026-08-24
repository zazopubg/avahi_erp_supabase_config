/// حاسبة التأخير التصاعدي (Exponential Backoff) الموحّدة لكل إعادة
/// محاولة مزامنة فاشلة: 1 ثانية → 2 → 4 → 8 ... حتى سقف 5 دقائق، ثم
/// تبقى ثابتة عند السقف لأي عدد محاولات إضافي (بدل الاستمرار في
/// التضاعف إلى قيم غير عملية).
///
/// دالة نقيّة بحتة (Pure) بلا حالة داخلية — يُغذّيها `retry_policy.dart`
/// بعدد المحاولات الحالي فقط، وهو ما يُخزَّن أصلاً في عمود
/// `OutboxTable.retryCount` (`data/local/tables/outbox_table.dart`،
/// Prompt 08) دون الحاجة لأي عدّاد إضافي هنا.
abstract final class ExponentialBackoff {
  static const Duration baseDelay = Duration(seconds: 1);
  static const Duration maxDelay = Duration(minutes: 5);

  /// التأخير المطلوب قبل المحاولة رقم [retryCount] (تبدأ من 1 للمحاولة
  /// الأولى بعد الفشل الأصلي). [retryCount] صفر أو أقل يعني "لا تأخير"
  /// (المحاولة الأولى قبل أي فشل سابق).
  static Duration delayFor(int retryCount) {
    if (retryCount <= 0) return Duration.zero;

    // 2^(retryCount-1) بالثواني: 1→1s, 2→2s, 3→4s, 4→8s...
    // `clamp` يمنع فيضان (Overflow) القيمة الصحيحة لعدد محاولات كبير
    // جداً قبل حتى مقارنتها بالسقف.
    final int exponent = (retryCount - 1).clamp(0, 20);
    final int delayMs = baseDelay.inMilliseconds * (1 << exponent);
    final Duration delay = Duration(milliseconds: delayMs);

    return delay > maxDelay ? maxDelay : delay;
  }
}
