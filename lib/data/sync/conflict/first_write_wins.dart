import 'conflict_resolver.dart';

/// محلل تعارض "الكتابة الأولى تفوز" — **إلزامي** لجدول الحضور
/// (`attendance`, انظر `backend/supabase/migrations/006_create_attendance.sql`
/// و`domain/validators/` الخاصة بالحضور، Prompt 06).
///
/// المنطق: أول سجل حضور/انصراف يصل فعلياً إلى الخادم هو المرجع
/// الرسمي دائماً، بصرف النظر عن ترتيب وصول عمليات المزامنة لاحقاً
/// (مثال: جهاز عمل دون اتصال لساعات ثم أرسل تسجيل حضور مؤرَّخ قبل
/// تسجيل آخر وصل فعلياً للخادم أولاً). هذا يمنع تلاعباً محتملاً
/// بسجلات الحضور بعد فوات الأوان، ويطابق قيد `attendance_client_
/// mutation_id_unique` على مستوى قاعدة البيانات (`SupabaseErrorMapper`،
/// Prompt 07) كخط دفاع ثانٍ على مستوى الخادم.
///
/// المقارنة تعتمد على `created_at` (وقت الإنشاء الفعلي) وليس
/// `updated_at`، لأن سجل الحضور بطبيعته لا يجب أن يُعدَّل بعد إنشائه —
/// أي "تعارض" عليه هو عملياً تنافس بين نسختين مختلفتين لنفس الحدث.
class FirstWriteWinsResolver extends ConflictResolver {
  const FirstWriteWinsResolver();

  @override
  ConflictResolution resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    final DateTime? localCreatedAt = conflictTimestamp(local, 'created_at');
    final DateTime? remoteCreatedAt = conflictTimestamp(remote, 'created_at');

    // تعذّر تحديد الأسبقية الزمنية بثقة → السلامة أولى: يبقى ما وصل
    // فعلاً إلى الخادم (السحابة) كما هو، ولا تُفرَض الكتابة المحلية.
    if (localCreatedAt == null || remoteCreatedAt == null) {
      return const ConflictResolution(outcome: ConflictOutcome.keepRemote);
    }

    return localCreatedAt.isBefore(remoteCreatedAt)
        ? const ConflictResolution(outcome: ConflictOutcome.keepLocal)
        : const ConflictResolution(outcome: ConflictOutcome.keepRemote);
  }
}
