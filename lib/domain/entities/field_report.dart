import 'package:equatable/equatable.dart';

import '../enums/report_status.dart';
import '../enums/weather_condition.dart';

/// تقرير ميداني يومي، مطابق لجدول `public.field_reports` (انظر
/// `007_create_field_reports.sql`). يدعم دورة اعتماد
/// (draft→submitted→reviewed/rejected)، وتوقيعاً رقمياً مزدوجاً
/// (مشرف/عميل) عبر [supervisorSignatureUrl]/[clientSignatureUrl]،
/// وحقول طقس تُملأ تلقائياً لاحقاً (Prompt 17).
class FieldReport extends Equatable {
  const FieldReport({
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
  final ReportStatus status;

  final WeatherCondition? weatherCondition;
  final double? temperatureC;

  final int laborCount;
  final String? workPerformed;
  final String? materialsUsed;
  final String? equipmentUsed;
  final String? issues;
  final String? notes;

  /// مسار توقيع المشرف الرقمي في Supabase Storage.
  final String? supervisorSignatureUrl;
  final DateTime? supervisorSignedAt;

  /// مسار توقيع العميل الرقمي في Supabase Storage.
  final String? clientSignatureUrl;
  final DateTime? clientSignedAt;

  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  final DateTime createdAt;
  final DateTime updatedAt;

  FieldReport copyWith({
    String? id,
    String? companyId,
    String? projectId,
    String? createdBy,
    DateTime? reportDate,
    ReportStatus? status,
    WeatherCondition? weatherCondition,
    double? temperatureC,
    int? laborCount,
    String? workPerformed,
    String? materialsUsed,
    String? equipmentUsed,
    String? issues,
    String? notes,
    String? supervisorSignatureUrl,
    DateTime? supervisorSignedAt,
    String? clientSignatureUrl,
    DateTime? clientSignedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FieldReport(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      createdBy: createdBy ?? this.createdBy,
      reportDate: reportDate ?? this.reportDate,
      status: status ?? this.status,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      temperatureC: temperatureC ?? this.temperatureC,
      laborCount: laborCount ?? this.laborCount,
      workPerformed: workPerformed ?? this.workPerformed,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      equipmentUsed: equipmentUsed ?? this.equipmentUsed,
      issues: issues ?? this.issues,
      notes: notes ?? this.notes,
      supervisorSignatureUrl:
          supervisorSignatureUrl ?? this.supervisorSignatureUrl,
      supervisorSignedAt: supervisorSignedAt ?? this.supervisorSignedAt,
      clientSignatureUrl: clientSignatureUrl ?? this.clientSignatureUrl,
      clientSignedAt: clientSignedAt ?? this.clientSignedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        projectId,
        createdBy,
        reportDate,
        status,
        weatherCondition,
        temperatureC,
        laborCount,
        workPerformed,
        materialsUsed,
        equipmentUsed,
        issues,
        notes,
        supervisorSignatureUrl,
        supervisorSignedAt,
        clientSignatureUrl,
        clientSignedAt,
        reviewedBy,
        reviewedAt,
        rejectionReason,
        createdAt,
        updatedAt,
      ];
}
