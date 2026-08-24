import '../../core/errors/failure.dart';
import '../entities/leave_request.dart';

/// تحقّقات نطاق `leave/`: صحة المدى الزمني للطلب، وعدم تداخله مع
/// طلبات إجازة أخرى قائمة لنفس المستخدم (معتمدة أو بانتظار الاعتماد).
abstract final class LeaveValidator {
  /// يتحقق من أن تاريخ البداية لا يسبق اليوم (لا إجازات بأثر رجعي)
  /// وأن تاريخ النهاية لاحق أو مساوٍ لتاريخ البداية.
  static ResultOf<void> validateDateRange({
    required DateTime startDate,
    required DateTime endDate,
    DateTime? now,
  }) {
    if (endDate.isBefore(startDate)) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'تاريخ نهاية الإجازة لا يمكن أن يسبق تاريخ بدايتها.',
          code: 'leave.end_before_start',
        ),
      );
    }

    final DateTime today = _dateOnly(now ?? DateTime.now());
    if (_dateOnly(startDate).isBefore(today)) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'لا يمكن تقديم طلب إجازة بتاريخ بداية في الماضي.',
          code: 'leave.start_in_past',
        ),
      );
    }

    return const Right<Failure, void>(null);
  }

  /// يتحقق من عدم تداخل المدى الزمني الجديد ([startDate]..[endDate])
  /// مع أي من [existingRequests] (المفترض أنها مُصفّاة مسبقاً من
  /// `IarrayLeaveRepository.getOverlappingLeaveRequests` لتشمل فقط
  /// الطلبات المعتمدة/بانتظار الاعتماد لنفس المستخدم).
  static ResultOf<void> validateNoOverlap({
    required DateTime startDate,
    required DateTime endDate,
    required List<LeaveRequest> existingRequests,
  }) {
    final bool hasOverlap = existingRequests.any((LeaveRequest existing) {
      if (existing.status.isRejected || existing.status.isCancelled) {
        return false;
      }
      return startDate.isBefore(existing.endDate.add(const Duration(days: 1))) &&
          endDate.isAfter(existing.startDate.subtract(const Duration(days: 1)));
    });

    if (hasOverlap) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'يوجد طلب إجازة آخر يتداخل مع هذا المدى الزمني.',
          code: 'leave.overlapping_request',
        ),
      );
    }

    return const Right<Failure, void>(null);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
