import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ⚠️ `core/platform/shell_mode.dart` يُعرِّف بنفسه امتداد
// `ShellModeContextX` بنفس اسم الخاصية (`shellMode`) الموجودة في
// `context_extensions.dart` أدناه (`BuildContextX`) — استيراد كليهما
// معاً بدون `hide` يُنتج خطأ ترجمة "Extension member conflict". نُبقي
// فقط تعريف النوع `ShellMode` نفسه من هذا الاستيراد (`hide` يستثني
// الامتداد فقط، لا النوع)، ونعتمد حصراً على `context.shellMode` من
// `context_extensions.dart` كنقطة وصول واحدة موحّدة عبر كل الشجرة.
import '../../core/platform/shell_mode.dart' hide ShellModeContextX;
import '../../core/utils/extensions/context_extensions.dart';
import 'desktop/desktop_shell.dart';
import 'mobile/mobile_shell.dart';
import 'tablet/tablet_shell.dart';

/// القالب الجذري الوحيد المُمرَّر لـ `ShellRoute.builder` في
/// `app_router.dart` — يقرأ [ShellMode] الحالي عبر `context.shellMode`
/// (`core/utils/extensions/context_extensions.dart`) ويعرض القالب
/// المناسب تلقائياً (`MobileShell`/`TabletShell`/`DesktopShell`)، مع
/// إعادة بناء تلقائية عند تغيّر عرض نافذة المتصفح لأن `context.shellMode`
/// يعتمد على `MediaQuery.sizeOf(context)` — وهو استعلام يسجّل هذه
/// الودجة كمعتمِدة (Dependent) على حجم الشاشة، فيُعاد بناؤها تلقائياً
/// من Flutter نفسه عند أي تغيّر فيه دون أي `StatefulWidget`/`Listener`
/// إضافي مطلوب هنا.
///
/// لا يحمل هذا القالب أي حالة أو منطق تنقل خاص به — مجرّد نقطة توزيع
/// (Dispatcher) بين ثلاثة قوالب فرعية، كل منها مسؤول بالكامل عن بنائه
/// المرئي الخاص (شريط سفلي، قائمة جانبية...).
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({required this.state, required this.child, super.key});

  /// حالة `go_router` الحالية — تحمل المسار المطابق الحالي، تُستخدم من
  /// القوالب الفرعية لتحديد العنصر النشط في الشريط/القائمة الجانبية.
  final GoRouterState state;

  /// محتوى الصفحة الحالية المطابقة للمسار (يُمرَّر كما هو من
  /// `ShellRoute.builder` في `app_router.dart`).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ShellMode mode = context.shellMode;

    return switch (mode) {
      ShellMode.mobile => MobileShell(state: state, child: child),
      ShellMode.tablet => TabletShell(state: state, child: child),
      ShellMode.desktop => DesktopShell(state: state, child: child),
    };
  }
}
