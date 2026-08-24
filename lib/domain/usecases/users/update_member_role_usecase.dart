import '../../../core/errors/failure.dart';
import '../../entities/app_user.dart';
import '../../enums/user_role.dart';
import '../../repositories/i_user_repository.dart';

/// UseCase تحديث دور عضو ضمن الشركة — `user_roles_edit.dart`
/// (Prompt 26)، محصور بصلاحية `Permission.usersEditRoles`. 🆕
///
/// ⚠️ قرار تصميم مهم (بلا استدعاء Edge Function `sync-user-claims`
/// مباشرة من هنا): الخطة الأصلية لهذه الخطوة كانت استدعاء تلك الدالة
/// صراحةً عند الحفظ لتحديث JWT فوراً. لكن `sync-user-claims`
/// (`backend/supabase/functions/sync-user-claims/index.ts`، Prompt
/// 04) لا تتحقق من هوية عبر JWT مستخدم إطلاقاً — تتحقق فقط من سرّ
/// مشترك (`x-webhook-secret`/`DB_WEBHOOK_SECRET`) لأنها مصمَّمة صراحةً
/// لتُستدعى فقط عبر Database Webhook مضبوط على `company_members` في
/// Supabase Studio (انظر التوثيق أعلى تلك الدالة وتعليق
/// `ApiConstants` في `core/constants/api_constants.dart`: "لا تُستدعى
/// مباشرة من عميل Flutter"). كشف ذلك السرّ داخل تطبيق Flutter (حتى لو
/// شُفِّر) يُبطل الغرض الأمني منه بالكامل.
///
/// لذا [call] يكتفي بتحديث `company_members.role` عبر
/// [IUserRepository.updateMemberRole] فقط — وهذا التحديث نفسه (UPDATE
/// على الجدول) هو ما يُفعِّل تلقائياً Database Webhook فيُحدَّث
/// `app_metadata` (JWT) من جانب الخادم خلال ثوانٍ معدودة دون أي دور
/// إضافي للعميل، محقّقاً نية "تحديث الصلاحيات فوراً بعد الحفظ" بأمان
/// كامل بدل كسره.
class UpdateMemberRoleUsecase {
  const UpdateMemberRoleUsecase(this._repository);

  final IUserRepository _repository;

  Future<ResultOf<AppUser>> call({
    required String membershipId,
    required UserRole role,
  }) {
    return _repository.updateMemberRole(
      membershipId: membershipId,
      role: role,
    );
  }
}
