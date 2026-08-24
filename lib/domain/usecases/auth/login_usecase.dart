import '../../../core/errors/failure.dart';
import '../../entities/app_user.dart';
import '../../repositories/i_auth_repository.dart';

/// UseCase تسجيل الدخول عبر البريد وكلمة المرور. بسيط بمethod واحدة
/// (`call`) بحيث يمكن استدعاؤه كدالة مباشرة من `Cubit` الطبقة
/// الأعلى: `loginUsecase(email: ..., password: ...)`.
class LoginUsecase {
  const LoginUsecase(this._repository);

  final IAuthRepository _repository;

  Future<ResultOf<AppUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
