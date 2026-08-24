import '../../core/errors/failure.dart';
import '../entities/punch_item.dart';

/// عقد الوصول إلى عناصر قائمة الملاحظات (`public.punch_items`).
abstract interface class IPunchRepository {
  /// يجلب عنصراً واحداً عبر معرّفه.
  Future<ResultOf<PunchItem>> getPunchItemById(String punchItemId);

  /// يجلب كل عناصر Punch List تابعة لمشروع محدد.
  Future<ResultOf<List<PunchItem>>> getProjectPunchItems(String projectId);

  /// ينشئ عنصر ملاحظات جديداً (اختيارياً مرتبطاً بتقرير ميداني).
  Future<ResultOf<PunchItem>> createPunchItem(PunchItem item);

  /// يغلق عنصر ملاحظات (`resolved`/`open` → `closed`).
  Future<ResultOf<PunchItem>> closePunchItem({
    required String punchItemId,
    required String closedBy,
  });
}
