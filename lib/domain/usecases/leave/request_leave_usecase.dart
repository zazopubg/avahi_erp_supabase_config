import '../../../core/errors/failure.dart';
import '../../../core/utils/id_generator.dart';
import '../../entities/leave_request.dart';
import '../../enums/leave_status.dart';
import '../../enums/leave_type.dart';
import '../../repositories/i_leave_repository.dart';
import '../../validators/leave_validator.dart';

/// UseCase تقديم طلب إجازة جديد. يتحقق من صحة المدى الزمني، ثم يجلب
/// طلبات المستخدم المتداخلة زمنياً عبر
/// [ILeaveRepository.getOverlappingLeaveRequests] ويتحقق من عدم
/// تداخلها عبر [LeaveValidator] قبل الإرسال. 🆕
class RequestLeaveUsecase {
  const RequestLeaveUsecase(this._repository);

  final ILeaveRepository _repository;

  Future<ResultOf<LeaveRequest>> call({
    required String companyId,
    required String userId,
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final ResultOf<void> rangeCheck = LeaveValidator.validateDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    if (rangeCheck.isLeft) {
      return rangeCheck.fold(
        (Failure f) => Left<Failure, LeaveRequest>(f),
        (_) => throw StateError('unreachable'),
      );
    }

    final ResultOf<List<LeaveRequest>> overlappingResult =
        await _repository.getOverlappingLeaveRequests(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    if (overlappingResult.isLeft) {
      return overlappingResult.fold(
        (Failure f) => Left<Failure, LeaveRequest>(f),
        (_) => throw StateError('unreachable'),
      );
    }

    final List<LeaveRequest> overlapping = overlappingResult.getOrNull()!;

    final ResultOf<void> overlapCheck = LeaveValidator.validateNoOverlap(
      startDate: startDate,
      endDate: endDate,
      existingRequests: overlapping,
    );
    if (overlapCheck.isLeft) {
      return overlapCheck.fold(
        (Failure f) => Left<Failure, LeaveRequest>(f),
        (_) => throw StateError('unreachable'),
      );
    }

    final DateTime now = DateTime.now();
    final LeaveRequest request = LeaveRequest(
      id: IdGenerator.v4(),
      companyId: companyId,
      userId: userId,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: LeaveStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.requestLeave(request);
  }
}
