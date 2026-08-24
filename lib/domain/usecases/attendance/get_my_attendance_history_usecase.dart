import '../../../core/errors/failure.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/i_attendance_repository.dart';

/// UseCase جلب سجلات حضور المستخدم الحالي ضمن مدى تاريخي —
/// `my_history_screen.dart` (Prompt 15). 🆕
class GetMyAttendanceHistoryUsecase {
  const GetMyAttendanceHistoryUsecase(this._repository);

  final IAttendanceRepository _repository;

  Future<ResultOf<List<AttendanceRecord>>> call({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.getMyHistory(userId: userId, from: from, to: to);
  }
}
