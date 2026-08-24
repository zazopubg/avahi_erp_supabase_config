import '../../../core/errors/failure.dart';
import '../../entities/leave_request.dart';
import '../../repositories/i_leave_repository.dart';

/// UseCase اعتماد أو رفض طلب إجازة من قبل المسؤول المباشر. 🆕
class ReviewLeaveUsecase {
  const ReviewLeaveUsecase(this._repository);

  final ILeaveRepository _repository;

  Future<ResultOf<LeaveRequest>> call({
    required LeaveRequest request,
    required bool approve,
    required String reviewerId,
    String? reviewNote,
  }) {
    if (!request.status.isPending) {
      return Future<ResultOf<LeaveRequest>>.value(
        const Left<Failure, LeaveRequest>(
          ValidationFailure(
            message: 'لا يمكن مراجعة طلب إجازة تمت مراجعته أو إلغاؤه مسبقاً.',
            code: 'leave.not_pending',
          ),
        ),
      );
    }

    return _repository.reviewLeave(
      leaveRequestId: request.id,
      approve: approve,
      reviewerId: reviewerId,
      reviewNote: reviewNote,
    );
  }
}
