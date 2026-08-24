import '../../../core/errors/failure.dart';
import '../../entities/equipment.dart';
import '../../enums/equipment_status.dart';
import '../../repositories/i_equipment_repository.dart';

/// 🆕 (Prompt 22) UseCase تحديث حالة معدة صراحةً (متاحة/قيد الاستخدام/
/// صيانة/متقاعدة) بمعزل عن تدفّق الإسناد الكامل في
/// [AssignEquipmentUsecase] — أساس إجراءات `maintenance_schedule.dart`
/// (إرسال معدة للصيانة، ثم إعادتها "متاحة" بعد إنجازها) و
/// `equipment_details.dart` (إخراج معدة نهائياً من الخدمة).
///
/// ⚠️ قرار تصميم مهم (تواريخ الصيانة غير محدَّثة هنا): طبقة `data/`
/// المبنية مسبقاً لهذه الميزة (`IEquipmentRepository`، Prompt 06/10)
/// لا تملك أي عملية لتحديث [Equipment.lastMaintenanceDate]/
/// [Equipment.nextMaintenanceDue] فعلياً على الخادم — فقط الحالة
/// وساعات التشغيل. لذا "إنجاز الصيانة" في هذه الخطوة يُحدّث الحالة
/// فقط (إلى [EquipmentStatus.available]) بلا تحديث فعلي لتاريخ آخر
/// صيانة على الخادم؛ توسيع هذا يتطلب أولاً توسيع طبقة `data/` (خارج
/// نطاق Prompt 22 هذا)، بنفس منطق قيود Offline الموثَّقة في
/// `PunchCubit`/`DocumentsCubit`.
class UpdateEquipmentStatusUsecase {
  const UpdateEquipmentStatusUsecase(this._repository);

  final IEquipmentRepository _repository;

  Future<ResultOf<Equipment>> call({
    required String equipmentId,
    required EquipmentStatus status,
  }) {
    return _repository.updateStatus(
      equipmentId: equipmentId,
      statusDbValue: status.dbValue,
    );
  }
}
