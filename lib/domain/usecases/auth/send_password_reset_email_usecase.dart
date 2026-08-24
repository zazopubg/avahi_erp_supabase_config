import '../../../core/errors/failure.dart';
import '../../repositories/i_auth_repository.dart';

/// UseCase إرسال رسالة إعادة تعيين كلمة المرور — `forgot_password_screen.dart`
/// (Prompt 13).
class SendPasswordResetEmailUsecase {
  const SendPasswordResetEmailUsecase(this._repository);

  final IAuthRepository _repository;

  Future<ResultOf<void>> call(String email) =>
      _repository.sendPasswordResetEmail(email);
}
