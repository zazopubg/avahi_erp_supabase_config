import '../../../core/errors/failure.dart';
import '../../entities/field_report.dart';
import '../../repositories/i_report_repository.dart';
import '../../validators/report_validator.dart';

/// UseCase تقديم تقرير ميداني للمراجعة (`draft` → `submitted`).
/// يتحقق من اكتمال التقرير عبر [ReportValidator.validateForSubmission]
/// قبل استدعاء [IReportRepository.submitReport]، والذي يقفل تعديل
/// حقول المحتوى في طبقة `data/` بعد التقديم.
class SubmitReportUsecase {
  const SubmitReportUsecase(this._repository);

  final IReportRepository _repository;

  Future<ResultOf<FieldReport>> call(FieldReport report) async {
    final ResultOf<void> completionCheck =
        ReportValidator.validateForSubmission(report);
    if (completionCheck.isLeft) {
      return completionCheck.fold(
        (Failure f) => Left<Failure, FieldReport>(f),
        (_) => throw StateError('unreachable'),
      );
    }

    return _repository.submitReport(report.id);
  }
}
