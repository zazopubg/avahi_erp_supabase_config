import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// استعلامات مجمّعة لاستخدام المعدات، لتغذية لوحات
/// `features/equipment/` (Prompt 22) و`features/analytics/`
/// (Prompt 25) لاحقاً. 🆕
class EquipmentUsageQueries {
  EquipmentUsageQueries({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  /// إجمالي ساعات تشغيل كل معدات مشروع محدد.
  Future<ResultOf<double>> getProjectTotalUsageHours(String projectId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableEquipment)
          .select('usage_hours')
          .eq('project_id', projectId);

      final double total = rows.fold<double>(
        0,
        (double sum, Map<String, dynamic> row) =>
            sum + ((row['usage_hours'] as num?)?.toDouble() ?? 0),
      );

      return Right<Failure, double>(total);
    } catch (error, stackTrace) {
      return Left<Failure, double>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  /// عدد معدات الشركة حسب كل حالة (`available`/`in_use`/`maintenance`/
  /// `retired`)، لعرض بطاقات ملخّص سريعة.
  Future<ResultOf<Map<String, int>>> getCompanyEquipmentCountByStatus(
    String companyId,
  ) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableEquipment)
          .select('status')
          .eq('company_id', companyId);

      final Map<String, int> counts = <String, int>{
        'available': 0,
        'in_use': 0,
        'maintenance': 0,
        'retired': 0,
      };

      for (final Map<String, dynamic> row in rows) {
        final String status = row['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return Right<Failure, Map<String, int>>(counts);
    } catch (error, stackTrace) {
      return Left<Failure, Map<String, int>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  /// معدات مشروع محدد المستحقة لصيانة قريبة (خلال [withinDays] يوماً
  /// من الآن) — مؤشر تكميلي للتنبيه الآلي الصادر من Edge Function
  /// `equipment-alert`.
  Future<ResultOf<int>> getUpcomingMaintenanceCount({
    required String projectId,
    int withinDays = 7,
  }) async {
    try {
      final DateTime now = DateTime.now().toUtc();
      final DateTime horizon = now.add(Duration(days: withinDays));
      final String horizonDate = horizon.toIso8601String().split('T').first;

      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableEquipment)
          .select('id')
          .eq('project_id', projectId)
          .not('next_maintenance_due', 'is', null)
          .lte('next_maintenance_due', horizonDate);

      return Right<Failure, int>(rows.length);
    } catch (error, stackTrace) {
      return Left<Failure, int>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
