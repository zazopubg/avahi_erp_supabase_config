import '../../../core/errors/failure.dart';
import '../../entities/equipment.dart';
import '../../repositories/i_equipment_repository.dart';

/// 🆕 (Prompt 22) UseCase جلب كل معدات الشركة، اختيارياً مصفّاة حسب
/// مشروع محدد — أساس `equipment_registry.dart` (سطح المكتب، بلا
/// [projectId] لعرض كل معدات الشركة معاً) و`my_equipment_screen.dart`
/// (الهاتف، عبر تصفية جانب العميل اللاحقة على [Equipment.assignedTo]
/// — انظر توثيق القرار الكامل في `EquipmentCubit.loadInitial`، إذ لا
/// يوجد استعلام "معداتي" مخصّص منفصل ضمن [IEquipmentRepository] ذاتها).
class GetCompanyEquipmentUsecase {
  const GetCompanyEquipmentUsecase(this._repository);

  final IEquipmentRepository _repository;

  Future<ResultOf<List<Equipment>>> call({String? projectId}) {
    return _repository.getCompanyEquipment(projectId: projectId);
  }
}
