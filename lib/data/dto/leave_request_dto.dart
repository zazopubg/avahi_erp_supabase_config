import '../../domain/entities/leave_request.dart';
import '../../domain/enums/leave_status.dart';
import '../../domain/enums/leave_type.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.leave_requests` (انظر
/// `014_create_leave_requests.sql`). 🆕
class LeaveRequestDto {
  const LeaveRequestDto({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.reason,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
  });

  final String id;
  final String companyId;
  final String userId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LeaveRequestDto.fromJson(Map<String, dynamic> json) {
    return LeaveRequestDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      leaveType: json['leave_type'] as String,
      startDate: parseDateTime(json['start_date']),
      endDate: parseDateTime(json['end_date']),
      reason: json['reason'] as String?,
      status: json['status'] as String,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: parseNullableDateTime(json['reviewed_at']),
      reviewNote: json['review_note'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'user_id': userId,
      'leave_type': leaveType,
      'start_date': toDateOnlyString(startDate),
      'end_date': toDateOnlyString(endDate),
      'reason': reason,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'review_note': reviewNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج (بدون `id`/`created_at`/`updated_at`).
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'user_id': userId,
      'leave_type': leaveType,
      'start_date': toDateOnlyString(startDate),
      'end_date': toDateOnlyString(endDate),
      'reason': reason,
      'status': status,
    };
  }

  LeaveRequest toEntity() {
    return LeaveRequest(
      id: id,
      companyId: companyId,
      userId: userId,
      leaveType: LeaveType.fromDbValue(leaveType),
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: LeaveStatus.fromDbValue(status),
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      reviewNote: reviewNote,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory LeaveRequestDto.fromEntity(LeaveRequest entity) {
    return LeaveRequestDto(
      id: entity.id,
      companyId: entity.companyId,
      userId: entity.userId,
      leaveType: entity.leaveType.dbValue,
      startDate: entity.startDate,
      endDate: entity.endDate,
      reason: entity.reason,
      status: entity.status.dbValue,
      reviewedBy: entity.reviewedBy,
      reviewedAt: entity.reviewedAt,
      reviewNote: entity.reviewNote,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
