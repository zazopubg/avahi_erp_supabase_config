import '../../domain/entities/punch_item.dart';
import '../../domain/enums/punch_status.dart';
import '../../domain/enums/task_priority.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.punch_items` (انظر
/// `008_create_punch_items.sql`).
class PunchItemDto {
  const PunchItemDto({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.fieldReportId,
    this.description,
    this.locationNote,
    this.assignedTo,
    this.createdBy,
    this.dueDate,
    this.resolvedAt,
    this.resolvedBy,
    this.closedAt,
    this.closedBy,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String? fieldReportId;
  final String title;
  final String? description;
  final String? locationNote;
  final String status;
  final String priority;
  final String? assignedTo;
  final String? createdBy;
  final DateTime? dueDate;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime? closedAt;
  final String? closedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PunchItemDto.fromJson(Map<String, dynamic> json) {
    return PunchItemDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      projectId: json['project_id'] as String,
      fieldReportId: json['field_report_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      locationNote: json['location_note'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      assignedTo: json['assigned_to'] as String?,
      createdBy: json['created_by'] as String?,
      dueDate: parseNullableDateTime(json['due_date']),
      resolvedAt: parseNullableDateTime(json['resolved_at']),
      resolvedBy: json['resolved_by'] as String?,
      closedAt: parseNullableDateTime(json['closed_at']),
      closedBy: json['closed_by'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'project_id': projectId,
      'field_report_id': fieldReportId,
      'title': title,
      'description': description,
      'location_note': locationNote,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'due_date': toNullableDateOnlyString(dueDate),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'closed_at': closedAt?.toIso8601String(),
      'closed_by': closedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج (بدون `id`/`created_at`/`updated_at`).
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'project_id': projectId,
      'field_report_id': fieldReportId,
      'title': title,
      'description': description,
      'location_note': locationNote,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'due_date': toNullableDateOnlyString(dueDate),
    };
  }

  PunchItem toEntity() {
    return PunchItem(
      id: id,
      companyId: companyId,
      projectId: projectId,
      fieldReportId: fieldReportId,
      title: title,
      description: description,
      locationNote: locationNote,
      status: PunchStatus.fromDbValue(status),
      priority: TaskPriority.fromDbValue(priority),
      assignedTo: assignedTo,
      createdBy: createdBy,
      dueDate: dueDate,
      resolvedAt: resolvedAt,
      resolvedBy: resolvedBy,
      closedAt: closedAt,
      closedBy: closedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory PunchItemDto.fromEntity(PunchItem entity) {
    return PunchItemDto(
      id: entity.id,
      companyId: entity.companyId,
      projectId: entity.projectId,
      fieldReportId: entity.fieldReportId,
      title: entity.title,
      description: entity.description,
      locationNote: entity.locationNote,
      status: entity.status.dbValue,
      priority: entity.priority.dbValue,
      assignedTo: entity.assignedTo,
      createdBy: entity.createdBy,
      dueDate: entity.dueDate,
      resolvedAt: entity.resolvedAt,
      resolvedBy: entity.resolvedBy,
      closedAt: entity.closedAt,
      closedBy: entity.closedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
