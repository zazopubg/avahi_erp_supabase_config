/// حالة مزامنة أي سجل محلي (Offline-first) ضمن آلية الـ Outbox التي
/// ستُبنى لاحقاً في Prompt 09 (`lib/data/sync/`). هذا التعداد Dart
/// نقي بحت ولا يقابله عمود مباشر في Postgres (المصدر السحابي دائماً
/// "متزامن" بحكم التعريف)؛ يُستخدم فقط على الجهاز لتتبّع حالة كل
/// سجل محلي (Drift، Prompt 08) قبل/أثناء/بعد إرساله للسحابة.
enum SyncState {
  /// أُنشئ محلياً ولم تتم محاولة إرساله للسحابة بعد.
  pending,

  /// عملية الإرسال جارية حالياً.
  syncing,

  /// تمت مزامنته بنجاح ويطابق نسخة السحابة.
  synced,

  /// فشلت آخر محاولة إرسال (سيُعاد المحاولة عبر `retry` policy).
  failed,

  /// تعارض بين النسخة المحلية والسحابية يتطلب حلاً (Conflict
  /// Resolution)، انظر `lib/data/sync/conflict/`.
  conflict;

  bool get isPending => this == SyncState.pending;
  bool get isSyncing => this == SyncState.syncing;
  bool get isSynced => this == SyncState.synced;
  bool get isFailed => this == SyncState.failed;
  bool get isConflict => this == SyncState.conflict;

  /// صحيح لأي حالة تتطلب انتباه/إجراء من المستخدم أو من نظام
  /// المزامنة (كل شيء عدا "متزامن بنجاح").
  bool get needsAttention => this != SyncState.synced;
}
