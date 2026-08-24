import '../../domain/entities/task.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_status.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.tasks` (انظر `005_create_tasks.sql`).
class TaskDto {
  const TaskDto({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.title,
    required this.status,
    required this.priority,
    required this.kanbanOrder,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.assignedTo,
    this.createdBy,
    this.dueDate,
    this.completedAt,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? assignedTo;
  final String? createdBy;
  final DateTime? dueDate;
  final int kanbanOrder;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TaskDto.fromJson(Map<String, dynamic> json) {
    return TaskDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      assignedTo: json['assigned_to'] as String?,
      createdBy: json['created_by'] as String?,
      dueDate: parseNullableDateTime(json['due_date']),
      kanbanOrder: parseNullableInt(json['kanban_order']) ?? 0,
      completedAt: parseNullableDateTime(json['completed_at']),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'due_date': toNullableDateOnlyString(dueDate),
      'kanban_order': kanbanOrder,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج (بدون `id`/`created_at`/`updated_at`).
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'due_date': toNullableDateOnlyString(dueDate),
      'kanban_order': kanbanOrder,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Task toEntity() {
    return Task(
      id: id,
      companyId: companyId,
      projectId: projectId,
      title: title,
      description: description,
      status: TaskStatus.fromDbValue(status),
      priority: TaskPriority.fromDbValue(priority),
      assignedTo: assignedTo,
      createdBy: createdBy,
      dueDate: dueDate,
      kanbanOrder: kanbanOrder,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory TaskDto.fromEntity(Task entity) {
    return TaskDto(
      id: entity.id,
      companyId: entity.companyId,
      projectId: entity.projectId,
      title: entity.title,
      description: entity.description,
      status: entity.status.dbValue,
      priority: entity.priority.dbValue,
      assignedTo: entity.assignedTo,
      createdBy: entity.createdBy,
      dueDate: entity.dueDate,
      kanbanOrder: entity.kanbanOrder,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
