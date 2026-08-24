import 'package:flutter/widgets.dart';

/// أوضاع القالب العام (Shell) التي يتكيّف معها التطبيق بحسب عرض نافذة
/// المتصفح. هذا التصنيف يُستخدم لاحقاً من `lib/navigation/shells/`
/// (Prompt 12) لاختيار القالب المناسب (Mobile / Tablet / Desktop).
enum ShellMode {
  /// عرض ضيق يحاكي تجربة الهاتف: < 600.
  mobile,

  /// عرض متوسط يحاكي تجربة الجهاز اللوحي: 600 - 1024.
  tablet,

  /// عرض واسع يحاكي تجربة سطح المكتب: > 1024.
  desktop;

  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  /// يحدد [ShellMode] المناسب لعرض معين بالبيكسل المنطقي.
  static ShellMode fromWidth(double width) {
    if (width >= desktopBreakpoint) return ShellMode.desktop;
    if (width >= mobileBreakpoint) return ShellMode.tablet;
    return ShellMode.mobile;
  }

  bool get isMobile => this == ShellMode.mobile;
  bool get isTablet => this == ShellMode.tablet;
  bool get isDesktop => this == ShellMode.desktop;

  /// صحيح لأي وضع أوسع من الهاتف (لوحي أو سطح مكتب)، مفيد لقرارات
  /// عرض القوائم الجانبية بدلاً من شريط سفلي.
  bool get isWideLayout => this != ShellMode.mobile;
}

/// امتداد مساعد لاستخراج [ShellMode] مباشرة من [BuildContext].
extension ShellModeContextX on BuildContext {
  ShellMode get shellMode =>
      ShellMode.fromWidth(MediaQuery.sizeOf(this).width);
}
