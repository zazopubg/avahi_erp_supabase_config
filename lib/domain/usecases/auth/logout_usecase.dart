import '../../../core/errors/failure.dart';
import '../../repositories/i_auth_repository.dart';

/// UseCase تسجيل الخروج وإنهاء الجلسة الحالية.
class LogoutUsecase {
  const LogoutUsecase(this._repository);

  final IAuthRepository _repository;

  Future<ResultOf<void>> call() => _repository.logout();
}
