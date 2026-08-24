import 'package:flutter/widgets.dart';

import 'shell_mode.dart';

/// كاشف المنصّة/القالب الحالي.
///
/// ⚠️ التطبيق يستهدف المتصفح (Chrome) حصراً في هذه المرحلة، لذا لا
/// يوجد هنا أي فحص لنظام تشغيل أصلي (Platform.isAndroid وما شابه).
/// الاعتماد الوحيد هو عرض نافذة العرض (Viewport Width) عبر [ShellMode].
///
/// هذا الكاشف مصمم كطبقة Interface بسيطة الآن (بلا حقن تبعيات بعد)؛
/// سيُسجَّل لاحقاً كـ Singleton ضمن `core/di/` في Prompt 11.
class PlatformDetector {
  const PlatformDetector();

  /// يحدد [ShellMode] الحالي من `MediaQuery` عبر [context].
  ShellMode detectFromContext(BuildContext context) {
    return ShellMode.fromWidth(MediaQuery.sizeOf(context).width);
  }

  /// يحدد [ShellMode] مباشرة من عرض بالبكسل (مفيد خارج شجرة الودجات،
  /// مثل داخل Cubit عند تمرير العرض من الواجهة).
  ShellMode detectFromWidth(double width) => ShellMode.fromWidth(width);

  /// هل يعمل التطبيق حالياً ضمن متصفح ويب؟ صحيح دائماً في هذه المرحلة
  /// من المشروع (Avahi Web-only)، لكنه مُعرَّف كطريقة صريحة حتى يسهل
  /// لاحقاً توسعة الدعم لمنصات أصلية دون كسر التوقيع (Signature).
  bool get isWeb => true;
}
