import '../../domain/entities/attendance_record.dart';
import '../../domain/enums/attendance_type.dart';
import '../../domain/enums/check_method.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.attendance` (انظر
/// `006_create_attendance.sql`).
class AttendanceDto {
  const AttendanceDto({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.userId,
    required this.clientMutationId,
    required this.checkInAt,
    required this.geofenceValid,
    required this.checkMethod,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.checkOutAt,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.distanceMeters,
    this.qrCodeId,
    this.notes,
    this.approvedBy,
    this.approvedAt,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String userId;
  final String clientMutationId;
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final bool geofenceValid;
  final double? distanceMeters;
  final String checkMethod;
  final String? qrCodeId;
  final String status;
  final String? notes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AttendanceDto.fromJson(Map<String, dynamic> json) {
    return AttendanceDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      clientMutationId: json['client_mutation_id'] as String,
      checkInAt: parseDateTime(json['check_in_at']),
      checkOutAt: parseNullableDateTime(json['check_out_at']),
      checkInLatitude: parseNullableDouble(json['check_in_latitude']),
      checkInLongitude: parseNullableDouble(json['check_in_longitude']),
      checkOutLatitude: parseNullableDouble(json['check_out_latitude']),
      checkOutLongitude: parseNullableDouble(json['check_out_longitude']),
      geofenceValid: json['geofence_valid'] as bool,
      distanceMeters: parseNullableDouble(json['distance_meters']),
      checkMethod: json['check_method'] as String,
      qrCodeId: json['qr_code_id'] as String?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: parseNullableDateTime(json['approved_at']),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'project_id': projectId,
      'user_id': userId,
      'client_mutation_id': clientMutationId,
      'check_in_at': checkInAt.toIso8601String(),
      'check_out_at': checkOutAt?.toIso8601String(),
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'geofence_valid': geofenceValid,
      'distance_meters': distanceMeters,
      'check_method': checkMethod,
      'qr_code_id': qrCodeId,
      'status': status,
      'notes': notes,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AttendanceRecord toEntity() {
    return AttendanceRecord(
      id: id,
      companyId: companyId,
      projectId: projectId,
      userId: userId,
      clientMutationId: clientMutationId,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      checkInLatitude: checkInLatitude,
      checkInLongitude: checkInLongitude,
      checkOutLatitude: checkOutLatitude,
      checkOutLongitude: checkOutLongitude,
      geofenceValid: geofenceValid,
      distanceMeters: distanceMeters,
      checkMethod: CheckMethod.fromDbValue(checkMethod),
      qrCodeId: qrCodeId,
      status: AttendanceType.fromDbValue(status),
      notes: notes,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AttendanceDto.fromEntity(AttendanceRecord entity) {
    return AttendanceDto(
      id: entity.id,
      companyId: entity.companyId,
      projectId: entity.projectId,
      userId: entity.userId,
      clientMutationId: entity.clientMutationId,
      checkInAt: entity.checkInAt,
      checkOutAt: entity.checkOutAt,
      checkInLatitude: entity.checkInLatitude,
      checkInLongitude: entity.checkInLongitude,
      checkOutLatitude: entity.checkOutLatitude,
      checkOutLongitude: entity.checkOutLongitude,
      geofenceValid: entity.geofenceValid,
      distanceMeters: entity.distanceMeters,
      checkMethod: entity.checkMethod.dbValue,
      qrCodeId: entity.qrCodeId,
      status: entity.status.dbValue,
      notes: entity.notes,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
