import '../../../core/errors/failure.dart';
import '../../entities/equipment.dart';
import '../../enums/equipment_status.dart';
import '../../repositories/i_equipment_repository.dart';

/// UseCase إسناد معدة إلى مستخدم/مشروع، مع تحديث حالتها تلقائياً إلى
/// `inUse` عند الإسناد، أو `available` عند إلغائه. 🆕
class AssignEquipmentUsecase {
  const AssignEquipmentUsecase(this._repository);

  final IEquipmentRepository _repository;

  Future<ResultOf<Equipment>> call({
    required Equipment equipment,
    String? assignedTo,
    String? projectId,
  }) async {
    if (equipment.status.isRetired) {
      return const Left<Failure, Equipment>(
        ValidationFailure(
          message: 'لا يمكن إسناد معدة أُخرجت نهائياً من الخدمة.',
          code: 'equipment.retired',
        ),
      );
    }

    if (equipment.status.isInMaintenance) {
      return const Left<Failure, Equipment>(
        ValidationFailure(
          message: 'المعدة قيد الصيانة حالياً ولا يمكن إسنادها.',
          code: 'equipment.in_maintenance',
        ),
      );
    }

    final ResultOf<Equipment> assignResult = await _repository.assignEquipment(
      equipmentId: equipment.id,
      assignedTo: assignedTo,
      projectId: projectId,
    );

    if (assignResult.isLeft) {
      return assignResult;
    }

    final Equipment updated = assignResult.getOrNull()!;
    final EquipmentStatus newStatus =
        assignedTo != null ? EquipmentStatus.inUse : EquipmentStatus.available;

    return _repository.updateStatus(
      equipmentId: updated.id,
      statusDbValue: newStatus.dbValue,
    );
  }
}
