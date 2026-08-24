import '../../../../core/errors/failure.dart';
import '../../../../core/utils/gps_helper.dart';
import '../../../../domain/entities/attendance_record.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/enums/check_method.dart';

/// حالة `AttendanceCubit` الكاملة — Union Type مكتوب يدوياً (`sealed
/// class` + تفريغ أنماط `switch`)، بنفس نمط
/// `features/auth/presentation/state/auth_state.dart` و
/// `features/home/presentation/state/home_state.dart` تماماً (بلا
/// `freezed` — انظر التوثيق المفصّل في `auth_state.dart` لسبب هذا
/// القرار المعماري الثابت عبر كل الميزات).
sealed class AttendanceState {
  const AttendanceState();

  /// تفريغ أنماط شامل (Exhaustive) — كل الحالات الست إلزامية، بنفس
  /// التسميات المطلوبة تحديداً في Prompt 15: Loading / Ready /
  /// CheckInProgress / CheckInSuccess / CheckInGeofenceWarning / Error.
  T when<T>({
    required T Function() loading,
    required T Function(AttendanceData data) ready,
    required T Function(AttendanceData data) checkInProgress,
    required T Function(AttendanceData data) checkInSuccess,
    required T Function(AttendanceData data) checkInGeofenceWarning,
    required T Function(Failure failure) error,
  }) {
    final AttendanceState state = this;
    return switch (state) {
      AttendanceLoading() => loading(),
      AttendanceReady(:final data) => ready(data),
      AttendanceCheckInProgress(:final data) => checkInProgress(data),
      AttendanceCheckInSuccess(:final data) => checkInSuccess(data),
      AttendanceCheckInGeofenceWarning(:final data) =>
        checkInGeofenceWarning(data),
      AttendanceError(:final failure) => error(failure),
    };
  }

  /// تفريغ أنماط جزئي — كل الحالات اختيارية، مع [orElse] إلزامي كقيمة
  /// افتراضية لأي حالة غير مُمرَّرة.
  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(AttendanceData data)? ready,
    T Function(AttendanceData data)? checkInProgress,
    T Function(AttendanceData data)? checkInSuccess,
    T Function(AttendanceData data)? checkInGeofenceWarning,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      ready: ready ?? (_) => orElse(),
      checkInProgress: checkInProgress ?? (_) => orElse(),
      checkInSuccess: checkInSuccess ?? (_) => orElse(),
      checkInGeofenceWarning: checkInGeofenceWarning ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [AttendanceData] الحالية إن كانت الحالة تحملها (كل الحالات ما عدا
  /// [AttendanceLoading]/[AttendanceError])، أو `null` — مختصر مفيد
  /// للشاشات التي تحتاج قراءة البيانات الأخيرة المعروفة دون تفريغ
  /// أنماط كامل في كل مكان (مثال: عرض آخر بيانات معروفة فوق مؤشر
  /// تحميل صغير أثناء [AttendanceCheckInProgress]).
  AttendanceData? get dataOrNull => maybeWhen<AttendanceData?>(
        orElse: () => null,
        ready: (AttendanceData d) => d,
        checkInProgress: (AttendanceData d) => d,
        checkInSuccess: (AttendanceData d) => d,
        checkInGeofenceWarning: (AttendanceData d) => d,
      );
}

/// جارٍ التحميل الأولي (سجل اليوم + تحديد المشروع الحالي).
final class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

/// جاهزة لعرض شاشات الحضور — لا عملية تسجيل جارية حالياً.
final class AttendanceReady extends AttendanceState {
  const AttendanceReady(this.data);

  final AttendanceData data;
}

/// جارٍ تنفيذ عملية تسجيل حضور/انصراف حالياً (تعطيل الأزرار، إظهار
/// مؤشر تحميل).
final class AttendanceCheckInProgress extends AttendanceState {
  const AttendanceCheckInProgress(this.data);

  final AttendanceData data;
}

/// تم تسجيل الحضور بنجاح ضمن نطاق الجيوفنسينغ (`geofenceValid = true`).
final class AttendanceCheckInSuccess extends AttendanceState {
  const AttendanceCheckInSuccess(this.data);

  final AttendanceData data;
}

/// تم تسجيل الحضور فعلياً (السجل محفوظ)، لكن خارج نطاق الجيوفنسينغ
/// (`geofenceValid = false`) — تحذير تفاعلي غير حاجب
/// (`geofence_alert_banner.dart`)، وليس رفضاً صريحاً للعملية.
final class AttendanceCheckInGeofenceWarning extends AttendanceState {
  const AttendanceCheckInGeofenceWarning(this.data);

  final AttendanceData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً (مثال: فشل تحديد المشروع
/// الحالي أو جلب سجل اليوم). يعتمد `Retry` في الشاشة لإعادة
/// [AttendanceCubit.loadInitial].
final class AttendanceError extends AttendanceState {
  const AttendanceError(this.failure);

  final Failure failure;
}

/// حزمة بيانات ميزة الحضور المجمّعة — يحملها كل حالة ما عدا
/// [AttendanceLoading]/[AttendanceError]، بنفس نمط `HomeSummary`
/// (`features/home/presentation/state/home_state.dart`).
class AttendanceData {
  const AttendanceData({
    required this.project,
    required this.checkMethod,
    required this.gpsStatus,
    this.todayRecord,
    this.lastCheckInDistanceMeters,
    this.history = const <AttendanceRecord>[],
    this.isHistoryLoading = false,
    this.monitorRecords = const <AttendanceRecord>[],
    this.isMonitorLoading = false,
    this.reportRecords = const <AttendanceRecord>[],
    this.reportMonth,
    this.isReportLoading = false,
    this.pendingApprovalCount = 0,
  });

  /// المشروع الحالي المُحدَّد لتسجيل الحضور (أول مشروع نشط ضمن مشاريع
  /// المستخدم — نفس منطق `HomeCubit._loadCurrentProject`).
  final Project project;

  /// طريقة تسجيل الحضور المختارة حالياً في مبدّل GPS/QR أعلى شاشة
  /// الدخول (`check_in_screen.dart`).
  final CheckMethod checkMethod;

  /// آخر حالة معروفة لإذن/خدمة الموقع الجغرافي (`gps_status_indicator.dart`).
  final GpsPermissionStatus gpsStatus;

  /// سجل حضور اليوم الحالي للمستخدم ضمن [project]، أو `null` إن لم
  /// يسجّل حضوراً بعد اليوم.
  final AttendanceRecord? todayRecord;

  /// المسافة بالأمتار من آخر عملية تسجيل حضور (لعرضها ضمن
  /// `geofence_alert_banner.dart` عند التحذير).
  final double? lastCheckInDistanceMeters;

  /// سجل حضور المستخدم (30 يوماً الأخيرة افتراضياً) — `my_history_screen.dart`.
  final List<AttendanceRecord> history;
  final bool isHistoryLoading;

  /// سجلات المشروع اللحظية — `attendance_monitor.dart` (سطح المكتب).
  final List<AttendanceRecord> monitorRecords;
  final bool isMonitorLoading;

  /// سجلات المشروع للشهر المُختار — `attendance_report.dart`.
  final List<AttendanceRecord> reportRecords;
  final DateTime? reportMonth;
  final bool isReportLoading;

  /// عدد السجلات المعلّقة اعتماداً ضمن [monitorRecords] — مؤشر سريع
  /// لبطاقة إحصاءات `attendance_monitor.dart`.
  final int pendingApprovalCount;

  bool get hasCheckedInToday => todayRecord != null;
  bool get hasCheckedOutToday => todayRecord?.checkOutAt != null;

  AttendanceData copyWith({
    Project? project,
    CheckMethod? checkMethod,
    GpsPermissionStatus? gpsStatus,
    AttendanceRecord? todayRecord,
    bool clearTodayRecord = false,
    double? lastCheckInDistanceMeters,
    List<AttendanceRecord>? history,
    bool? isHistoryLoading,
    List<AttendanceRecord>? monitorRecords,
    bool? isMonitorLoading,
    List<AttendanceRecord>? reportRecords,
    DateTime? reportMonth,
    bool? isReportLoading,
    int? pendingApprovalCount,
  }) {
    return AttendanceData(
      project: project ?? this.project,
      checkMethod: checkMethod ?? this.checkMethod,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      todayRecord:
          clearTodayRecord ? null : (todayRecord ?? this.todayRecord),
      lastCheckInDistanceMeters:
          lastCheckInDistanceMeters ?? this.lastCheckInDistanceMeters,
      history: history ?? this.history,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      monitorRecords: monitorRecords ?? this.monitorRecords,
      isMonitorLoading: isMonitorLoading ?? this.isMonitorLoading,
      reportRecords: reportRecords ?? this.reportRecords,
      reportMonth: reportMonth ?? this.reportMonth,
      isReportLoading: isReportLoading ?? this.isReportLoading,
      pendingApprovalCount: pendingApprovalCount ?? this.pendingApprovalCount,
    );
  }
}
