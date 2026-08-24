import 'package:equatable/equatable.dart';

import '../enums/milestone_status.dart';

/// 🆕 (Prompt 20) مرحلة رئيسية (Milestone) ضمن جدول زمني لمشروع
/// إنشائي معيّن — مطابقة لجدول `public.project_milestones` (انظر
/// `020_create_project_milestones.sql`). تُستخدم فقط ضمن
/// `features/projects/` (`project_milestones.dart` لإدارتها،
/// `project_overview.dart` لعرض المراحل القادمة على الهاتف).
class ProjectMilestone extends Equatable {
  const ProjectMilestone({
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
  final MilestoneStatus status;

  /// نسبة إنجاز المرحلة (0-100) — مستقلة عن [status] عمداً (مرحلة قد
  /// تكون `inProgress` بنسبة 60% مثلاً)، بنفس فلسفة شريط التقدّم في
  /// `project_progress_bar.dart`.
  final int progressPercent;

  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `true` إن كانت المرحلة تجاوزت [dueDate] ولم تكتمل بعد — حساب
  /// مشتق (Derived) لا يعتمد فقط على [status] المخزّنة صراحة، حتى لو
  /// لم تُحدَّث القيمة المخزَّنة بعد عبر مهمة دورية على الخادم.
  bool get isOverdue {
    if (status.isCompleted) return false;
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  ProjectMilestone copyWith({
    String? id,
    String? companyId,
    String? projectId,
    String? title,
    String? titleAr,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    MilestoneStatus? status,
    int? progressPercent,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectMilestone(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      createdBy: createdBy ?? this.createdBy,
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
        titleAr,
        description,
        dueDate,
        completedAt,
        status,
        progressPercent,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
