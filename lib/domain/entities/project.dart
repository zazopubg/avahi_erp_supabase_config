import 'package:equatable/equatable.dart';

import '../enums/project_status.dart';

/// المشروع الإنشائي، مطابق لجدول `public.projects` (انظر
/// `003_create_projects.sql`). يحمل أيضاً مركز الجيوفنسينغ الافتراضي
/// ([latitude]/[longitude]/[geofenceRadiusMeters]) المستخدم لاحقاً في
/// Prompt 15 (تسجيل الحضور بالموقع الجغرافي).
class Project extends Equatable {
  const Project({
    required this.id,
    required this.companyId,
    required this.name,
    required this.geofenceRadiusMeters,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.nameAr,
    this.code,
    this.clientName,
    this.address,
    this.latitude,
    this.longitude,
    this.startDate,
    this.endDate,
    this.description,
    this.createdBy,
  });

  final String id;
  final String companyId;
  final String name;
  final String? nameAr;

  /// رمز/كود المشروع، فريد ضمن نطاق الشركة الواحدة.
  final String? code;

  final String? clientName;
  final String? address;

  /// إحداثيات مركز الجيوفنسينغ الافتراضي لموقع المشروع.
  final double? latitude;
  final double? longitude;

  /// نصف قطر الجيوفنسينغ بالأمتار (افتراضياً 150م).
  final double geofenceRadiusMeters;

  final DateTime? startDate;
  final DateTime? endDate;
  final ProjectStatus status;
  final String? description;

  /// معرّف المستخدم (`auth.users.id`) الذي أنشأ المشروع.
  final String? createdBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  Project copyWith({
    String? id,
    String? companyId,
    String? name,
    String? nameAr,
    String? code,
    String? clientName,
    String? address,
    double? latitude,
    double? longitude,
    double? geofenceRadiusMeters,
    DateTime? startDate,
    DateTime? endDate,
    ProjectStatus? status,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      code: code ?? this.code,
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        name,
        nameAr,
        code,
        clientName,
        address,
        latitude,
        longitude,
        geofenceRadiusMeters,
        startDate,
        endDate,
        status,
        description,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
