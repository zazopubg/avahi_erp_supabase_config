import '../../../core/errors/failure.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/i_attendance_repository.dart';

/// UseCase جلب كل سجلات حضور مشروع ضمن مدى تاريخي — يغذّي كلاً من
/// لوحة المراقبة اللحظية (تحميل أولي قبل بدء البث) وتقرير الاستخراج
/// الشهري (`attendance_monitor.dart`/`attendance_report.dart`،
/// Prompt 15). 🆕
class GetProjectAttendanceUsecase {
  const GetProjectAttendanceUsecase(this._repository);

  final IAttendanceRepository _repository;

  Future<ResultOf<List<AttendanceRecord>>> call({
    required String projectId,
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.getProjectAttendance(
      projectId: projectId,
      from: from,
      to: to,
    );
  }
}
