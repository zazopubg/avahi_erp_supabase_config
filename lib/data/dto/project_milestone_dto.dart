import '../../domain/entities/project_milestone.dart';
import '../../domain/enums/milestone_status.dart';
import 'dto_parsing_helpers.dart';

/// 🆕 (Prompt 20) DTO مطابق لبنية جدول `public.project_milestones`
/// (انظر `020_create_project_milestones.sql`)، بنفس نمط `project_dto.dart`
/// تماماً.
class ProjectMilestoneDto {
  const ProjectMilestoneDto({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.title,
    required this.status,
    required this.progressPercent,
    required this.createdAt,
    required this.updatedAt,
    this.titleAr,
    this.description,
    this.dueDate,
    this.completedAt,
    this.createdBy,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String title;
  final String? titleAr;
  final String? description;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String status;
  final int progressPercent;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProjectMilestoneDto.fromJson(Map<String, dynamic> json) {
    return ProjectMilestoneDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      titleAr: json['title_ar'] as String?,
      description: json['description'] as String?,
      dueDate: parseNullableDateTime(json['due_date']),
      completedAt: parseNullableDateTime(json['completed_at']),
      status: json['status'] as String,
      progressPercent: parseNullableInt(json['progress_percent']) ?? 0,
      createdBy: json['created_by'] as String?,
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
      'title_ar': titleAr,
      'description': description,
      'due_date': toNullableDateOnlyString(dueDate),
      'completed_at': completedAt?.toIso8601String(),
      'status': status,
      'progress_percent': progressPercent,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج/التحديث (بدون `id`/`created_at`/`updated_at`).
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'project_id': projectId,
      'title': title,
      'title_ar': titleAr,
      'description': description,
      'due_date': toNullableDateOnlyString(dueDate),
      'completed_at': completedAt?.toIso8601String(),
      'status': status,
      'progress_percent': progressPercent,
      'created_by': createdBy,
    };
  }

  ProjectMilestone toEntity() {
    return ProjectMilestone(
      id: id,
      companyId: companyId,
      projectId: projectId,
      title: title,
      titleAr: titleAr,
      description: description,
      dueDate: dueDate,
      completedAt: completedAt,
      status: MilestoneStatus.fromDbValue(status),
      progressPercent: progressPercent,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProjectMilestoneDto.fromEntity(ProjectMilestone entity) {
    return ProjectMilestoneDto(
      id: entity.id,
      companyId: entity.companyId,
      projectId: entity.projectId,
      title: entity.title,
      titleAr: entity.titleAr,
      description: entity.description,
      dueDate: entity.dueDate,
      completedAt: entity.completedAt,
      status: entity.status.dbValue,
      progressPercent: entity.progressPercent,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
