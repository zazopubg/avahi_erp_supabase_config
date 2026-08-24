import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/field_report.dart';
import '../../../../domain/repositories/i_report_repository.dart';
import '../../../dto/field_report_dto.dart';
import '../realtime/report_subscription.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IReportRepository] فوق جدول `public.field_reports` عبر
/// Supabase. تحديث حالة `status` نتيجة `submitReport`/`reviewReport`
/// يُنفَّذ عبر تحديث مباشر على الجدول — الإشعارات الناتجة (اعتماد/رفض)
/// تُطلَق تلقائياً من طرف الخادم عبر Database Webhook إلى Edge
/// Function `report-notifications` (انظر
/// `backend/supabase/functions/report-notifications/`، Prompt 04)،
/// وتصل للعميل لاحقاً عبر `realtime/notification_subscription.dart`
/// وليس عبر استدعاء مباشر من هذه الطبقة.
class ReportRepositoryImpl implements IReportRepository {
  ReportRepositoryImpl({sb.SupabaseClient? client, ReportSubscription? subscription})
      : _client = client ?? SupabaseClientProvider.client,
        _subscription = subscription ?? ReportSubscription();

  final sb.SupabaseClient _client;
  final ReportSubscription _subscription;

  @override
  Future<ResultOf<FieldReport>> getReportById(String reportId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableFieldReports)
          .select()
          .eq('id', reportId)
          .single();
      return Right<Failure, FieldReport>(FieldReportDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, FieldReport>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<FieldReport>>> getProjectReports(String projectId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableFieldReports)
          .select()
          .eq('project_id', projectId)
          .order('report_date', ascending: false);

      return Right<Failure, List<FieldReport>>(
        rows.map((Map<String, dynamic> row) => FieldReportDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<FieldReport>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<FieldReport>> saveDraft(FieldReport report) async {
    try {
      // ⚠️ اصطلاح "إنشاء أو تحديث" المُشار إليه في عقد
      // [IReportRepository.saveDraft]: تقرير جديد يُمرَّر بـ
      // `id.isEmpty` (لم يُخصَّص له معرّف من قاعدة البيانات بعد)، بينما
      // تقرير قائم يُمرَّر بـ `id` فعلي فيُحدَّث بدلاً من إنشاء صف جديد.
      final Map<String, dynamic> row;
      if (report.id.isEmpty) {
        row = await _client
            .from(ApiConstants.tableFieldReports)
            .insert(FieldReportDto.fromEntity(report).toDraftJson())
            .select()
            .single();
      } else {
        row = await _client
            .from(ApiConstants.tableFieldReports)
            .update(FieldReportDto.fromEntity(report).toDraftJson())
            .eq('id', report.id)
            .select()
            .single();
      }
      return Right<Failure, FieldReport>(FieldReportDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, FieldReport>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<FieldReport>> submitReport(String reportId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableFieldReports)
          .update(<String, dynamic>{'status': 'submitted'})
          .eq('id', reportId)
          .select()
          .single();
      return Right<Failure, FieldReport>(FieldReportDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, FieldReport>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<FieldReport>> reviewReport({
    required String reportId,
    required bool approve,
    required String reviewerId,
    String? rejectionReason,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableFieldReports)
          .update(<String, dynamic>{
            'status': approve ? 'reviewed' : 'rejected',
            'reviewed_by': reviewerId,
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
            'rejection_reason': approve ? null : rejectionReason,
          })
          .eq('id', reportId)
          .select()
          .single();
      return Right<Failure, FieldReport>(FieldReportDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, FieldReport>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<FieldReport>> attachSignature({
    required String reportId,
    String? supervisorSignatureUrl,
    String? clientSignatureUrl,
  }) async {
    try {
      final DateTime now = DateTime.now().toUtc();
      final Map<String, dynamic> patch = <String, dynamic>{
        if (supervisorSignatureUrl != null) ...<String, dynamic>{
          'supervisor_signature_url': supervisorSignatureUrl,
          'supervisor_signed_at': now.toIso8601String(),
        },
        if (clientSignatureUrl != null) ...<String, dynamic>{
          'client_signature_url': clientSignatureUrl,
          'client_signed_at': now.toIso8601String(),
        },
      };

      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableFieldReports)
          .update(patch)
          .eq('id', reportId)
          .select()
          .single();
      return Right<Failure, FieldReport>(FieldReportDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, FieldReport>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Stream<FieldReport> watchProjectReports(String projectId) {
    return _subscription.watchProjectReports(projectId);
  }
}
