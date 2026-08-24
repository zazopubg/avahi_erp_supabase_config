import '../../../core/errors/failure.dart';
import '../../entities/punch_item.dart';
import '../../repositories/i_punch_repository.dart';

/// UseCase إغلاق عنصر ملاحظات نهائياً. يشترط ألا يكون مغلقاً مسبقاً.
class ClosePunchItemUsecase {
  const ClosePunchItemUsecase(this._repository);

  final IPunchRepository _repository;

  Future<ResultOf<PunchItem>> call({
    required PunchItem item,
    required String closedBy,
  }) {
    if (item.status.isClosed) {
      return Future<ResultOf<PunchItem>>.value(
        const Left<Failure, PunchItem>(
          ValidationFailure(
            message: 'عنصر الملاحظات مغلق بالفعل.',
            code: 'punch.already_closed',
          ),
        ),
      );
    }

    return _repository.closePunchItem(punchItemId: item.id, closedBy: closedBy);
  }
}
