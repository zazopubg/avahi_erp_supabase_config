import '../../../core/errors/failure.dart';
import '../../entities/app_user.dart';
import '../../repositories/i_user_repository.dart';

/// UseCase تفعيل/تعطيل عضوية مستخدم ضمن الشركة — `user_details.dart`
/// (Prompt 26)، محصور بصلاحية `Permission.usersDeactivate`. 🆕
///
/// ⚠️ تعطيل (`isActive: false`) لا يحذف عضوية `company_members` (سجل
/// تاريخي يبقى كاملاً لأغراض التدقيق `audit_logs`)، بل يمنع الوصول
/// فعلياً عبر سياسات RLS التي تتحقق من `is_active` — نفس أثر الحذف
/// الفعلي من منظور صلاحيات المستخدم، مع إمكانية إعادة التفعيل لاحقاً
/// بعكس الحذف.
class UpdateMemberStatusUsecase {
  const UpdateMemberStatusUsecase(this._repository);

  final IUserRepository _repository;

  Future<ResultOf<AppUser>> call({
    required String membershipId,
    required bool isActive,
  }) {
    return _repository.updateMemberStatus(
      membershipId: membershipId,
      isActive: isActive,
    );
  }
}
