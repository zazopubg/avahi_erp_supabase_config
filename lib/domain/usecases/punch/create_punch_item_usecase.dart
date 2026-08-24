import '../../../core/errors/failure.dart';
import '../../entities/punch_item.dart';
import '../../repositories/i_punch_repository.dart';

/// UseCase إنشاء عنصر ملاحظات جديد ضمن قائمة Punch List لمشروع.
class CreatePunchItemUsecase {
  const CreatePunchItemUsecase(this._repository);

  final IPunchRepository _repository;

  Future<ResultOf<PunchItem>> call(PunchItem item) {
    return _repository.createPunchItem(item);
  }
}
