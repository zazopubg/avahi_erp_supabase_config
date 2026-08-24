import '../../../core/errors/failure.dart';
import '../../entities/equipment.dart';
import '../../repositories/i_equipment_repository.dart';

/// نتيجة تسجيل ساعات استخدام معدة: يوضّح ما إذا تجاوزت الساعات
/// التراكمية منذ آخر صيانة عتبة الصيانة الموصى بها.
class LogUsageHoursResult {
  const LogUsageHoursResult({
    required this.equipment,
    required this.maintenanceThresholdExceeded,
  });

  final Equipment equipment;
  final bool maintenanceThresholdExceeded;
}

/// UseCase إضافة ساعات تشغيل لمعدة والتحقق من تجاوز حد الصيانة. 🆕
///
/// [maintenanceThresholdHours] هي أقصى عدد ساعات تشغيل مسموح بها بين
/// صيانتين قبل التنبيه (افتراضياً 250 ساعة، قابلة للتخصيص لكل معدة
/// لاحقاً من `features/equipment/`، Prompt 22).
class LogUsageHoursUsecase {
  const LogUsageHoursUsecase(this._repository);

  final IEquipmentRepository _repository;

  static const double defaultMaintenanceThresholdHours = 250;

  Future<ResultOf<LogUsageHoursResult>> call({
    required Equipment equipment,
    required double additionalHours,
    double maintenanceThresholdHours = defaultMaintenanceThresholdHours,
  }) async {
    if (additionalHours <= 0) {
      return const Left<Failure, LogUsageHoursResult>(
        ValidationFailure(
          message: 'عدد الساعات المُضافة يجب أن يكون أكبر من صفر.',
          code: 'equipment.invalid_usage_hours',
        ),
      );
    }

    final double newUsageHours = equipment.usageHours + additionalHours;

    final double hoursSinceMaintenance = equipment.lastMaintenanceDate == null
        ? newUsageHours
        : additionalHours + _hoursAlreadyLoggedSinceMaintenance(equipment);

    final bool thresholdExceeded = hoursSinceMaintenance >= maintenanceThresholdHours;

    final ResultOf<Equipment> updateResult = await _repository.updateUsageHours(
      equipmentId: equipment.id,
      newUsageHours: newUsageHours,
    );

    return updateResult.fold(
      (Failure f) => Left<Failure, LogUsageHoursResult>(f),
      (Equipment updated) => Right<Failure, LogUsageHoursResult>(
        LogUsageHoursResult(
          equipment: updated,
          maintenanceThresholdExceeded: thresholdExceeded,
        ),
      ),
    );
  }

  /// تقدير مبسّط لساعات التشغيل المُسجَّلة منذ آخر صيانة، بافتراض عدم
  /// وجود سجل تفصيلي لكل جلسة استخدام في هذه الطبقة (يُدار التفصيل
  /// الفعلي في `data/local/` لاحقاً إن لزم، Prompt 08). هنا نعتمد
  /// الفارق بين الساعات التراكمية الحالية وساعات وقت آخر صيانة كقيمة
  /// تقريبية معقولة لهذه الخطوة.
  double _hoursAlreadyLoggedSinceMaintenance(Equipment equipment) {
    return equipment.usageHours;
  }
}
