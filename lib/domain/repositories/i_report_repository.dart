import '../../core/errors/failure.dart';
import '../entities/field_report.dart';

/// عقد الوصول إلى التقارير الميدانية (`public.field_reports`).
abstract interface class IReportRepository {
  /// يجلب تقريراً واحداً عبر معرّفه.
  Future<ResultOf<FieldReport>> getReportById(String reportId);

  /// يجلب تقارير مشروع محدد، مرتبة تنازلياً حسب `reportDate`.
  Future<ResultOf<List<FieldReport>>> getProjectReports(String projectId);

  /// يحفظ مسوّدة تقرير (إنشاء أو تحديث، طالما الحالة `draft`).
  Future<ResultOf<FieldReport>> saveDraft(FieldReport report);

  /// يقدّم التقرير للمراجعة (`draft` → `submitted`)، ويقفل تعديل حقول
  /// المحتوى بعدها (التحقق من ذلك مسؤولية `SubmitReportUsecase` +
  /// `ReportValidator` قبل استدعاء هذه الدالة).
  Future<ResultOf<FieldReport>> submitReport(String reportId);

  /// يعتمد أو يرفض تقريراً مُقدَّماً (`submitted` → `reviewed`/`rejected`).
  Future<ResultOf<FieldReport>> reviewReport({
    required String reportId,
    required bool approve,
    required String reviewerId,
    String? rejectionReason,
  });

  /// يرفع رابط توقيع رقمي (مشرف أو عميل) ويحدّث حقل التوقيع المطابق.
  Future<ResultOf<FieldReport>> attachSignature({
    required String reportId,
    String? supervisorSignatureUrl,
    String? clientSignatureUrl,
  });

  /// بث لحظي (Realtime) لأي تقرير جديد/محدَّث ضمن مشروع محدد —
  /// `reports_inbox.dart` (سطح المكتب، Prompt 17). Stream خام بلا غلاف
  /// [ResultOf]، بنفس نمط `IAttendanceRepository.watchProjectAttendance`. 🆕
  Stream<FieldReport> watchProjectReports(String projectId);
}
