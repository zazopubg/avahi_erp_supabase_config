import '../../entities/field_report.dart';
import '../../repositories/i_report_repository.dart';

/// UseCase بث لحظي (Realtime) لتحديثات تقارير مشروع — يعتمده
/// `reports_inbox.dart` (سطح المكتب، Prompt 17) لعرض التقارير الواردة
/// حيّة دون إعادة جلب يدوي. Stream خام بلا غلاف [ResultOf]، بنفس نمط
/// `WatchProjectAttendanceUsecase` (`features/attendance/`، Prompt 15). 🆕
class WatchProjectReportsUsecase {
  const WatchProjectReportsUsecase(this._repository);

  final IReportRepository _repository;

  Stream<FieldReport> call(String projectId) {
    return _repository.watchProjectReports(projectId);
  }
}
