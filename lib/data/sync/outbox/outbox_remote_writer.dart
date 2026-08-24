import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../cloud/supabase/supabase_client_provider.dart';
import '../../cloud/supabase/supabase_error_mapper.dart';
import '../../dto/dto_parsing_helpers.dart' show parseNullableDateTime;
import 'outbox_queue.dart' show OutboxOperationType;

/// نتيجة محاولة إرسال عنصر طابور واحد إلى الخادم — إما نجاح تام أو
/// اكتشاف تعارض حقيقي يتطلّب تدخّل `data/sync/conflict/` (وليس
/// استثناءً، عمداً: التعارض حالة عمل متوقعة ضمن Offline-first، وليس
/// خللاً تقنياً يستحق مساراً استثنائياً).
sealed class OutboxPushResult {
  const OutboxPushResult();
}

class OutboxPushSuccess extends OutboxPushResult {
  const OutboxPushSuccess();
}

class OutboxPushConflict extends OutboxPushResult {
  const OutboxPushConflict(this.remotePayload);

  /// النسخة السحابية الحالية كاملة كما قُرئت وقت اكتشاف التعارض —
  /// تُمرَّر مباشرة إلى `ConflictResolver.resolve`.
  final Map<String, dynamic> remotePayload;
}

/// الواجهة التي يعتمد عليها [OutboxProcessor] لإرسال عملية واحدة إلى
/// الوجهة السحابية الفعلية — مفصولة عن التنفيذ الحقيقي عبر Supabase
/// لسهولة الاختبار (Unit Testing، Prompt 29) بتمرير تنفيذ وهمي.
abstract class OutboxRemoteWriter {
  Future<OutboxPushResult> push({
    required String entityType,
    required String entityId,
    required OutboxOperationType operation,
    required Map<String, dynamic> payload,
  });

  /// إرسال قسري (Force) يتجاوز أي فحص تعارض — يُستدعى فقط بعد أن يقرر
  /// `ConflictResolver` صراحة `ConflictOutcome.keepLocal`.
  Future<void> forcePush({
    required String entityType,
    required Map<String, dynamic> payload,
  });
}

/// التنفيذ الفعلي عبر عميل Supabase (PostgREST) مباشرة — **دون** المرور
/// بأي من `data/cloud/supabase/repositories/*_repository_impl.dart`.
/// تلك المستودعات ستُدمَج مع هذه الطبقة لاحقاً ضمن
/// `data/repositories_impl/` (Prompt 10)، ولا حاجة لانتظار ذلك: طالما
/// [entityType] هو نفسه اسم جدول Supabase (قيم `ApiConstants.table*`،
/// مثال: `tasks`, `attendance`, `field_reports`) و[payload] بصيغة JSON
/// جاهزة (نفس مخرجات `*Dto.toJson()`)، هذا التنفيذ عام ويعمل مع أي
/// كيان دون معرفة تفاصيله.
class SupabaseOutboxRemoteWriter implements OutboxRemoteWriter {
  SupabaseOutboxRemoteWriter({SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final SupabaseClient _client;

  @override
  Future<OutboxPushResult> push({
    required String entityType,
    required String entityId,
    required OutboxOperationType operation,
    required Map<String, dynamic> payload,
  }) async {
    try {
      if (operation == OutboxOperationType.delete) {
        // الحذف عملية Idempotent بطبيعتها: حذف سجل غير موجود أصلاً لا
        // يُعتبر خطأ (ربما وصلت عملية مزامنة سابقة له بالفعل).
        await _client.from(entityType).delete().eq('id', entityId);
        return const OutboxPushSuccess();
      }

      final Map<String, dynamic>? remote = await _client
          .from(entityType)
          .select()
          .eq('id', entityId)
          .maybeSingle();

      if (remote != null && _isGenuineConflict(local: payload, remote: remote)) {
        return OutboxPushConflict(remote);
      }

      await _client.from(entityType).upsert(payload);
      return const OutboxPushSuccess();
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw SupabaseErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> forcePush({
    required String entityType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _client.from(entityType).upsert(payload);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw SupabaseErrorMapper.map(error, stackTrace);
    }
  }

  /// تعارض *حقيقي* فقط إذا كانت النسخة السحابية أُحدِّثت لاحقاً من
  /// عميل آخر غير عملية الكتابة المحلية الحالية نفسها:
  /// - إن تطابق `client_mutation_id` بين النسختين (عند توفره) فهذا مجرد
  ///   صدى تأكيد كتابتنا نحن، وليس تعارضاً.
  /// - وإلا، تُقارَن `updated_at`: تعارض فقط إن كانت نسخة السحابة أحدث
  ///   زمنياً من النسخة التي بُنيت عليها الكتابة المحلية.
  bool _isGenuineConflict({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    final Object? localMutationId = local['client_mutation_id'];
    final Object? remoteMutationId = remote['client_mutation_id'];
    if (localMutationId != null && localMutationId == remoteMutationId) {
      return false;
    }

    final DateTime? localUpdatedAt = parseNullableDateTime(local['updated_at']);
    final DateTime? remoteUpdatedAt =
        parseNullableDateTime(remote['updated_at']);
    if (localUpdatedAt == null || remoteUpdatedAt == null) return false;

    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }
}
