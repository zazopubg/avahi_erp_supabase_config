import '../../core/constants/permissions.dart';
import '../../domain/entities/app_user.dart';
import '../nav_destinations.dart';
import '../route_paths.dart';

/// حارس الأدوار: يتحقق أن [AppUser.role] الحالي يملك [Permission]
/// المطلوبة للمسار المطلوب، اعتماداً على `core/constants/permissions.dart`
/// (Prompt 02) عبر `RolePermissions.has`.
///
/// ⚠️ يعتمد نفس خريطة [AppNavDestinations.all] (`nav_destinations.dart`)
/// التي تُبنى منها القوائم الجانبية/السفلية — بحيث تبقى "الوجهة الظاهرة
/// في القائمة" و"الوجهة المسموح الوصول إليها فعلياً" متطابقتين دائماً
/// من مصدر واحد، بدل خريطتين منفصلتين قد تتباعدان بمرور الوقت.
///
/// لا يتحقق هذا الحارس من غياب الجلسة أصلاً (مسؤولية [AuthGuard] التي
/// تُنفَّذ أولاً في `app_router.dart` — إن وصل التنفيذ لهذا الحارس
/// وكان [AppUser]`?` ما زال `null`، فهذا يعني أن المسار عام أصلاً ولا
/// حاجة لأي تحقق صلاحيات عليه).
class RoleGuard {
  const RoleGuard();

  String? redirect({
    required String? currentRouteName,
    required AppUser? currentUser,
  }) {
    if (currentUser == null) return null;

    final Permission? requiredPermission = AppNavDestinations.all
        .where((d) => d.routeName == currentRouteName)
        .map((d) => d.requiredPermission)
        .firstOrNull;

    if (requiredPermission == null) return null;

    final bool hasPermission = RolePermissions.has(
      currentUser.role,
      requiredPermission,
    );

    // مستخدم لا يملك الصلاحية المطلوبة لهذا المسار المحدد → إعادة
    // توجيه للرئيسية (وليس لصفحة 404 — المسار موجود فعلاً، لكنه غير
    // متاح لدوره تحديداً).
    return hasPermission ? null : RoutePaths.home;
  }
}

/// امتداد داخلي صغير بديل عن `firstWhereOrNull` (حزمة `collection`)
/// لتفادي إضافة تبعية جديدة لعملية بسيطة واحدة.
extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
