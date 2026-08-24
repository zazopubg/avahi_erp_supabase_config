import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// استعلامات مجمّعة (Aggregation) لبيانات لوحة تحكّم مشروع واحد، تُغذّي
/// [IProjectRepository.getProjectDashboard]. الشكل النهائي لهذه
/// البيانات في واجهة المستخدم يُحسم لاحقاً في `features/projects/`
/// (Prompt 20) — هذه الطبقة توفّر فقط الأرقام الخام.
///
/// ⚠️ تنفيذ مبسّط عمداً لهذه الخطوة: يحسب حدود "اليوم" بالتوقيت UTC.
/// حساب دقيق حسب منطقة زمنية الشركة ([Company.timezone]) يمكن تحسينه
/// لاحقاً دون تغيير عقد الإرجاع (`Map<String, num>`).
class DashboardQueries {
  DashboardQueries({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  Future<ResultOf<Map<String, num>>> getProjectDashboard(String projectId) async {
    try {
      final DateTime now = DateTime.now().toUtc();
      final DateTime startOfDay = DateTime.utc(now.year, now.month, now.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      final List<Map<String, dynamic>> openTasks = await _client
          .from(ApiConstants.tableTasks)
          .select('id')
          .eq('project_id', projectId)
          .not('status', 'eq', 'done');

      final List<Map<String, dynamic>> openPunchItems = await _client
          .from(ApiConstants.tablePunchItems)
          .select('id')
          .eq('project_id', projectId)
          .inFilter('status', <String>['open', 'in_progress']);

      final List<Map<String, dynamic>> projectMembers = await _client
          .from(ApiConstants.tableProjectMembers)
          .select('user_id')
          .eq('project_id', projectId)
          .eq('is_active', true);

      final List<Map<String, dynamic>> todayAttendance = await _client
          .from(ApiConstants.tableAttendance)
          .select('id')
          .eq('project_id', projectId)
          .gte('check_in_at', startOfDay.toIso8601String())
          .lt('check_in_at', endOfDay.toIso8601String());

      final int membersCount = projectMembers.length;
      final int attendanceCount = todayAttendance.length;
      final double attendanceRate =
          membersCount == 0 ? 0 : (attendanceCount / membersCount).clamp(0, 1).toDouble();

      return Right<Failure, Map<String, num>>(<String, num>{
        'openTasksCount': openTasks.length,
        'openPunchItemsCount': openPunchItems.length,
        'projectMembersCount': membersCount,
        'todayAttendanceCount': attendanceCount,
        'todayAttendanceRate': attendanceRate,
      });
    } catch (error, stackTrace) {
      return Left<Failure, Map<String, num>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
