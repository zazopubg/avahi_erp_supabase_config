import '../../core/errors/failure.dart';
import '../entities/app_user.dart';

/// عقد طبقة المصادقة (Domain Interface). التنفيذ الفعلي (Supabase Auth)
/// يُبنى لاحقاً في `data/repositories_impl/` (Prompt 10)، فوق
/// `data/cloud/supabase/auth/` (Prompt 07). لا يحتوي هذا الملف أي
/// تنفيذ — Dart نقي 100%، بلا استيراد من Supabase أو Flutter.
abstract interface class IAuthRepository {
  /// يسجّل الدخول عبر البريد وكلمة المرور، ويعيد عضوية [AppUser]
  /// النشطة للمستخدم (قد يُطلب اختيار شركة لاحقاً إن تعددت العضويات
  /// — تُدار هذه الحالة في طبقة `presentation/features/auth/`).
  Future<ResultOf<AppUser>> login({
    required String email,
    required String password,
  });

  /// يسجّل الخروج وينهي الجلسة المحلية والسحابية.
  Future<ResultOf<void>> logout();

  /// يعيد المستخدم الحالي المسجّل دخوله، أو `null` داخل [Right] إن لم
  /// توجد جلسة نشطة (وليس [Left] — غياب الجلسة ليس فشلاً).
  Future<ResultOf<AppUser?>> getCurrentUser();

  /// يبث تغيّرات حالة المصادقة (تسجيل دخول/خروج، انتهاء صلاحية الجلسة)
  /// لتحديث `navigation/guards/` (Prompt 12) تفاعلياً.
  Stream<AppUser?> watchAuthState();

  /// يجلب **كل** عضويات الشركة النشطة للمستخدم [userId] (بخلاف
  /// [login]/[getCurrentUser] اللتين تُعيدان أول عضوية فقط). تستخدمها
  /// `features/auth/` (Prompt 13) لحسم الحاجة لعرض شاشة اختيار الشركة
  /// (`AuthNeedsCompanySelection`) عند تعدد العضويات.
  Future<ResultOf<List<AppUser>>> getUserMemberships(String userId);

  /// يرسل رسالة إعادة تعيين كلمة مرور إلى [email] (شاشة
  /// `forgot_password_screen.dart`، Prompt 13).
  Future<ResultOf<void>> sendPasswordResetEmail(String email);
}
