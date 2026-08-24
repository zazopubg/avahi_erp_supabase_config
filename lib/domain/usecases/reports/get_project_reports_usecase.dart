import '../../../core/errors/failure.dart';
import '../../entities/field_report.dart';
import '../../repositories/i_report_repository.dart';

/// UseCase جلب كل تقارير مشروع محدد (مرتّبة تنازلياً حسب تاريخ
/// التقرير) — تُستخدم من `my_reports_screen.dart`/`report_drafts_screen.dart`
/// (الهاتف) و`reports_archive.dart`/`report_export_screen.dart` (سطح
/// المكتب). 🆕 (Prompt 17) — غلاف رقيق فوق
/// [IReportRepository.getProjectReports]، بنفس نمط `GetProjectTasksUsecase`.
class GetProjectReportsUsecase {
  const GetProjectReportsUsecase(this._repository);

  final IReportRepository _repository;

  Future<ResultOf<List<FieldReport>>> call(String projectId) {
    return _repository.getProjectReports(projectId);
  }
}
