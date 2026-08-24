import '../../core/errors/failure.dart';
import '../entities/field_report.dart';

/// تحقّقات نطاق `reports/`: يضمن اكتمال الحقول الجوهرية قبل السماح
/// بتقديم تقرير ميداني للمراجعة (`draft` → `submitted`)، ويمنع
/// تعديل تقرير بعد قفله.
abstract final class ReportValidator {
  /// يتحقق من اكتمال [report] قبل تقديمه للمراجعة. لا يسمح بالتقديم
  /// إلا من حالة `draft`، ويشترط وجود وصف للعمل المُنجز وعدد عمّال
  /// غير سالب على الأقل.
  static ResultOf<void> validateForSubmission(FieldReport report) {
    if (!report.status.isDraft) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'لا يمكن تقديم تقرير إلا من حالة المسوّدة (draft).',
          code: 'report.not_in_draft',
        ),
      );
    }

    final Map<String, String> fieldErrors = <String, String>{};

    if (report.workPerformed == null || report.workPerformed!.trim().isEmpty) {
      fieldErrors['workPerformed'] = 'وصف العمل المُنجز مطلوب قبل التقديم.';
    }

    if (report.laborCount < 0) {
      fieldErrors['laborCount'] = 'عدد العمّال لا يمكن أن يكون سالباً.';
    }

    if (fieldErrors.isNotEmpty) {
      return Left<Failure, void>(
        ValidationFailure(
          message: 'التقرير غير مكتمل ولا يمكن تقديمه.',
          code: 'report.incomplete',
          fieldErrors: fieldErrors,
        ),
      );
    }

    return const Right<Failure, void>(null);
  }

  /// يتحقق من أن [report] لا يزال قابلاً للتعديل (مسوّدة فقط). يُستخدم
  /// قبل أي حفظ لتعديلات المحتوى (`SaveDraftReportUsecase`).
  static ResultOf<void> validateEditable(FieldReport report) {
    if (!report.status.isDraft) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'لا يمكن تعديل تقرير بعد تقديمه للمراجعة.',
          code: 'report.locked',
        ),
      );
    }
    return const Right<Failure, void>(null);
  }

  /// يتحقق من أن [report] في حالة `submitted` قبل السماح بمراجعته
  /// (اعتماد/رفض) أو إرفاق توقيع رقمي عليه.
  static ResultOf<void> validateReviewable(FieldReport report) {
    if (!report.status.isSubmitted) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'لا يمكن مراجعة تقرير لم يُقدَّم بعد.',
          code: 'report.not_submitted',
        ),
      );
    }
    return const Right<Failure, void>(null);
  }
}
