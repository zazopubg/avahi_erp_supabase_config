import '../../../core/errors/failure.dart';
import 'exponential_backoff.dart';

/// تصنيف فشل معالجة عنصر طابور واحد بعد استنفاد كل معلومات الخطأ
/// المتاحة (`Failure`، انظر `core/errors/failure.dart`).
enum RetryVerdict {
  /// خطأ عابر (شبكي غالباً) — يستحق إعادة محاولة لاحقة بحسب
  /// [ExponentialBackoff].
  transient,

  /// خطأ دائم لا تُجدي معه إعادة المحاولة الفورية (مصادقة/صلاحيات/
  /// تحقق من صحة البيانات) — يبقى العنصر في الطابور لكن بمعدل فحص
  /// أبطأ بكثير (سقف التأخير)، بانتظار تدخّل خارجي (تسجيل دخول جديد،
  /// منح صلاحية، تصحيح بيانات من واجهة العرض).
  permanent,
}

class RetryDecision {
  const RetryDecision(this.verdict, this.delay);

  final RetryVerdict verdict;
  final Duration delay;

  bool get isPermanent => verdict == RetryVerdict.permanent;
}

/// السياسة الموحّدة لقرار "هل ومتى" تُعاد محاولة إرسال عنصر طابور
/// فاشل — يُستدعى حصراً من `outbox/outbox_processor.dart` عند كل فشل،
/// وقبل كل دورة معالجة لتحديد العناصر الجاهزة فعلياً.
abstract final class RetryPolicy {
  /// يصنّف [failure] إلى عابر أو دائم، ويُرفق تأخير [ExponentialBackoff]
  /// المناسب بحسب [retryCount] الحالي (قبل تسجيل هذه المحاولة الفاشلة
  /// نفسها، لذا التأخير المحسوب هنا يخص *المحاولة التالية*).
  static RetryDecision classify(Failure failure, int retryCount) {
    final bool isPermanent = failure is AuthFailure ||
        failure is PermissionFailure ||
        failure is ValidationFailure;

    if (isPermanent) {
      // لا فائدة من إعادة محاولة سريعة لخطأ لن يتغيّر خلال ثوانٍ؛
      // نُبقيها عند سقف التأخير مباشرة (فحص كل 5 دقائق كحد أقصى).
      return const RetryDecision(RetryVerdict.permanent, ExponentialBackoff.maxDelay);
    }

    return RetryDecision(
      RetryVerdict.transient,
      ExponentialBackoff.delayFor(retryCount + 1),
    );
  }

  /// هل حان وقت إعادة محاولة عنصر بحسب [retryCount] و[lastAttemptAt]
  /// المخزَّنين في `OutboxTable`؟ عنصر لم يُحاوَل بعد (`retryCount == 0`
  /// أو `lastAttemptAt == null`) جاهز دائماً.
  static bool isDueForRetry({
    required int retryCount,
    required DateTime? lastAttemptAt,
    DateTime? now,
  }) {
    if (retryCount <= 0 || lastAttemptAt == null) return true;

    final DateTime effectiveNow = now ?? DateTime.now().toUtc();
    final Duration requiredDelay = ExponentialBackoff.delayFor(retryCount);
    return !effectiveNow.isBefore(lastAttemptAt.add(requiredDelay));
  }
}
