import '../../domain/entities/app_user.dart';
import '../../domain/enums/user_role.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.company_members` (انظر
/// `002_create_company_members.sql`)، يقابل كيان [AppUser].
class AppUserDto {
  const AppUserDto({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    required this.fullName,
    required this.isActive,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.avatarUrl,
    this.jobTitle,
  });

  final String id;
  final String companyId;
  final String userId;
  final String role;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? jobTitle;
  final bool isActive;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AppUserDto.fromJson(Map<String, dynamic> json) {
    return AppUserDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      jobTitle: json['job_title'] as String?,
      isActive: json['is_active'] as bool,
      joinedAt: parseDateTime(json['joined_at']),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'user_id': userId,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'job_title': jobTitle,
      'is_active': isActive,
      'joined_at': joinedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج (بدون `id`/`created_at`/`updated_at`).
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'user_id': userId,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'job_title': jobTitle,
      'is_active': isActive,
    };
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      companyId: companyId,
      userId: userId,
      role: UserRole.fromName(role),
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      jobTitle: jobTitle,
      isActive: isActive,
      joinedAt: joinedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AppUserDto.fromEntity(AppUser entity) {
    return AppUserDto(
      id: entity.id,
      companyId: entity.companyId,
      userId: entity.userId,
      role: entity.role.name,
      fullName: entity.fullName,
      phone: entity.phone,
      avatarUrl: entity.avatarUrl,
      jobTitle: entity.jobTitle,
      isActive: entity.isActive,
      joinedAt: entity.joinedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
