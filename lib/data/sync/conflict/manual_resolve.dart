import 'conflict_resolver.dart';

/// محلل تعارض "بلا حسم تلقائي" — للكيانات الحساسة التي لا يجوز فيها
/// اختيار نسخة تلقائياً دون مراجعة بشرية (مثال مرشّح مستقبلي: طلبات
/// الإجازة `leave_requests` بعد اعتمادها، أو تعديلات مالية إن أُضيفت
/// لاحقاً — هذه الخطوة لا تُلزم به أي `entityType` بعينه، بل تتيحه
/// كخيار صريح لطبقة `data/repositories_impl/`، Prompt 10، عند تسجيل
/// محللات كل كيان).
///
/// عند استخدامه، يُترَك السجل بحالة `SyncState.conflict` (انظر
/// `LocalSyncStateWriter.markConflict` في `outbox/outbox_processor.dart`)
/// وتبقى عملية الطابور قائمة (لا تُحذَف) بانتظار واجهة حلّ تعارضات
/// مستقبلية تسمح للمستخدم باختيار النسخة الصحيحة صراحة.
class ManualResolveConflictResolver extends ConflictResolver {
  const ManualResolveConflictResolver();

  @override
  ConflictResolution resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    return const ConflictResolution(outcome: ConflictOutcome.needsManual);
  }
}
