import '../../domain/entities/app_user.dart';
import '../route_names.dart';
import '../route_paths.dart';

/// حارس المصادقة: يمنع الوصول لأي مسار غير عام (`RouteNames.publicRoutes`)
/// بدون جلسة نشطة، ويمنع بالمقابل عودة مستخدم مسجَّل دخوله بالفعل إلى
/// شاشة تسجيل الدخول.
///
/// ⚠️ حارس **نقي (Pure)** بلا أي حالة أو استدعاء شبكة داخله عمداً: لا
/// يستقبل `IAuthRepository` مباشرة، بل يستقبل [AppUser]`?` جاهزاً —
/// مسؤولية جلب المستخدم الحالي (عبر `GetCurrentUserUsecase`) تبقى في
/// `app_router.dart` وحده (استدعاء شبكة/تخزين محلي واحد يُشارَك بين كل
/// الحراس بدل تكراره في كل حارس على حدة).
class AuthGuard {
  const AuthGuard();

  /// يُعيد مسار إعادة التوجيه المطلوب، أو `null` إن كان بالإمكان
  /// المتابعة للمسار المطلوب كما هو.
  String? redirect({
    required String? currentRouteName,
    required AppUser? currentUser,
  }) {
    final bool isLoggedIn = currentUser != null;

    // مسار البداية (`/`) ليس وجهة فعلية أبداً — يُحسم دائماً وفوراً
    // لأحد المسارين، بخلاف بقية مسارات الدخول العامة (login/pin/
    // companySelect) التي *يجوز* البقاء عليها فعلياً أثناء تدفّق
    // الدخول نفسه. لولا هذه الحالة الخاصة، سيبقى المستخدم عالقاً إلى
    // الأبد على [SplashScreen] لأن `splash` مُدرَج أصلاً ضمن
    // [RouteNames.publicRoutes] (لتمييزه كمسار لا يتطلب جلسة)، فلا
    // يُفعِّل شرط "لا جلسة + مسار محمي" أدناه إطلاقاً بمفرده.
    if (currentRouteName == RouteNames.splash) {
      return isLoggedIn ? RoutePaths.home : RoutePaths.login;
    }

    final bool isPublicRoute =
        currentRouteName != null &&
        RouteNames.publicRoutes.contains(currentRouteName);

    // لا جلسة + مسار محمي → إعادة توجيه لتسجيل الدخول.
    if (!isLoggedIn && !isPublicRoute) {
      return RoutePaths.login;
    }

    // جلسة نشطة بالفعل + محاولة الوصول لشاشة تسجيل الدخول تحديداً
    // (وليس بقية مسارات الدخول العامة مثل `pin`/`companySelect` التي
    // قد يحتاجها مستخدم مسجَّل دخوله جزئياً أثناء تدفّق اختيار الشركة)
    // → إعادة توجيه للرئيسية مباشرة بدل عرض نموذج دخول لا معنى له.
    if (isLoggedIn && currentRouteName == RouteNames.login) {
      return RoutePaths.home;
    }

    return null;
  }
}
