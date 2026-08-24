import 'package:flutter/material.dart';

import '../../platform/shell_mode.dart';

/// امتدادات مساعدة على [BuildContext] لتقليل التكرار عند الوصول
/// لعناصر شائعة الاستخدام (الثيم، أبعاد الشاشة، وضع القالب).
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;

  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// وضع القالب الحالي (mobile/tablet/desktop) بحسب عرض الشاشة.
  ShellMode get shellMode => ShellMode.fromWidth(screenSize.width);

  /// صحيح عندما يكون اتجاه الواجهة الحالي من اليمين لليسار.
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// اختصار لعرض `SnackBar` بسيط بنص [message].
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
}
