import 'package:equatable/equatable.dart';

import '../enums/task_priority.dart';
import '../enums/task_status.dart';

/// مهمة ضمن مشروع، مع دعم ترتيب لوحة Kanban عبر [kanbanOrder]
/// (Prompt 16). مطابقة لجدول `public.tasks` (انظر
/// `005_create_tasks.sql`).
class Task extends Equatable {
  const Task({
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
  final TaskStatus status;
  final TaskPriority priority;

  /// معرّف المستخدم (`auth.users.id`) المُسندة إليه المهمة، إن وُجد.
  final String? assignedTo;

  final String? createdBy;
  final DateTime? dueDate;

  /// ترتيب البطاقة ضمن عمودها في لوحة Kanban.
  final int kanbanOrder;

  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task copyWith({
    String? id,
    String? companyId,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assignedTo,
    String? createdBy,
    DateTime? dueDate,
    int? kanbanOrder,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      kanbanOrder: kanbanOrder ?? this.kanbanOrder,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        projectId,
        title,
        description,
        status,
        priority,
        assignedTo,
        createdBy,
        dueDate,
        kanbanOrder,
        completedAt,
        createdAt,
        updatedAt,
      ];
}
