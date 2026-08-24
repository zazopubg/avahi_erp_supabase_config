import 'conflict_resolver.dart';

/// محلل تعارض "الكتابة الأخيرة تفوز" — يُستخدم للمهام (`tasks`) ولكل
/// كيان لا تستدعي طبيعته حساسية خاصة تجاه ترتيب الكتابة (خلافاً
/// للحضور، انظر [FirstWriteWinsResolver] الإلزامي هناك).
///
/// المنطق قياسي (Optimistic Concurrency عبر `updated_at`): أياً كانت
/// النسخة (محلية أو سحابية) التي حُدِّثت زمنياً لاحقاً، فهي الأحدث
/// معرفياً وتُفرَض على الأخرى. هذا هو المحلل الافتراضي
/// ([OutboxProcessor]'s `defaultResolver`) لأي `entityType` لم يُسجَّل
/// له محلل مخصّص صراحة.
class LastWriteWinsResolver extends ConflictResolver {
  const LastWriteWinsResolver();

  @override
  ConflictResolution resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    final DateTime? localUpdatedAt = conflictTimestamp(local, 'updated_at');
    final DateTime? remoteUpdatedAt = conflictTimestamp(remote, 'updated_at');

    // تعذّر تحديد الأحدث بثقة → الافتراض الآمن الافتراضي: الإبقاء على
    // النسخة السحابية (المصدر الرسمي للحقيقة عند الشك).
    if (localUpdatedAt == null || remoteUpdatedAt == null) {
      return const ConflictResolution(outcome: ConflictOutcome.keepRemote);
    }

    return localUpdatedAt.isAfter(remoteUpdatedAt)
        ? const ConflictResolution(outcome: ConflictOutcome.keepLocal)
        : const ConflictResolution(outcome: ConflictOutcome.keepRemote);
  }
}
