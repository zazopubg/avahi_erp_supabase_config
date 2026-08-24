import '../../../core/errors/failure.dart';
import '../../entities/field_report.dart';
import '../../repositories/i_report_repository.dart';
import '../../validators/report_validator.dart';

/// UseCase اعتماد أو رفض تقرير مُقدَّم (`submitted` → `reviewed`/`rejected`).
class ReviewReportUsecase {
  const ReviewReportUsecase(this._repository);

  final IReportRepository _repository;

  Future<ResultOf<FieldReport>> call({
    required FieldReport report,
    required bool approve,
    required String reviewerId,
    String? rejectionReason,
  }) async {
    final ResultOf<void> reviewableCheck = ReportValidator.validateReviewable(report);
    if (reviewableCheck.isLeft) {
      return reviewableCheck.fold(
        (Failure f) => Left<Failure, FieldReport>(f),
        (_) => throw StateError('unreachable'),
      );
    }

    return _repository.reviewReport(
      reportId: report.id,
      approve: approve,
      reviewerId: reviewerId,
      rejectionReason: rejectionReason,
    );
  }
}
