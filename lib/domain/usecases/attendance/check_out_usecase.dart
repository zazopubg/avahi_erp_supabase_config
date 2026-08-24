import '../../../core/errors/failure.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/i_attendance_repository.dart';
import '../../validators/attendance_validator.dart';

/// UseCase تسجيل انصراف (Check-out) لسجل حضور قائم.
class CheckOutUsecase {
  const CheckOutUsecase(this._repository);

  final IAttendanceRepository _repository;

  Future<ResultOf<AttendanceRecord>> call({
    required String attendanceId,
    required DateTime checkInAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
    DateTime? checkOutAt,
  }) {
    final DateTime effectiveCheckOutAt = checkOutAt ?? DateTime.now();

    final ResultOf<void> timesCheck = AttendanceValidator.validateCheckTimes(
      checkInAt: checkInAt,
      checkOutAt: effectiveCheckOutAt,
    );
    if (timesCheck.isLeft) {
      return Future<ResultOf<AttendanceRecord>>.value(
        timesCheck.fold(
          (Failure f) => Left<Failure, AttendanceRecord>(f),
          (_) => throw StateError('unreachable'),
        ),
      );
    }

    return _repository.checkOut(
      attendanceId: attendanceId,
      checkOutAt: effectiveCheckOutAt,
      checkOutLatitude: checkOutLatitude,
      checkOutLongitude: checkOutLongitude,
    );
  }
}
