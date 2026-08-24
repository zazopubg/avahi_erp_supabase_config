import 'package:equatable/equatable.dart';

import '../enums/leave_status.dart';
import '../enums/leave_type.dart';

/// طلب إجازة يقدّمه موظف ويعتمده/يرفضه مسؤوله المباشر. مطابق لجدول
/// `public.leave_requests` (انظر `014_create_leave_requests.sql`). 🆕
class LeaveRequest extends Equatable {
  const LeaveRequest({
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

  /// معرّف المستخدم (`auth.users.id`) مقدّم الطلب.
  final String userId;

  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  final LeaveStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;

  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveRequest copyWith({
    String? id,
    String? companyId,
    String? userId,
    LeaveType? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    LeaveStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        userId,
        leaveType,
        startDate,
        endDate,
        reason,
        status,
        reviewedBy,
        reviewedAt,
        reviewNote,
        createdAt,
        updatedAt,
      ];
}
