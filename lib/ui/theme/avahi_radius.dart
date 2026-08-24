import 'package:flutter/widgets.dart';

/// نظام زوايا الاستدارة (Border Radius) الموحّد لتطبيق Avahi.
abstract class AvahiRadius {
  /// 0px — بدون استدارة.
  static const double none = 0;

  /// 4px — عناصر صغيرة (شارات، أزرار مصغّرة).
  static const double xs = 4;

  /// 8px — الحقول والأزرار القياسية.
  static const double sm = 8;

  /// 12px — البطاقات (Cards) والحوارات.
  static const double md = 12;

  /// 16px — بطاقات كبيرة / لوحات علوية (Bottom Sheets).
  static const double lg = 16;

  /// 24px — عناصر بارزة كبيرة.
  static const double xl = 24;

  /// 999px — استدارة كاملة (أزرار دائرية، شارات كبسولية Pill).
  static const double full = 999;

  // ── BorderRadius جاهزة للاستخدام المباشر ────────────────────
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusFull =
      BorderRadius.all(Radius.circular(full));
}
