import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// انتقالات صفحات موحّدة لاستخدامها ضمن `pageBuilder:` لأي `GoRoute`
/// (بدل `builder:` القياسي الذي يستخدم انتقال المنصّة الافتراضي فقط).
///
/// كل دالة هنا تُعيد [CustomTransitionPage] كاملة الإعداد (المدة
/// والمنحنى الزمني ثابتان ومتّسقان عبر التطبيق) — الاستدعاء البسيط:
///
/// ```dart
/// GoRoute(
///   path: RoutePaths.home,
///   name: RouteNames.home,
///   pageBuilder: (context, state) => AvahiPageTransitions.fade(
///     key: state.pageKey,
///     child: const HomePlaceholderScreen(),
///   ),
/// )
/// ```
abstract final class AvahiPageTransitions {
  static const Duration _duration = Duration(milliseconds: 220);

  /// تلاشٍ بسيط (Fade) — الانتقال الافتراضي المستخدم بين وجهات
  /// `AdaptiveShell` الرئيسية (`app_router.dart`): تبديل تبويب/قسم
  /// وليس "دخولاً" أعمق في التطبيق، فانتقال هادئ بلا حركة اتجاهية
  /// أنسب من انزلاق يوحي بتسلسل هرمي غير موجود فعلياً.
  static Page<void> fade({required LocalKey key, required Widget child}) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: _duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// انزلاق من اليمين (متوافق تلقائياً مع RTL عبر [SlideTransition]
  /// الذي يعتمد على [Directionality] المحيطة، انظر
  /// `ui/rtl/directionality_provider.dart`) — يُستخدم لمسارات "الدخول
  /// العميق" داخل ميزة واحدة (تفاصيل عنصر، نموذج إضافة...) بدل تبديل
  /// وجهة رئيسية.
  static Page<void> slide({required LocalKey key, required Widget child}) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: _duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Animatable<Offset> tween = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// بلا أي انتقال مرئي (فوري) — يُستخدم لتدفّق المصادقة
  /// (`splash`/`login`/`pin`/`companySelect`) حيث تكرار حركات دخول/
  /// خروج بين شاشات انتقالية قصيرة العمر مشتّت أكثر منه مفيداً.
  static Page<void> none({required LocalKey key, required Widget child}) {
    return NoTransitionPage<void>(key: key, child: child);
  }
}
