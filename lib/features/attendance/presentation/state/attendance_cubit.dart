import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/gps_helper.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/attendance_record.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/enums/check_method.dart';
import '../../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../../../domain/usecases/attendance/check_out_usecase.dart';
import '../../../../domain/usecases/attendance/get_my_attendance_history_usecase.dart';
import '../../../../domain/usecases/attendance/get_project_attendance_usecase.dart';
import '../../../../domain/usecases/attendance/get_today_attendance_usecase.dart';
import '../../../../domain/usecases/attendance/qr_check_in_usecase.dart';
import '../../../../domain/usecases/attendance/review_attendance_usecase.dart';
import '../../../../domain/usecases/attendance/watch_project_attendance_usecase.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import 'attendance_state.dart';

/// `Cubit` ميزة الحضور بالكامل — يقود كل شاشات `features/attendance/`
/// (الدخول/الانصراف عبر GPS أو QR، السجل الشخصي، المراقبة اللحظية
/// وتقرير الاستخراج الشهري على سطح المكتب) عبر [AttendanceData] واحدة
/// مجمّعة، بنفس فلسفة `HomeCubit` (`features/home/`، Prompt 14).
///
/// ⚠️ قرار تنقّل متعمَّد: كل شاشات هذه الميزة (`mobile/*`، `desktop/*`)
/// تُبنى فوق نفس مسار `RoutePaths.attendance` **الوحيد** الموجود مسبقاً
/// في `navigation/` (Prompt 12/13)، وليس عبر مسارات فرعية جديدة في
/// `go_router` — [AppNavDestinations.attendance] محمي أصلاً بصلاحية
/// [Permission.attendanceCheckInSelf] (كل الأدوار)، وزرَي "تسجيل حضور"/
/// "اعتماد الحضور" في `QuickActions` (`features/home/`) يشيران كلاهما
/// لنفس `RouteNames.attendance` فعلاً منذ Prompt 14. التمييز بين عرض
/// شاشات عامل ميداني (GPS/QR/سجل) وعرض لوحة إدارية (مراقبة/جدول/تقرير)
/// يتم بالكامل داخل `attendance_screen.dart` حسب `ShellMode` + فحص
/// [Permission.attendanceApproveTeam] للدور الحالي — تنقّل محلي (تبويبات/
/// `Navigator.push` للشاشات الفرعية) دون أي حاجة لتوسيع `app_router.dart`
/// أو `RoleGuard`/`AppNavDestinations` بمسارات جديدة.
class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required GetTodayAttendanceUsecase getTodayAttendanceUsecase,
    required CheckInUsecase checkInUsecase,
    required QrCheckInUsecase qrCheckInUsecase,
    required CheckOutUsecase checkOutUsecase,
    required ReviewAttendanceUsecase reviewAttendanceUsecase,
    required GetMyAttendanceHistoryUsecase getMyAttendanceHistoryUsecase,
    required GetProjectAttendanceUsecase getProjectAttendanceUsecase,
    required WatchProjectAttendanceUsecase watchProjectAttendanceUsecase,
    required LocationService locationService,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _getTodayAttendanceUsecase = getTodayAttendanceUsecase,
        _checkInUsecase = checkInUsecase,
        _qrCheckInUsecase = qrCheckInUsecase,
        _checkOutUsecase = checkOutUsecase,
        _reviewAttendanceUsecase = reviewAttendanceUsecase,
        _getMyAttendanceHistoryUsecase = getMyAttendanceHistoryUsecase,
        _getProjectAttendanceUsecase = getProjectAttendanceUsecase,
        _watchProjectAttendanceUsecase = watchProjectAttendanceUsecase,
        _locationService = locationService,
        super(const AttendanceLoading());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final GetTodayAttendanceUsecase _getTodayAttendanceUsecase;
  final CheckInUsecase _checkInUsecase;
  final QrCheckInUsecase _qrCheckInUsecase;
  final CheckOutUsecase _checkOutUsecase;
  final ReviewAttendanceUsecase _reviewAttendanceUsecase;
  final GetMyAttendanceHistoryUsecase _getMyAttendanceHistoryUsecase;
  final GetProjectAttendanceUsecase _getProjectAttendanceUsecase;
  final WatchProjectAttendanceUsecase _watchProjectAttendanceUsecase;
  final LocationService _locationService;

  StreamSubscription<AttendanceRecord>? _monitorSubscription;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى مرة واحدة عند دخول `attendance_screen.dart`: يحدّد
  /// "المشروع الحالي" (نفس منطق `HomeCubit._loadCurrentProject`)، يجلب
  /// سجل حضور اليوم ضمنه، ويقرأ حالة إذن الموقع الحالية (بلا طلب موقع
  /// فعلي بعد — [refreshGpsStatus] منفصلة عمداً لتُستدعى فقط عند
  /// اختيار طريقة GPS تحديداً).
  Future<void> loadInitial(AppUser user) async {
    emit(const AttendanceLoading());

    final ResultOf<List<Project>> projectsResult = await _getMyProjectsUsecase(
      user.userId,
    );

    final Project? project = projectsResult.fold(
      (Failure _) => null,
      (List<Project> projects) {
        if (projects.isEmpty) return null;
        return projects.firstWhere(
          (Project p) => p.status.isActive,
          orElse: () => projects.first,
        );
      },
    );

    if (project == null) {
      emit(
        const AttendanceError(
          ValidationFailure(
            message: 'لا يوجد مشروع نشط مرتبط بحسابك لتسجيل الحضور ضمنه.',
            code: 'attendance.no_project',
          ),
        ),
      );
      return;
    }

    final AttendanceRecord? todayRecord = await _loadTodayAttendance(
      userId: user.userId,
      projectId: project.id,
    );

    final GpsPermissionStatus gpsStatus = await _readGpsStatus();

    emit(
      AttendanceReady(
        AttendanceData(
          project: project,
          checkMethod: CheckMethod.gps,
          gpsStatus: gpsStatus,
          todayRecord: todayRecord,
        ),
      ),
    );
  }

  /// يعيد قراءة حالة إذن/خدمة الموقع فقط (مثال: بعد عودة المستخدم من
  /// إعدادات الجهاز) دون إعادة تحميل كامل الشاشة.
  Future<void> refreshGpsStatus() async {
    final AttendanceData? current = state.dataOrNull;
    if (current == null) return;

    final GpsPermissionStatus status = await _readGpsStatus();
    emit(AttendanceReady(current.copyWith(gpsStatus: status)));
  }

  /// يبدّل طريقة تسجيل الحضور المختارة في واجهة `check_in_screen.dart`
  /// (مبدّل GPS/QR) — عرض بحت، لا يُنفّذ أي عملية تسجيل فعلية.
  void setCheckMethod(CheckMethod method) {
    final AttendanceData? current = state.dataOrNull;
    if (current == null) return;
    emit(AttendanceReady(current.copyWith(checkMethod: method)));
  }

  // ── تسجيل حضور/انصراف ───────────────────────────────────────────

  /// تسجيل حضور عبر GPS. لا يرفض التسجيل عند فشل التحقق الجغرافي —
  /// السجل يُحفظ دوماً؛ [AttendanceCheckInGeofenceWarning] تحذير
  /// تفاعلي فقط (انظر توثيق `attendance_state.dart`).
  Future<void> checkInGps({required AppUser user, String? notes}) async {
    final AttendanceData? current = state.dataOrNull;
    if (current == null) return;

    emit(AttendanceCheckInProgress(current));

    final ResultOf<GeoPoint> locationResult =
        await _locationService.currentLocation();

    if (locationResult.isLeft) {
      final Failure failure = locationResult.fold(
        (Failure f) => f,
        (GeoPoint _) => throw StateError('unreachable'),
      );
      emit(AttendanceError(failure));
      return;
    }

    final GeoPoint point = locationResult.getOrNull()!;
    final Project project = current.project;

    // مركز جيوفنسينغ احتياطي: إن لم يُهيَّأ [Project.latitude]/[longitude]
    // بعد (مشروع لم تُحدَّد إحداثياته الدقيقة بعد)، يُستخدم موقع الجهاز
    // نفسه كمركز مؤقت — يجعل التحقق يمر دوماً (`geofenceValid = true`)
    // بدل رفض تسجيل حضور بلا سبب فعلي بسبب نقص بيانات المشروع.
    final double centerLat = project.latitude ?? point.latitude;
    final double centerLng = project.longitude ?? point.longitude;

    final ResultOf<AttendanceRecord> result = await _checkInUsecase(
      companyId: user.companyId,
      projectId: project.id,
      userId: user.userId,
      checkInLatitude: point.latitude,
      checkInLongitude: point.longitude,
      projectCenterLatitude: centerLat,
      projectCenterLongitude: centerLng,
      geofenceRadiusMeters: project.geofenceRadiusMeters,
      notes: notes,
    );

    _emitCheckInResult(current, result);
  }

  /// تسجيل حضور عبر مسح رمز QR — الموقع اختياري هنا (يُحاول جلبه
  /// بأفضل جهد، ويتجاهل الفشل بصمت إن تعذّر، بخلاف [checkInGps] حيث
  /// الموقع إلزامي).
  Future<void> checkInQr({
    required AppUser user,
    required String qrCodeId,
    String? notes,
  }) async {
    final AttendanceData? current = state.dataOrNull;
    if (current == null) return;

    emit(AttendanceCheckInProgress(current));

    final ResultOf<GeoPoint> locationResult =
        await _locationService.currentLocation();
    final GeoPoint? point = locationResult.getOrNull();
    final Project project = current.project;

    final ResultOf<AttendanceRecord> result = await _qrCheckInUsecase(
      companyId: user.companyId,
      userId: user.userId,
      qrCodeId: qrCodeId,
      deviceLatitude: point?.latitude,
      deviceLongitude: point?.longitude,
      projectCenterLatitude: project.latitude,
      projectCenterLongitude: project.longitude,
      geofenceRadiusMeters:
          project.latitude != null ? project.geofenceRadiusMeters : null,
      notes: notes,
    );

    _emitCheckInResult(current, result);
  }

  /// تسجيل انصراف عن سجل حضور اليوم القائم. عودة إلى [AttendanceReady]
  /// مباشرة عند النجاح (وليس [AttendanceCheckInSuccess] — الانصراف ليس
  /// حدث "تسجيل حضور").
  Future<void> checkOut({required AppUser user}) async {
    final AttendanceData? current = state.dataOrNull;
    final AttendanceRecord? todayRecord = current?.todayRecord;
    if (current == null || todayRecord == null) return;

    emit(AttendanceCheckInProgress(current));

    final ResultOf<GeoPoint> locationResult =
        await _locationService.currentLocation();
    final GeoPoint? point = locationResult.getOrNull();

    final ResultOf<AttendanceRecord> result = await _checkOutUsecase(
      attendanceId: todayRecord.id,
      checkInAt: todayRecord.checkInAt,
      checkOutLatitude: point?.latitude,
      checkOutLongitude: point?.longitude,
    );

    result.fold(
      (Failure f) => emit(AttendanceError(f)),
      (AttendanceRecord updated) => emit(
        AttendanceReady(current.copyWith(todayRecord: updated)),
      ),
    );
  }

  // ── سجل شخصي (My History) ──────────────────────────────────────

  /// يجلب سجل حضور المستخدم ضمن مدى تاريخي — افتراضياً آخر 30 يوماً.
  Future<void> loadHistory({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final AttendanceData? current = state.dataOrNull;
    if (current == null) return;

    emit(AttendanceReady(current.copyWith(isHistoryLoading: true)));

    final DateTime effectiveTo = to ?? DateTime.now();
    final DateTime effectiveFrom =
        from ?? effectiveTo.subtract(const Duration(days: 30));

    final ResultOf<List<AttendanceRecord>> result =
        await _getMyAttendanceHistoryUsecase(
      userId: userId,
      from: effectiveFrom,
      to: effectiveTo,
    );

    final AttendanceData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) => emit(
        AttendanceReady(latest.copyWith(isHistoryLoading: false)),
      ),
      (List<AttendanceRecord> records) => emit(
        AttendanceReady(
          latest.copyWith(history: records, isHistoryLoading: false),
        ),
      ),
    );
  }

  // ── مراقبة لحظية (سطح المكتب) ───────────────────────────────────

  /// يجلب لقطة اليوم الحالية لكل سجلات المشروع، ثم يبدأ الاستماع
  /// اللحظي (Realtime) لأي تسجيل/تحديث جديد — `attendance_monitor.dart`.
  Future<void> loadMonitor(String projectId) async {
    final AttendanceData? current = state.dataOrNull;
    if (current == null) return;

    emit(AttendanceReady(current.copyWith(isMonitorLoading: true)));

    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);

    final ResultOf<List<AttendanceRecord>> result =
        await _getProjectAttendanceUsecase(
      projectId: projectId,
      from: startOfDay,
      to: now,
    );

    final AttendanceData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) => emit(
        AttendanceReady(latest.copyWith(isMonitorLoading: false)),
      ),
      (List<AttendanceRecord> records) => emit(
        AttendanceReady(
          latest.copyWith(
            monitorRecords: records,
            isMonitorLoading: false,
            pendingApprovalCount:
                records.where((AttendanceRecord r) => r.status.isPending).length,
          ),
        ),
      ),
    );

    _startWatchingMonitor(projectId);
  }

  void _startWatchingMonitor(String projectId) {
    unawaited(_monitorSubscription?.cancel());
    _monitorSubscription =
        _watchProjectAttendanceUsecase(projectId).listen((AttendanceRecord updated) {
      final AttendanceData? latest = state.dataOrNull;
      if (latest == null) return;

      final List<AttendanceRecord> merged = <AttendanceRecord>[
        updated,
        ...latest.monitorRecords.where(
          (AttendanceRecord r) => r.id != updated.id,
        ),
      ];

      emit(
        AttendanceReady(
          latest.copyWith(
            monitorRecords: merged,
            pendingApprovalCount:
                merged.where((AttendanceRecord r) => r.status.isPending).length,
          ),
        ),
      );
    });
  }

  // ── تقرير شهري (سطح المكتب) ─────────────────────────────────────

  Future<void> loadReport({
    required String projectId,
    required DateTime month,
  }) async {
    final AttendanceData? current = state.dataOrNull;
    if (current == null) return;

    emit(
      AttendanceReady(
        current.copyWith(isReportLoading: true, reportMonth: month),
      ),
    );

    final DateTime from = DateTime(month.year, month.month);
    final DateTime to = DateTime(month.year, month.month + 1)
        .subtract(const Duration(seconds: 1));

    final ResultOf<List<AttendanceRecord>> result =
        await _getProjectAttendanceUsecase(
      projectId: projectId,
      from: from,
      to: to,
    );

    final AttendanceData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) => emit(
        AttendanceReady(latest.copyWith(isReportLoading: false)),
      ),
      (List<AttendanceRecord> records) => emit(
        AttendanceReady(
          latest.copyWith(reportRecords: records, isReportLoading: false),
        ),
      ),
    );
  }

  // ── اعتماد الحضور (مشرف/رئيس عمال) ──────────────────────────────

  Future<void> reviewAttendance({
    required String attendanceId,
    required bool approve,
    required String reviewerId,
  }) async {
    final AttendanceData? current = state.dataOrNull;
    if (current == null) return;

    final ResultOf<AttendanceRecord> result = await _reviewAttendanceUsecase(
      attendanceId: attendanceId,
      approve: approve,
      reviewerId: reviewerId,
    );

    result.fold(
      (Failure _) {},
      (AttendanceRecord updated) {
        final AttendanceData latest = state.dataOrNull ?? current;
        List<AttendanceRecord> replace(List<AttendanceRecord> list) => list
            .map((AttendanceRecord r) => r.id == updated.id ? updated : r)
            .toList(growable: false);

        emit(
          AttendanceReady(
            latest.copyWith(
              monitorRecords: replace(latest.monitorRecords),
              reportRecords: replace(latest.reportRecords),
              pendingApprovalCount: replace(latest.monitorRecords)
                  .where((AttendanceRecord r) => r.status.isPending)
                  .length,
            ),
          ),
        );
      },
    );
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  void _emitCheckInResult(
    AttendanceData baseline,
    ResultOf<AttendanceRecord> result,
  ) {
    result.fold(
      (Failure f) => emit(AttendanceError(f)),
      (AttendanceRecord record) {
        final AttendanceData updated = baseline.copyWith(
          todayRecord: record,
          lastCheckInDistanceMeters: record.distanceMeters,
        );
        emit(
          record.geofenceValid
              ? AttendanceCheckInSuccess(updated)
              : AttendanceCheckInGeofenceWarning(updated),
        );
      },
    );
  }

  Future<AttendanceRecord?> _loadTodayAttendance({
    required String userId,
    required String projectId,
  }) async {
    final ResultOf<AttendanceRecord?> result = await _getTodayAttendanceUsecase(
      userId: userId,
      projectId: projectId,
    );
    return result.fold(
      (Failure _) => null,
      (AttendanceRecord? record) => record,
    );
  }

  Future<GpsPermissionStatus> _readGpsStatus() async {
    final ResultOf<GpsPermissionStatus> result =
        await _locationService.ensurePermission();
    return result.fold(
      (Failure _) => GpsPermissionStatus.deniedOnce,
      (GpsPermissionStatus status) => status,
    );
  }

  @override
  Future<void> close() {
    unawaited(_monitorSubscription?.cancel());
    return super.close();
  }
}
