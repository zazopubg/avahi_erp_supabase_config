import 'package:equatable/equatable.dart';

/// إسناد عضو شركة ([AppUser]) إلى مشروع محدد. مطابق لجدول
/// `public.project_members` (انظر `004_create_project_members.sql`).
class ProjectMember extends Equatable {
  const ProjectMember({
    required this.id,
    required this.projectId,
    required this.companyId,
    required this.userId,
    required this.isActive,
    required this.assignedAt,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String companyId;

  /// معرّف المستخدم (`auth.users.id`) المُسند للمشروع.
  final String userId;

  final bool isActive;
  final DateTime assignedAt;
  final DateTime createdAt;

  ProjectMember copyWith({
    String? id,
    String? projectId,
    String? companyId,
    String? userId,
    bool? isActive,
    DateTime? assignedAt,
    DateTime? createdAt,
  }) {
    return ProjectMember(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        projectId,
        companyId,
        userId,
        isActive,
        assignedAt,
        createdAt,
      ];
}
