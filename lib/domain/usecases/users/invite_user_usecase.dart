import '../../../core/errors/failure.dart';
import '../../entities/app_user.dart';
import '../../enums/user_role.dart';
import '../../repositories/i_user_repository.dart';

/// UseCase دعوة مستخدم جديد إلى الشركة — `invite_user.dart` (Prompt
/// 26)، محصور بصلاحية `Permission.usersInvite`. 🆕
///
/// ⚠️ تحقّق تنسيق بريد بسيط هنا فقط (دفاعية إضافية قبل استدعاء
/// الشبكة — بنفس نمط `ReviewLeaveUsecase.call` أعلاه في التحقق من
/// حالة الطلب) وليس بديلاً عن `core/utils/validators.dart`
/// (`Validators.email`) المستخدَم فعلياً ضمن `TextFormField` نفسه في
/// `invite_user.dart` لتغذية فورية للمستخدم قبل حتى محاولة الإرسال.
/// التحقق الحقيقي من تفرّد البريد ضمن المستأجر وصحته الكاملة يبقى من
/// مسؤولية `invite-user` Edge Function (`service_role`، وحدها القادرة
/// فعلياً على استعلام `auth.users` عبر `supabaseAdmin.auth.admin`).
class InviteUserUsecase {
  const InviteUserUsecase(this._repository);

  final IUserRepository _repository;

  static final RegExp _emailPattern = RegExp(
    r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$',
  );

  Future<ResultOf<AppUser>> call({
    required String companyId,
    required String email,
    required String fullName,
    required UserRole role,
    String? jobTitle,
    String? phone,
  }) {
    final String trimmedEmail = email.trim();
    final String trimmedName = fullName.trim();

    if (!_emailPattern.hasMatch(trimmedEmail)) {
      return Future<ResultOf<AppUser>>.value(
        const Left<Failure, AppUser>(
          ValidationFailure(
            message: 'صيغة البريد الإلكتروني غير صحيحة.',
            code: 'users.invalid_email',
          ),
        ),
      );
    }

    if (trimmedName.isEmpty) {
      return Future<ResultOf<AppUser>>.value(
        const Left<Failure, AppUser>(
          ValidationFailure(
            message: 'الاسم الكامل مطلوب لإرسال الدعوة.',
            code: 'users.missing_full_name',
          ),
        ),
      );
    }

    return _repository.inviteUser(
      companyId: companyId,
      email: trimmedEmail,
      fullName: trimmedName,
      role: role,
      jobTitle: (jobTitle == null || jobTitle.trim().isEmpty)
          ? null
          : jobTitle.trim(),
      phone: (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
    );
  }
}
