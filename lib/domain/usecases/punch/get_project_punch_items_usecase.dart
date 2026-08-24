import '../../../core/errors/failure.dart';
import '../../entities/punch_item.dart';
import '../../repositories/i_punch_repository.dart';

/// UseCase جلب كل عناصر Punch List تابعة لمشروع محدد — يغذّي كلاً من
/// `punch_list_screen.dart` (الهاتف، مشروع المستخدم الحالي) و
/// `punch_dashboard.dart` (سطح المكتب، يُستدعى مرة لكل مشروع من
/// مشاريع المستخدم عبر `PunchCubit.loadDashboard` لتجميع كل العيوب
/// المفتوحة عبر جميع المشاريع معاً) — بنفس نمط
/// `GetProjectTasksUsecase` (`domain/usecases/tasks/`) تماماً.
class GetProjectPunchItemsUsecase {
  const GetProjectPunchItemsUsecase(this._repository);

  final IPunchRepository _repository;

  Future<ResultOf<List<PunchItem>>> call(String projectId) {
    return _repository.getProjectPunchItems(projectId);
  }
}
