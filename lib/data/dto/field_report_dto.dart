import '../../domain/entities/field_report.dart';
import '../../domain/enums/report_status.dart';
import '../../domain/enums/weather_condition.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.field_reports` (انظر
/// `007_create_field_reports.sql`).
class FieldReportDto {
  const FieldReportDto({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.reportDate,
    required this.status,
    required this.laborCount,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.weatherCondition,
    this.temperatureC,
    this.workPerformed,
    this.materialsUsed,
    this.equipmentUsed,
    this.issues,
    this.notes,
    this.supervisorSignatureUrl,
    this.supervisorSignedAt,
    this.clientSignatureUrl,
    this.clientSignedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String? createdBy;
  final DateTime reportDate;
  final String status;
  final String? weatherCondition;
  final double? temperatureC;
  final int laborCount;
  final String? workPerformed;
  final String? materialsUsed;
  final String? equipmentUsed;
  final String? issues;
  final String? notes;
  final String? supervisorSignatureUrl;
  final DateTime? supervisorSignedAt;
  final String? clientSignatureUrl;
  final DateTime? clientSignedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FieldReportDto.fromJson(Map<String, dynamic> json) {
    return FieldReportDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      projectId: json['project_id'] as String,
      createdBy: json['created_by'] as String?,
      reportDate: parseDateTime(json['report_date']),
      status: json['status'] as String,
      weatherCondition: json['weather_condition'] as String?,
      temperatureC: parseNullableDouble(json['temperature_c']),
      laborCount: parseNullableInt(json['labor_count']) ?? 0,
      workPerformed: json['work_performed'] as String?,
      materialsUsed: json['materials_used'] as String?,
      equipmentUsed: json['equipment_used'] as String?,
      issues: json['issues'] as String?,
      notes: json['notes'] as String?,
      supervisorSignatureUrl: json['supervisor_signature_url'] as String?,
      supervisorSignedAt: parseNullableDateTime(json['supervisor_signed_at']),
      clientSignatureUrl: json['client_signature_url'] as String?,
      clientSignedAt: parseNullableDateTime(json['client_signed_at']),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: parseNullableDateTime(json['reviewed_at']),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'project_id': projectId,
      'created_by': createdBy,
      'report_date': toDateOnlyString(reportDate),
      'status': status,
      'weather_condition': weatherCondition,
      'temperature_c': temperatureC,
      'labor_count': laborCount,
      'work_performed': workPerformed,
      'materials_used': materialsUsed,
      'equipment_used': equipmentUsed,
      'issues': issues,
      'notes': notes,
      'supervisor_signature_url': supervisorSignatureUrl,
      'supervisor_signed_at': supervisorSignedAt?.toIso8601String(),
      'client_signature_url': clientSignatureUrl,
      'client_signed_at': clientSignedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة لحفظ مسوّدة (إنشاء/تحديث) — تستثني حقول دورة
  /// الاعتماد (`reviewed_*`) التي تُدار حصراً عبر `reviewReport`.
  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'project_id': projectId,
      'created_by': createdBy,
      'report_date': toDateOnlyString(reportDate),
      'status': status,
      'weather_condition': weatherCondition,
      'temperature_c': temperatureC,
      'labor_count': laborCount,
      'work_performed': workPerformed,
      'materials_used': materialsUsed,
      'equipment_used': equipmentUsed,
      'issues': issues,
      'notes': notes,
    };
  }

  FieldReport toEntity() {
    return FieldReport(
      id: id,
      companyId: companyId,
      projectId: projectId,
      createdBy: createdBy,
      reportDate: reportDate,
      status: ReportStatus.fromDbValue(status),
      weatherCondition: WeatherCondition.fromDbValue(weatherCondition),
      temperatureC: temperatureC,
      laborCount: laborCount,
      workPerformed: workPerformed,
      materialsUsed: materialsUsed,
      equipmentUsed: equipmentUsed,
      issues: issues,
      notes: notes,
      supervisorSignatureUrl: supervisorSignatureUrl,
      supervisorSignedAt: supervisorSignedAt,
      clientSignatureUrl: clientSignatureUrl,
      clientSignedAt: clientSignedAt,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      rejectionReason: rejectionReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory FieldReportDto.fromEntity(FieldReport entity) {
    return FieldReportDto(
      id: entity.id,
      companyId: entity.companyId,
      projectId: entity.projectId,
      createdBy: entity.createdBy,
      reportDate: entity.reportDate,
      status: entity.status.dbValue,
      weatherCondition: entity.weatherCondition?.dbValue,
      temperatureC: entity.temperatureC,
      laborCount: entity.laborCount,
      workPerformed: entity.workPerformed,
      materialsUsed: entity.materialsUsed,
      equipmentUsed: entity.equipmentUsed,
      issues: entity.issues,
      notes: entity.notes,
      supervisorSignatureUrl: entity.supervisorSignatureUrl,
      supervisorSignedAt: entity.supervisorSignedAt,
      clientSignatureUrl: entity.clientSignatureUrl,
      clientSignedAt: entity.clientSignedAt,
      reviewedBy: entity.reviewedBy,
      reviewedAt: entity.reviewedAt,
      rejectionReason: entity.rejectionReason,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
