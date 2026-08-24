import 'package:avahi/core/constants/roles.dart';
import 'package:avahi/domain/entities/app_user.dart';
import 'package:avahi/domain/entities/attendance_record.dart';
import 'package:avahi/domain/entities/equipment.dart';
import 'package:avahi/domain/entities/field_report.dart';
import 'package:avahi/domain/entities/leave_request.dart';
import 'package:avahi/domain/entities/project.dart';
import 'package:avahi/domain/enums/attendance_type.dart';
import 'package:avahi/domain/enums/check_method.dart';
import 'package:avahi/domain/enums/equipment_status.dart';
import 'package:avahi/domain/enums/leave_status.dart';
import 'package:avahi/domain/enums/leave_type.dart';
import 'package:avahi/domain/enums/project_status.dart';
import 'package:avahi/domain/enums/report_status.dart';

/// مصنع بيانات تجريبية (Fixtures) مشترك لكل ملفات `test/` — يبني كيانات
/// [domain/entities/] الحقيقية بقيم افتراضية معقولة وقابلة للتخصيص عبر
/// `copyWith`، بدل تكرار مُنشئات طويلة الحقول (11-22 حقلاً لكل كيان) في
/// كل ملف اختبار على حدة.
///
/// كل الطوابع الزمنية الافتراضية ثابتة (`_baseTime`) وليست
/// `DateTime.now()` لضمان أن الاختبارات **حتمية** (Deterministic) —
/// أي مقارنة نسبية بالزمن الحالي (`AttendanceValidator.validateCheckTimes`،
/// `LeaveValidator.validateDateRange`) تمرَّر صراحة عبر باراميتر `now`
/// في كل اختبار يحتاجها، وليس عبر هذه الطوابع الثابتة.
abstract final class Fixtures {
  static final DateTime baseTime = DateTime.utc(2026, 1, 10, 8);

  // ── Project ──────────────────────────────────────────────────

  static Project project({
    String id = 'project-1',
    String companyId = 'company-1',
    String name = 'Downtown Tower',
    String? nameAr = 'برج وسط المدينة',
    double geofenceRadiusMeters = 150,
    double? latitude = 36.1911,
    double? longitude = 44.0092,
    ProjectStatus status = ProjectStatus.active,
  }) {
    return Project(
      id: id,
      companyId: companyId,
      name: name,
      nameAr: nameAr,
      geofenceRadiusMeters: geofenceRadiusMeters,
      latitude: latitude,
      longitude: longitude,
      status: status,
      createdAt: baseTime,
      updatedAt: baseTime,
    );
  }

  // ── AppUser ──────────────────────────────────────────────────

  static AppUser appUser({
    String id = 'member-1',
    String companyId = 'company-1',
    String userId = 'user-1',
    UserRole role = UserRole.worker,
    String fullName = 'أحمد الجبوري',
    bool isActive = true,
  }) {
    return AppUser(
      id: id,
      companyId: companyId,
      userId: userId,
      role: role,
      fullName: fullName,
      isActive: isActive,
      joinedAt: baseTime,
      createdAt: baseTime,
      updatedAt: baseTime,
    );
  }

  // ── AttendanceRecord ─────────────────────────────────────────

  static AttendanceRecord attendanceRecord({
    String id = 'attendance-1',
    String companyId = 'company-1',
    String projectId = 'project-1',
    String userId = 'user-1',
    String clientMutationId = 'mutation-1',
    DateTime? checkInAt,
    DateTime? checkOutAt,
    double? checkInLatitude = 36.1911,
    double? checkInLongitude = 44.0092,
    bool geofenceValid = true,
    double? distanceMeters = 10,
    CheckMethod checkMethod = CheckMethod.gps,
    AttendanceType status = AttendanceType.pending,
  }) {
    final DateTime effectiveCheckInAt = checkInAt ?? baseTime;
    return AttendanceRecord(
      id: id,
      companyId: companyId,
      projectId: projectId,
      userId: userId,
      clientMutationId: clientMutationId,
      checkInAt: effectiveCheckInAt,
      checkOutAt: checkOutAt,
      checkInLatitude: checkInLatitude,
      checkInLongitude: checkInLongitude,
      geofenceValid: geofenceValid,
      distanceMeters: distanceMeters,
      checkMethod: checkMethod,
      status: status,
      createdAt: effectiveCheckInAt,
      updatedAt: effectiveCheckInAt,
    );
  }

  // ── FieldReport ──────────────────────────────────────────────

  static FieldReport fieldReport({
    String id = 'report-1',
    String companyId = 'company-1',
    String projectId = 'project-1',
    DateTime? reportDate,
    ReportStatus status = ReportStatus.draft,
    int laborCount = 5,
    String? workPerformed = 'صب خرسانة الطابق الثالث',
  }) {
    final DateTime effectiveDate = reportDate ?? baseTime;
    return FieldReport(
      id: id,
      companyId: companyId,
      projectId: projectId,
      reportDate: effectiveDate,
      status: status,
      laborCount: laborCount,
      workPerformed: workPerformed,
      createdAt: effectiveDate,
      updatedAt: effectiveDate,
    );
  }

  // ── Equipment ────────────────────────────────────────────────

  static Equipment equipment({
    String id = 'equipment-1',
    String companyId = 'company-1',
    String name = 'رافعة برجية',
    String type = 'crane',
    EquipmentStatus status = EquipmentStatus.inUse,
    double usageHours = 100,
    DateTime? lastMaintenanceDate,
  }) {
    return Equipment(
      id: id,
      companyId: companyId,
      name: name,
      type: type,
      status: status,
      usageHours: usageHours,
      lastMaintenanceDate: lastMaintenanceDate,
      createdAt: baseTime,
      updatedAt: baseTime,
    );
  }

  // ── LeaveRequest ─────────────────────────────────────────────

  static LeaveRequest leaveRequest({
    String id = 'leave-1',
    String companyId = 'company-1',
    String userId = 'user-1',
    LeaveType leaveType = LeaveType.annual,
    DateTime? startDate,
    DateTime? endDate,
    LeaveStatus status = LeaveStatus.pending,
  }) {
    final DateTime effectiveStart = startDate ?? baseTime;
    final DateTime effectiveEnd = endDate ?? baseTime.add(const Duration(days: 2));
    return LeaveRequest(
      id: id,
      companyId: companyId,
      userId: userId,
      leaveType: leaveType,
      startDate: effectiveStart,
      endDate: effectiveEnd,
      status: status,
      createdAt: baseTime,
      updatedAt: baseTime,
    );
  }
}
