import '../../../core/errors/failure.dart';
import '../../entities/equipment.dart';
import '../../repositories/i_equipment_repository.dart';

/// 🆕 (Prompt 22) UseCase جلب معدة واحدة عبر معرّفها — تُستخدم عند
/// الدخول المباشر (Deep Link) لتفاصيل معدة دون المرور أولاً بسجل
/// المعدات الكامل المُحمَّل مسبقاً في `EquipmentCubit`، بنفس نمط
/// `GetDocumentByIdUsecase`.
class GetEquipmentByIdUsecase {
  const GetEquipmentByIdUsecase(this._repository);

  final IEquipmentRepository _repository;

  Future<ResultOf<Equipment>> call(String equipmentId) {
    return _repository.getEquipmentById(equipmentId);
  }
}
