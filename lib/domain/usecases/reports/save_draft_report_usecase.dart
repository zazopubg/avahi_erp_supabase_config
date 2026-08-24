import '../../../core/errors/failure.dart';
import '../../entities/field_report.dart';
import '../../repositories/i_report_repository.dart';
import '../../validators/report_validator.dart';

/// UseCase حفظ مسوّدة تقرير ميداني (إنشاء أو تحديث). يتحقق أن
/// التقرير (عند وجوده مسبقاً) لا يزال قابلاً للتعديل عبر
/// [ReportValidator.validateEditable] قبل الحفظ.
class SaveDraftReportUsecase {
  const SaveDraftReportUsecase(this._repository);

  final IReportRepository _repository;

  Future<ResultOf<FieldReport>> call(FieldReport report) async {
    final ResultOf<void> editableCheck = ReportValidator.validateEditable(report);
    if (editableCheck.isLeft) {
      return editableCheck.fold(
        (Failure f) => Left<Failure, FieldReport>(f),
        (_) => throw StateError('unreachable'),
      );
    }

    return _repository.saveDraft(report);
  }
}
