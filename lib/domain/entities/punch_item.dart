import 'package:equatable/equatable.dart';

import '../enums/punch_status.dart';
import '../enums/task_priority.dart';

/// عنصر ضمن قائمة الملاحظات (Punch List) لمشروع، قد يرتبط اختيارياً
/// بتقرير ميداني. مطابق لجدول `public.punch_items` (انظر
/// `008_create_punch_items.sql`).
class PunchItem extends Equatable {
  const PunchItem({
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

  /// معرّف التقرير الميداني المرتبط، اختياري.
  final String? fieldReportId;

  final String title;
  final String? description;
  final String? locationNote;

  final PunchStatus status;
  final TaskPriority priority;

  final String? assignedTo;
  final String? createdBy;

  final DateTime? dueDate;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime? closedAt;
  final String? closedBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  PunchItem copyWith({
    String? id,
    String? companyId,
    String? projectId,
    String? fieldReportId,
    String? title,
    String? description,
    String? locationNote,
    PunchStatus? status,
    TaskPriority? priority,
    String? assignedTo,
    String? createdBy,
    DateTime? dueDate,
    DateTime? resolvedAt,
    String? resolvedBy,
    DateTime? closedAt,
    String? closedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PunchItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      fieldReportId: fieldReportId ?? this.fieldReportId,
      title: title ?? this.title,
      description: description ?? this.description,
      locationNote: locationNote ?? this.locationNote,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      closedAt: closedAt ?? this.closedAt,
      closedBy: closedBy ?? this.closedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        projectId,
        fieldReportId,
        title,
        description,
        locationNote,
        status,
        priority,
        assignedTo,
        createdBy,
        dueDate,
        resolvedAt,
        resolvedBy,
        closedAt,
        closedBy,
        createdAt,
        updatedAt,
      ];
}
