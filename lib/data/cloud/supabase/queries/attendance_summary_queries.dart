import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// استعلامات ملخّص حضور قابلة لإعادة الاستخدام عبر أكثر من ميزة
/// (لوحة تحكّم المشروع الآن، وتقارير `features/analytics/` لاحقاً في
/// Prompt 25). مفصولة عن [DashboardQueries] (`dashboard_queries.dart`)
/// لأن الأخيرة مُخصَّصة حصراً لتجميع مؤشرات لوحة مشروع واحدة دفعة
/// واحدة، بينما هذا الملف يوفّر استعلامات حضور مفردة أدق قابلة
/// للتركيب حسب الحاجة (نطاق تاريخ عام، حضور مستخدم واحد...).
class AttendanceSummaryQueries {
  AttendanceSummaryQueries({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  /// عدد سجلات الحضور (Check-in) لمشروع ضمن مدى زمني [from]–[to]
  /// (شامل الطرفين، بتوقيت UTC).
  Future<ResultOf<int>> getAttendanceCountInRange({
    required String projectId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableAttendance)
          .select('id')
          .eq('project_id', projectId)
          .gte('check_in_at', from.toUtc().toIso8601String())
          .lte('check_in_at', to.toUtc().toIso8601String());

      return Right<Failure, int>(rows.length);
    } catch (error, stackTrace) {
      return Left<Failure, int>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  /// عدد سجلات الحضور "المعلّقة" (`status = pending`) بانتظار اعتماد
  /// مشرف — مؤشر شائع لتنبيهات لوحة التحكّم.
  Future<ResultOf<int>> getPendingApprovalCount(String projectId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableAttendance)
          .select('id')
          .eq('project_id', projectId)
          .eq('status', 'pending');

      return Right<Failure, int>(rows.length);
    } catch (error, stackTrace) {
      return Left<Failure, int>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  /// إجمالي عدد أيام حضور مستخدم ضمن مدى زمني (لتقارير كشف الرواتب
  /// المستقبلية في `features/analytics/`، Prompt 25).
  Future<ResultOf<int>> getUserAttendanceDaysCount({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableAttendance)
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'approved')
          .gte('check_in_at', from.toUtc().toIso8601String())
          .lte('check_in_at', to.toUtc().toIso8601String());

      return Right<Failure, int>(rows.length);
    } catch (error, stackTrace) {
      return Left<Failure, int>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
