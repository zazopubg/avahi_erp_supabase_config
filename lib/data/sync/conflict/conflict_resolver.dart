import '../../dto/dto_parsing_helpers.dart' show parseNullableDateTime;

/// نتيجة حسم تعارض بين نسخة محلية ونسخة سحابية لنفس السجل.
enum ConflictOutcome {
  /// النسخة المحلية هي الصحيحة — تُفرَض على السحابة (Force overwrite).
  keepLocal,

  /// النسخة السحابية هي الصحيحة — تُستبدَل بها النسخة المحلية وتُهمَل
  /// الكتابة المحلية المعلّقة.
  keepRemote,

  /// لا يمكن حسم التعارض تلقائياً؛ يبقى السجل بحالة
  /// `SyncState.conflict` بانتظار تدخّل بشري (واجهة حلّ تعارضات
  /// مستقبلية).
  needsManual,
}

/// نتيجة [ConflictResolver.resolve] الكاملة، مع إمكانية إرفاق حمولة
/// مدموجة (Merge) بدل اختيار نسخة كاملة كما هي — غير مستخدم حالياً من
/// أي محلل مبني في هذه الخطوة لكنه متاح لمحللات مستقبلية أكثر دقة
/// (مثال: دمج حقلي `notes` من الجهتين بدل استبعاد أحدهما بالكامل).
class ConflictResolution {
  const ConflictResolution({required this.outcome, this.mergedPayload});

  final ConflictOutcome outcome;
  final Map<String, dynamic>? mergedPayload;
}

/// الواجهة الموحّدة لكل محللات التعارض في `data/sync/conflict/`.
/// [OutboxProcessor] (`outbox/outbox_processor.dart`) يختار المحلل
/// المناسب بحسب `entityType` (مثال: [FirstWriteWinsResolver] لجدول
/// الحضور، [LastWriteWinsResolver] للمهام) عند اكتشاف تعارض فعلي —
/// انظر `OutboxRemoteWriter._isGenuineConflict`.
abstract class ConflictResolver {
  const ConflictResolver();

  /// [local] و[remote] حمولتا JSON بصيغة `snake_case` مطابقة لبنية
  /// جداول Supabase (نفس ما يُنتجه `*Dto.toJson()`/تُعيده استعلامات
  /// PostgREST مباشرة).
  ConflictResolution resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  });
}

/// يقرأ حقل طابع زمني (`created_at`/`updated_at`) من حمولة JSON بأمان،
/// بإعادة استخدام نفس منطق تحويل التواريخ الموحّد في `data/dto/`
/// (Prompt 07) بدل تكراره هنا.
DateTime? conflictTimestamp(Map<String, dynamic> payload, String key) =>
    parseNullableDateTime(payload[key]);
