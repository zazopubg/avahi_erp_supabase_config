import '../../../core/errors/failure.dart';
import '../../entities/app_user.dart';
import '../../repositories/i_auth_repository.dart';

/// UseCase جلب المستخدم الحالي المسجّل دخوله، إن وُجد.
class GetCurrentUserUsecase {
  const GetCurrentUserUsecase(this._repository);

  final IAuthRepository _repository;

  Future<ResultOf<AppUser?>> call() => _repository.getCurrentUser();
}
