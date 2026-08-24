import 'package:equatable/equatable.dart';

import '../enums/attendance_type.dart';
import '../enums/check_method.dart';

/// سجل حضور وانصراف، مطابق لجدول `public.attendance` (انظر
/// `006_create_attendance.sql`). يدعم العمل دون اتصال عبر
/// [clientMutationId] (idempotency عند إعادة المزامنة)، والتحقق
/// الجغرافي عبر [geofenceValid]/[distanceMeters]، وطريقتي تسجيل
/// (GPS/QR) عبر [checkMethod].
class AttendanceRecord extends Equatable {
  const AttendanceRecord({
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

  /// معرّف المستخدم (`auth.users.id`) صاحب سجل الحضور.
  final String userId;

  /// معرّف تزامن فريد (UUID) يُولَّد على الجهاز محلياً قبل الإرسال؛
  /// يُستخدم مع `upsert on-conflict-do-nothing` في Supabase لمنع
  /// تكرار السجل عند إعادة المحاولة (Retry) في وضع عدم الاتصال.
  final String clientMutationId;

  final DateTime checkInAt;
  final DateTime? checkOutAt;

  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;

  /// نتيجة التحقق الجغرافي (محسوبة عبر معادلة Haversine في Edge
  /// Function `attendance-guard`).
  final bool geofenceValid;

  /// المسافة بالأمتار بين نقطة تسجيل الحضور ومركز الجيوفنسينغ.
  final double? distanceMeters;

  /// طريقة تسجيل الحضور (GPS أو QR).
  final CheckMethod checkMethod;

  /// معرّف رمز QR الممسوح، عند [checkMethod] = [CheckMethod.qr].
  final String? qrCodeId;

  /// حالة اعتماد السجل (pending/approved/rejected).
  final AttendanceType status;

  final String? notes;
  final String? approvedBy;
  final DateTime? approvedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord copyWith({
    String? id,
    String? companyId,
    String? projectId,
    String? userId,
    String? clientMutationId,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    bool? geofenceValid,
    double? distanceMeters,
    CheckMethod? checkMethod,
    String? qrCodeId,
    AttendanceType? status,
    String? notes,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      clientMutationId: clientMutationId ?? this.clientMutationId,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      geofenceValid: geofenceValid ?? this.geofenceValid,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      checkMethod: checkMethod ?? this.checkMethod,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        projectId,
        userId,
        clientMutationId,
        checkInAt,
        checkOutAt,
        checkInLatitude,
        checkInLongitude,
        checkOutLatitude,
        checkOutLongitude,
        geofenceValid,
        distanceMeters,
        checkMethod,
        qrCodeId,
        status,
        notes,
        approvedBy,
        approvedAt,
        createdAt,
        updatedAt,
      ];
}
