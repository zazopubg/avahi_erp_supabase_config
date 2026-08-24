import '../../../core/errors/failure.dart';
import '../../entities/field_report.dart';
import '../../repositories/i_report_repository.dart';

/// UseCase جلب تقرير ميداني واحد عبر معرّفه — تُستخدم من
/// `report_preview_screen.dart`/`report_review_screen.dart` عند فتح
/// تقرير محدد مباشرة (مثال: رابط عميق أو الانتقال من `reports_inbox.dart`).
/// 🆕 (Prompt 17) — غلاف رقيق فوق [IReportRepository.getReportById]،
/// بنفس نمط بقية `UseCases` القرائية البسيطة في المشروع (`GetMyTasksUsecase`
/// ونحوها)، يبقي `presentation/` معتمدة على طبقة `domain/` حصراً دون أي
/// استدعاء مباشر لمستودعات `data/`.
class GetReportByIdUsecase {
  const GetReportByIdUsecase(this._repository);

  final IReportRepository _repository;

  Future<ResultOf<FieldReport>> call(String reportId) {
    return _repository.getReportById(reportId);
  }
}
