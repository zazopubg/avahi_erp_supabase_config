import 'app_exception.dart';

/// استثناءات متعلقة بآلية المزامنة بين قاعدة البيانات المحلية
/// (Drift/Outbox، Prompt 08/09) وقاعدة البيانات السحابية (Supabase).
class SyncException extends AppException {
  const SyncException({
    required super.message,
    required super.code,
    super.cause,
    super.stackTrace,
    this.entityType,
    this.entityId,
  });

  /// نوع الكيان المتأثر (مثال: `field_report`, `attendance_record`).
  final String? entityType;

  /// معرّف الكيان المتأثر إن وُجد.
  final String? entityId;

  factory SyncException.conflict({
    String? entityType,
    String? entityId,
    Object? cause,
    StackTrace? st,
  }) =>
      SyncException(
        message: 'حدث تعارض بين نسخة محلية ونسخة سحابية للبيانات.',
        code: 'sync.conflict',
        entityType: entityType,
        entityId: entityId,
        cause: cause,
        stackTrace: st,
      );

  factory SyncException.retryExhausted({
    String? entityType,
    String? entityId,
    Object? cause,
    StackTrace? st,
  }) =>
      SyncException(
        message: 'فشلت المزامنة بعد عدة محاولات.',
        code: 'sync.retry_exhausted',
        entityType: entityType,
        entityId: entityId,
        cause: cause,
        stackTrace: st,
      );

  factory SyncException.queueCorrupted({Object? cause, StackTrace? st}) =>
      SyncException(
        message: 'حدث خلل في قائمة انتظار المزامنة المحلية.',
        code: 'sync.queue_corrupted',
        cause: cause,
        stackTrace: st,
      );

  bool get isConflict => code == 'sync.conflict';
}
