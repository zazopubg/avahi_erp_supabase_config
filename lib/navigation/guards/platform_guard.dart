import '../../core/platform/shell_mode.dart';
import '../nav_destinations.dart';
import '../route_names.dart';
import '../route_paths.dart';

/// حارس المنصّة: يمنع الوصول المباشر (عبر رابط) لأي مسار مُعلَّم
/// [NavDestination.isDesktopOnly] عندما يكون عرض نافذة المتصفح الحالي
/// ضمن [ShellMode.mobile].
///
/// ⚠️ ملاحظة تصميم مهمة: هذا **ليس** حارس منصّة تشغيل فعلية (iOS/
/// Android مقابل Web/Desktop) — التطبيق يعمل على الويب فقط حالياً
/// (`core/platform/platform_detector.dart`، Prompt 02). المقصود هنا
/// تحديداً منع مسارات لا معنى فعلياً لعرضها ضمن نافذة متصفح ضيّقة
/// (تحاكي شكل الهاتف عبر [ShellMode.fromWidth])، مثل `/platform-admin`
/// التي تتطلب جداول/لوحات بيانات عريضة، بغض النظر عن جهاز المستخدم
/// الفعلي — إعادة تكبير نافذة المتصفح تكفي لإتاحتها من جديد فوراً (لا
/// حاجة لإعادة تسجيل دخول أو أي إجراء آخر).
class PlatformGuard {
  const PlatformGuard();

  /// ✅ Prompt 16: مسارات محمية إضافية لسطح المكتب فقط **خارج**
  /// [AppNavDestinations.all] عمداً — `RouteNames.tasksBoard`
  /// (`/tasks/board`) ليست وجهة تنقّل رئيسية بذاتها (لا تظهر في
  /// الشريط السفلي/القائمة الجانبية)، بل مسار فرعي يُفتح فقط من زر
  /// داخل `tasks_list_screen.dart`؛ إضافتها إلى [AppNavDestinations.all]
  /// كانت ستُظهرها خطأً كوجهة تنقّل مستقلة في `sidebar.dart`. لكل مسار
  /// هنا وجهة عودة مخصَّصة (بدل `RoutePaths.home` الافتراضي) أكثر
  /// ملاءمة لسياقه.
  static const Map<String, String> _additionalDesktopOnlyRoutes =
      <String, String>{RouteNames.tasksBoard: RoutePaths.tasks};

  String? redirect({
    required String? currentRouteName,
    required ShellMode currentShellMode,
  }) {
    if (!currentShellMode.isMobile) return null;

    if (currentRouteName != null &&
        _additionalDesktopOnlyRoutes.containsKey(currentRouteName)) {
      return _additionalDesktopOnlyRoutes[currentRouteName];
    }

    final bool isDesktopOnlyRoute = AppNavDestinations.all.any(
      (d) => d.routeName == currentRouteName && d.isDesktopOnly,
    );

    return isDesktopOnlyRoute ? RoutePaths.home : null;
  }
}
