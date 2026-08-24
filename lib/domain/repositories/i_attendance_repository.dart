import '../../core/errors/failure.dart';
import '../entities/attendance_record.dart';

/// عقد الوصول إلى سجلات الحضور (`public.attendance`).
abstract interface class IAttendanceRepository {
  /// يسجّل حضوراً جديداً (Check-in). الاعتماد على [AttendanceRecord.clientMutationId]
  /// لضمان Idempotency عند إعادة المحاولة في وضع عدم الاتصال (upsert
  /// on-conflict-do-nothing في Supabase، Prompt 09).
  Future<ResultOf<AttendanceRecord>> checkIn(AttendanceRecord record);

  /// يسجّل انصرافاً (Check-out) لسجل حضور قائم.
  Future<ResultOf<AttendanceRecord>> checkOut({
    required String attendanceId,
    required DateTime checkOutAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
  });

  /// يجلب سجل حضور اليوم الحالي للمستخدم ضمن مشروع محدد، أو `null`
  /// داخل [Right] إن لم يسجّل حضوراً بعد اليوم.
  Future<ResultOf<AttendanceRecord?>> getTodayAttendance({
    required String userId,
    required String projectId,
  });

  /// يتحقق من صلاحية رمز QR الممسوح ويعيد معرّف المشروع المرتبط به،
  /// أو [Left] عند رمز غير صالح/منتهي.
  Future<ResultOf<String>> resolveProjectFromQrCode(String qrCodeId);

  /// يعتمد أو يرفض سجل حضور (صلاحية المشرف/رئيس العمال).
  Future<ResultOf<AttendanceRecord>> reviewAttendance({
    required String attendanceId,
    required bool approve,
    required String reviewerId,
  });

  /// سجلات حضور مستخدم واحد ضمن مدى تاريخي (`my_history_screen.dart`،
  /// Prompt 15) — قراءة محلية أولاً (Offline-first)، بنفس نمط
  /// [getTodayAttendance]. 🆕
  Future<ResultOf<List<AttendanceRecord>>> getMyHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  /// كل سجلات حضور مشروع ضمن مدى تاريخي — تُستخدم للوحة المراقبة
  /// اللحظية (`attendance_monitor.dart`) والتقرير الشهري
  /// (`attendance_report.dart`، Prompt 15). عملية إدارية (صلاحية
  /// [Permission.attendanceApproveTeam]/[Permission.attendanceViewAll])
  /// تتطلب اتصالاً بالخادم أساساً؛ التنفيذ المحلي يوفّر نسخة مخبّأة
  /// (Best-effort) فقط عند الانقطاع. 🆕
  Future<ResultOf<List<AttendanceRecord>>> getProjectAttendance({
    required String projectId,
    required DateTime from,
    required DateTime to,
  });

  /// بث لحظي (Realtime) لكل تسجيل/تحديث حضور جديد ضمن مشروع محدد —
  /// يعتمده `attendance_monitor.dart` (Prompt 15) لتحديث عداد
  /// "الحاضرين الآن" فوراً دون تحديث يدوي. بنفس نمط
  /// `IAuthRepository.watchAuthState()` (Stream خام، بلا غلاف
  /// [ResultOf] — الأخطاء هنا نادرة ومُدارة داخلياً عبر إعادة اتصال
  /// القناة، وليست حالة فشل عملية واحدة). 🆕
  Stream<AttendanceRecord> watchProjectAttendance(String projectId);
}
