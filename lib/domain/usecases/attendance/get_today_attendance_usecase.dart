import '../../../core/errors/failure.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/i_attendance_repository.dart';

/// UseCase جلب سجل حضور اليوم الحالي للمستخدم ضمن مشروع محدد (لعرض
/// زر "تسجيل حضور"/"تسجيل انصراف" المناسب في `features/attendance/`).
class GetTodayAttendanceUsecase {
  const GetTodayAttendanceUsecase(this._repository);

  final IAttendanceRepository _repository;

  Future<ResultOf<AttendanceRecord?>> call({
    required String userId,
    required String projectId,
  }) {
    return _repository.getTodayAttendance(userId: userId, projectId: projectId);
  }
}
