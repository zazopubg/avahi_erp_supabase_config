import '../../core/errors/failure.dart';
import '../entities/equipment.dart';

/// عقد الوصول إلى المعدات الميدانية (`public.equipment`). 🆕
abstract interface class IEquipmentRepository {
  /// يجلب معدة واحدة عبر معرّفها.
  Future<ResultOf<Equipment>> getEquipmentById(String equipmentId);

  /// يجلب كل معدات الشركة، اختيارياً مصفّاة حسب مشروع.
  Future<ResultOf<List<Equipment>>> getCompanyEquipment({String? projectId});

  /// يُسند معدة إلى مستخدم/مشروع (أو يلغي الإسناد عند تمرير `null`).
  Future<ResultOf<Equipment>> assignEquipment({
    required String equipmentId,
    String? assignedTo,
    String? projectId,
  });

  /// يحدّث ساعات التشغيل التراكمية لمعدة (يُستدعى بعد التحقق من
  /// `LogUsageHoursUsecase`).
  Future<ResultOf<Equipment>> updateUsageHours({
    required String equipmentId,
    required double newUsageHours,
  });

  /// يحدّث حالة المعدة (متاحة/قيد الاستخدام/صيانة/متقاعدة).
  Future<ResultOf<Equipment>> updateStatus({
    required String equipmentId,
    required String statusDbValue,
  });
}
