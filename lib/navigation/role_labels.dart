import '../domain/enums/user_role.dart';

/// تسميات عربية موحّدة لعرض [UserRole] في واجهات التنقل (رأس القائمة
/// الجانبية، الشريط الجانبي لسطح المكتب، الشريط العلوي...).
///
/// ⚠️ مصدر عرض بحت فقط — لا علاقة له بـ `UserRole.fromName`/`.name`
/// المستخدمة للتخزين والمطابقة مع Supabase (`core/constants/roles.dart`)،
/// والتي تبقى بالإنجليزية دائماً. يُترجم لاحقاً فعلياً عبر ملفات
/// `assets/l10n/app_ar.arb`/`app_en.arb` عند ربط `AppLocalizations`
/// المولّدة فعلياً بكامل الواجهات (خارج نطاق هذه الخطوة).
extension UserRoleLabelX on UserRole {
  String get displayLabel => switch (this) {
        UserRole.worker => 'عامل ميداني',
        UserRole.foreman => 'رئيس عمال',
        UserRole.engineer => 'مهندس موقع',
        UserRole.projectManager => 'مدير مشروع',
        UserRole.admin => 'مدير النظام',
        UserRole.platformOwner => 'مالك المنصّة',
      };
}
