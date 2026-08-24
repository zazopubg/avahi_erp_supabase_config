import '../../domain/entities/audit_log.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.audit_logs` (انظر
/// `011_create_audit_logs.sql`/`017_audit_triggers.sql`، Prompt 03)
/// بأسماء أعمدة `snake_case` الحرفية. 🆕 (Prompt 28) — أول استهلاك
/// فعلي له من `PlatformAdminRepositoryImpl.getAllAuditLogs`
/// (`audit_logs_viewer.dart`)؛ الجدول نفسه موجود منذ Prompt 03 لكن لا
/// طبقة `data/` استهلكته مباشرة قبل هذه الخطوة (يُملأ فقط تلقائياً عبر
/// DB triggers).
class AuditLogDto {
  const AuditLogDto({
    required this.id,
    required this.action,
    required this.tableName,
    required this.createdAt,
    this.companyId,
    this.userId,
    this.recordId,
    this.oldData,
    this.newData,
  });

  final String id;
  final String? companyId;
  final String? userId;
  final String action;
  final String tableName;
  final String? recordId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;

  factory AuditLogDto.fromJson(Map<String, dynamic> json) {
    return AuditLogDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      userId: json['user_id'] as String?,
      action: json['action'] as String,
      tableName: json['table_name'] as String,
      recordId: json['record_id'] as String?,
      oldData: (json['old_data'] as Map?)?.cast<String, dynamic>(),
      newData: (json['new_data'] as Map?)?.cast<String, dynamic>(),
      createdAt: parseDateTime(json['created_at']),
    );
  }

  AuditLog toEntity() {
    return AuditLog(
      id: id,
      companyId: companyId,
      userId: userId,
      action: action,
      tableName: tableName,
      recordId: recordId,
      oldData: oldData,
      newData: newData,
      createdAt: createdAt,
    );
  }
}
