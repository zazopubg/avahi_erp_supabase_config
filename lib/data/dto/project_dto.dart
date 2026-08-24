import '../../domain/entities/project.dart';
import '../../domain/enums/project_status.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.projects` (انظر
/// `003_create_projects.sql`).
class ProjectDto {
  const ProjectDto({
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
  final String? code;
  final String? clientName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double geofenceRadiusMeters;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    return ProjectDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      code: json['code'] as String?,
      clientName: json['client_name'] as String?,
      address: json['address'] as String?,
      latitude: parseNullableDouble(json['latitude']),
      longitude: parseNullableDouble(json['longitude']),
      geofenceRadiusMeters: parseDouble(json['geofence_radius_meters']),
      startDate: parseNullableDateTime(json['start_date']),
      endDate: parseNullableDateTime(json['end_date']),
      status: json['status'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'name': name,
      'name_ar': nameAr,
      'code': code,
      'client_name': clientName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius_meters': geofenceRadiusMeters,
      'start_date': toNullableDateOnlyString(startDate),
      'end_date': toNullableDateOnlyString(endDate),
      'status': status,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج (بدون `id`/`created_at`/`updated_at`).
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'name': name,
      'name_ar': nameAr,
      'code': code,
      'client_name': clientName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius_meters': geofenceRadiusMeters,
      'start_date': toNullableDateOnlyString(startDate),
      'end_date': toNullableDateOnlyString(endDate),
      'status': status,
      'description': description,
      'created_by': createdBy,
    };
  }

  Project toEntity() {
    return Project(
      id: id,
      companyId: companyId,
      name: name,
      nameAr: nameAr,
      code: code,
      clientName: clientName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      geofenceRadiusMeters: geofenceRadiusMeters,
      startDate: startDate,
      endDate: endDate,
      status: ProjectStatus.fromDbValue(status),
      description: description,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProjectDto.fromEntity(Project entity) {
    return ProjectDto(
      id: entity.id,
      companyId: entity.companyId,
      name: entity.name,
      nameAr: entity.nameAr,
      code: entity.code,
      clientName: entity.clientName,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      geofenceRadiusMeters: entity.geofenceRadiusMeters,
      startDate: entity.startDate,
      endDate: entity.endDate,
      status: entity.status.dbValue,
      description: entity.description,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
