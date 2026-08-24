import '../../entities/attendance_record.dart';
import '../../repositories/i_attendance_repository.dart';

/// UseCase بث لحظي (Realtime) لتحديثات حضور مشروع — يعتمده
/// `attendance_monitor.dart` (Prompt 15). Stream خام بلا غلاف
/// [ResultOf]، بنفس نمط `IAuthRepository.watchAuthState()`. 🆕
class WatchProjectAttendanceUsecase {
  const WatchProjectAttendanceUsecase(this._repository);

  final IAttendanceRepository _repository;

  Stream<AttendanceRecord> call(String projectId) {
    return _repository.watchProjectAttendance(projectId);
  }
}
