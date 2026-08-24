import '../../../core/errors/failure.dart';
import '../../entities/leave_request.dart';
import '../../repositories/i_leave_repository.dart';

/// UseCase جلب طلبات إجازة مستخدم واحد (الأحدث أولاً) — أساس
/// `my_leave_requests_screen.dart` (الهاتف، Prompt 24). 🆕
///
/// ⚠️ قرار تصميم: جلب طلبات الفريق الكاملة لمشرف/مدير
/// (`leave_requests_inbox.dart`، سطح المكتب) لا يمرّ عبر UseCase
/// منفصلة هنا — [ILeaveRepository.getCompanyLeaveRequests] عملية
/// قراءة خام بلا أي منطق عمل إضافي يستحق طبقة `UseCase` خاصة به
/// (بنفس منطق حقن `INotificationRepository`/`IPhotoRepository`
/// مباشرة في `NotificationsCubit`/`PhotosCubit`/`ReportFormCubit` —
/// انظر توثيق القرار الكامل في `LeaveCubit`).
class GetLeaveRequestsUsecase {
  const GetLeaveRequestsUsecase(this._repository);

  final ILeaveRepository _repository;

  Future<ResultOf<List<LeaveRequest>>> call(String userId) {
    return _repository.getUserLeaveRequests(userId);
  }
}
