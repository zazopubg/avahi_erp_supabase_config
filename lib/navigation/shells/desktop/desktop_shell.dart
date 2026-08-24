import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'sidebar.dart';
import 'topbar.dart';

/// قالب سطح المكتب الكامل — قائمة جانبية ثابتة العرض (`Sidebar`) على
/// يمين الشاشة (RTL افتراضياً، انظر `ui/rtl/directionality_provider.dart`)
/// بجانب منطقة محتوى تعلوها شريط علوي ثابت (`Topbar`، بحث + إشعارات).
///
/// بخلاف [MobileShell] الذي يترك عنوان الشاشة بالكامل لـ `AppBar` كل
/// وجهة، هنا [Topbar] ثابت عبر كل الوجهات (بحث عام + إشعارات، وليس
/// عنوان صفحة) ويظهر *أعلى* أي `AppBar` خاص بالشاشة نفسها إن وُجد —
/// شريطان منفصلان بغرضين مختلفين (تنقل عام ثابت مقابل عنوان/إجراءات
/// خاصة بالصفحة الحالية) بدل شريط واحد يحاول خدمة الغرضين معاً.
class DesktopShell extends StatelessWidget {
  const DesktopShell({required this.state, required this.child, super.key});

  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String currentLocation = state.uri.path;

    return Scaffold(
      body: Row(
        children: <Widget>[
          Sidebar(currentLocation: currentLocation),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: <Widget>[
                const Topbar(),
                const Divider(height: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
