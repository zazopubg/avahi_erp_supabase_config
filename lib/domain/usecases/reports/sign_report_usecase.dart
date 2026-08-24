import '../../../core/errors/failure.dart';
import '../../entities/field_report.dart';
import '../../repositories/i_report_repository.dart';

/// UseCase رفع توقيع رقمي (مشرف أو عميل) على تقرير ميداني، وتحديث
/// `supervisorSignatureUrl`/`clientSignatureUrl` المطابق. 🆕
///
/// يشترط تمرير توقيع واحد على الأقل من النوعين في كل استدعاء.
class SignReportUsecase {
  const SignReportUsecase(this._repository);

  final IReportRepository _repository;

  Future<ResultOf<FieldReport>> call({
    required String reportId,
    String? supervisorSignatureUrl,
    String? clientSignatureUrl,
  }) {
    if (supervisorSignatureUrl == null && clientSignatureUrl == null) {
      return Future<ResultOf<FieldReport>>.value(
        const Left<Failure, FieldReport>(
          ValidationFailure(
            message: 'يجب تمرير رابط توقيع واحد على الأقل (مشرف أو عميل).',
            code: 'report.missing_signature',
          ),
        ),
      );
    }

    return _repository.attachSignature(
      reportId: reportId,
      supervisorSignatureUrl: supervisorSignatureUrl,
      clientSignatureUrl: clientSignatureUrl,
    );
  }
}
