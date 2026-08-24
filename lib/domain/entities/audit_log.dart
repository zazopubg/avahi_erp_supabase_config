import 'package:equatable/equatable.dart';

/// سجل تدقيق عام (Audit Trail)، للقراءة فقط، يُملأ تلقائياً عبر
/// triggers قاعدة البيانات (انظر `011_create_audit_logs.sql` و
/// `017_audit_triggers.sql`).
class AuditLog extends Equatable {
  const AuditLog({
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

  /// نوع العملية: `INSERT` / `UPDATE` / `DELETE`.
  final String action;

  /// اسم الجدول الذي طرأ عليه التغيير.
  final String tableName;

  final String? recordId;

  /// البيانات قبل التعديل (JSON)، فارغة عند `INSERT`.
  final Map<String, dynamic>? oldData;

  /// البيانات بعد التعديل (JSON)، فارغة عند `DELETE`.
  final Map<String, dynamic>? newData;

  final DateTime createdAt;

  AuditLog copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? action,
    String? tableName,
    String? recordId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      oldData: oldData ?? this.oldData,
      newData: newData ?? this.newData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        userId,
        action,
        tableName,
        recordId,
        oldData,
        newData,
        createdAt,
      ];
}
