import '../../core/errors/failure.dart';
import '../entities/leave_request.dart';

/// عقد الوصول إلى طلبات الإجازة (`public.leave_requests`). 🆕
abstract interface class ILeaveRepository {
  /// يجلب طلب إجازة واحداً عبر معرّفه.
  Future<ResultOf<LeaveRequest>> getLeaveRequestById(String leaveRequestId);

  /// يجلب طلبات إجازة مستخدم محدد.
  Future<ResultOf<List<LeaveRequest>>> getUserLeaveRequests(String userId);

  /// يجلب طلبات إجازة مستخدم تتداخل زمنياً مع مدى تاريخي معيّن —
  /// يُستخدم من [LeaveValidator] لمنع تداخل طلبين. يستثني الطلبات
  /// المرفوضة/الملغاة من نتيجة التداخل.
  Future<ResultOf<List<LeaveRequest>>> getOverlappingLeaveRequests({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// يجلب **كل** طلبات إجازة الشركة (كل الحالات معاً، الأحدث أولاً)
  /// — أساس `leave_requests_inbox.dart` (سطح المكتب، Prompt 24) لمشرف/
  /// مدير يملك [Permission.leaveRequestApproveTeam]؛ التصفية حسب
  /// الحالة والموظف (`statusFilter`/`employeeFilter`) تطبَّق لاحقاً
  /// على مستوى `LeaveCubit` نفسه وليس هنا، بنفس منطق
  /// `IReportRepository.getProjectAttendance` (تُجلب كل السجلات مرة
  /// واحدة، ثم تُصفَّى ضمن الحالة). 🆕
  Future<ResultOf<List<LeaveRequest>>> getCompanyLeaveRequests(
    String companyId,
  );

  /// يقدّم طلب إجازة جديداً.
  Future<ResultOf<LeaveRequest>> requestLeave(LeaveRequest request);

  /// يعتمد أو يرفض طلب إجازة.
  Future<ResultOf<LeaveRequest>> reviewLeave({
    required String leaveRequestId,
    required bool approve,
    required String reviewerId,
    String? reviewNote,
  });
}
