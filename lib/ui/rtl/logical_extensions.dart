import 'package:flutter/material.dart';

/// امتدادات "منطقية" (Logical / start-end) تُغني عن استخدام قيم
/// left/right المباشرة، بحيث تنعكس تلقائياً بحسب اتجاه النص الحالي
/// (RTL/LTR) دون أي منطق شرطي إضافي في شاشات الميزات.
///
/// مبدأ الاستخدام في هذا المشروع:
/// - `start` = يمين الشاشة في RTL، ويسارها في LTR.
/// - `end`   = يسار الشاشة في RTL، ويمينها في LTR.
///
/// معظم widgets في Flutter (Padding, Align, BorderRadius...) تدعم أصلاً
/// خصائص منطقية (`EdgeInsetsDirectional`, `AlignmentDirectional`,
/// `BorderRadiusDirectional`)، وهذا الملف يوفر اختصارات بنّاءة (builder
/// extensions) فوقها لتسهيل الاستخدام اليومي في شاشات الميزات.
extension EdgeInsetsLogical on num {
  /// `EdgeInsetsDirectional.only(start: this)`
  EdgeInsetsDirectional get paddingStart =>
      EdgeInsetsDirectional.only(start: toDouble());

  /// `EdgeInsetsDirectional.only(end: this)`
  EdgeInsetsDirectional get paddingEnd =>
      EdgeInsetsDirectional.only(end: toDouble());

  /// `EdgeInsetsDirectional.symmetric(horizontal: this)`
  EdgeInsetsDirectional get paddingHorizontal =>
      EdgeInsetsDirectional.symmetric(horizontal: toDouble());

  /// `EdgeInsetsDirectional.symmetric(vertical: this)`
  EdgeInsetsDirectional get paddingVertical =>
      EdgeInsetsDirectional.symmetric(vertical: toDouble());

  /// `EdgeInsetsDirectional.all(this)`
  EdgeInsetsDirectional get paddingAll =>
      EdgeInsetsDirectional.all(toDouble());
}

/// بناء [EdgeInsetsDirectional] بأربع قيم منطقية منفصلة، مكافئ لـ
/// `EdgeInsets.only` لكن باتجاه واعٍ للغة (start/end بدل left/right).
EdgeInsetsDirectional paddingOnly({
  double start = 0,
  double top = 0,
  double end = 0,
  double bottom = 0,
}) {
  return EdgeInsetsDirectional.only(
    start: start,
    top: top,
    end: end,
    bottom: bottom,
  );
}

/// امتداد لبناء [BorderRadiusDirectional] بزوايا منطقية (topStart،
/// topEnd، bottomStart، bottomEnd) بدل زوايا left/right الثابتة.
extension BorderRadiusLogical on double {
  /// استدارة في الزاوية العلوية "البادئة" فقط (topStart).
  BorderRadiusDirectional get radiusTopStart =>
      BorderRadiusDirectional.only(topStart: Radius.circular(this));

  /// استدارة في الزاوية العلوية "الخاتمة" فقط (topEnd).
  BorderRadiusDirectional get radiusTopEnd =>
      BorderRadiusDirectional.only(topEnd: Radius.circular(this));

  /// استدارة كاملة بنفس القيمة على كل الزوايا (اتجاهياً محايدة).
  BorderRadiusDirectional get radiusAll =>
      BorderRadiusDirectional.all(Radius.circular(this));
}

/// امتداد يوفر محاذاة منطقية (start/end) بديلاً عن [Alignment] المباشر.
abstract class AvahiAlignment {
  static const AlignmentDirectional centerStart =
      AlignmentDirectional.centerStart;
  static const AlignmentDirectional centerEnd =
      AlignmentDirectional.centerEnd;
  static const AlignmentDirectional topStart = AlignmentDirectional.topStart;
  static const AlignmentDirectional topEnd = AlignmentDirectional.topEnd;
  static const AlignmentDirectional bottomStart =
      AlignmentDirectional.bottomStart;
  static const AlignmentDirectional bottomEnd =
      AlignmentDirectional.bottomEnd;
}
