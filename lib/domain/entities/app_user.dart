import 'package:equatable/equatable.dart';

import '../enums/user_role.dart';

/// عضوية المستخدم في شركة محددة مع دوره ضمنها. مطابق لجدول
/// `public.company_members` (انظر `002_create_company_members.sql`).
///
/// ⚠️ [id] هو معرّف صف العضوية نفسها، بينما [userId] هو معرّف
/// المستخدم في `auth.users` (Supabase Auth) — قد يملك نفس المستخدم
/// أكثر من عضوية (شركات متعددة) لكل منها [id] مختلف.
class AppUser extends Equatable {
  const AppUser({
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

  /// معرّف المستخدم في `auth.users` (Supabase Auth).
  final String userId;

  final UserRole role;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? jobTitle;
  final bool isActive;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser copyWith({
    String? id,
    String? companyId,
    String? userId,
    UserRole? role,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? jobTitle,
    bool? isActive,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      jobTitle: jobTitle ?? this.jobTitle,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        userId,
        role,
        fullName,
        phone,
        avatarUrl,
        jobTitle,
        isActive,
        joinedAt,
        createdAt,
        updatedAt,
      ];
}
