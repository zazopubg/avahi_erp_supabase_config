import '../../../core/errors/failure.dart';
import '../../entities/app_user.dart';
import '../../repositories/i_auth_repository.dart';

/// UseCase جلب كل عضويات الشركة النشطة للمستخدم — يستخدمها
/// `AuthCubit` (Prompt 13) لحسم الحاجة لعرض شاشة اختيار الشركة.
class GetUserMembershipsUsecase {
  const GetUserMembershipsUsecase(this._repository);

  final IAuthRepository _repository;

  Future<ResultOf<List<AppUser>>> call(String userId) {
    return _repository.getUserMemberships(userId);
  }
}
