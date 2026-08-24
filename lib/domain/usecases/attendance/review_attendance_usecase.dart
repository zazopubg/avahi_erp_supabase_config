import '../../../core/errors/failure.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/i_attendance_repository.dart';

/// UseCase اعتماد/رفض سجل حضور معلّق — صلاحية
/// [Permission.attendanceApproveTeam]، تُستهلك من `attendance_monitor.dart`
/// و`attendance_table.dart` (Prompt 15). 🆕
class ReviewAttendanceUsecase {
  const ReviewAttendanceUsecase(this._repository);

  final IAttendanceRepository _repository;

  Future<ResultOf<AttendanceRecord>> call({
    required String attendanceId,
    required bool approve,
    required String reviewerId,
  }) {
    return _repository.reviewAttendance(
      attendanceId: attendanceId,
      approve: approve,
      reviewerId: reviewerId,
    );
  }
}
