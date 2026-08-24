import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'bottom_nav_bar.dart';
import 'mobile_drawer.dart';

/// قالب الهاتف الكامل — `Scaffold` بشريط تنقل سفلي (`BottomNavBar`)
/// وقائمة جانبية منسدلة (`MobileDrawer`) تُفتح من عنصر "المزيد" في
/// الشريط السفلي، بدل شريط علوي (`AppBar`) عام هنا: كل شاشة وجهة
/// (`placeholder_screens.dart` الآن، شاشات `features/` لاحقاً) تحمل
/// `AppBar` خاصاً بها بعنوانها وإجراءاتها، لأن محتوى هذه الإجراءات
/// يختلف تماماً بين وجهة وأخرى (مثال: "إضافة مهمة" في `tasks` مقابل
/// "تسجيل حضور" في `attendance`) ولا معنى لشريط علوي موحّد عابر لكل
/// الوجهات كما هو الحال مع الشريط السفلي.
class MobileShell extends StatelessWidget {
  const MobileShell({required this.state, required this.child, super.key});

  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String currentLocation = state.uri.path;

    return Scaffold(
      body: child,
      drawer: MobileDrawer(currentLocation: currentLocation),
      // `Builder` ضروري هنا: `Scaffold.of(context)` يحتاج سياقاً
      // (`BuildContext`) هو فعلياً حفيد لعنصر [Scaffold] في الشجرة —
      // `context` الأصلي لدالة `build` هذه هو سياق الأب *قبل* بناء
      // [Scaffold] نفسه، فلا يصلح مباشرة لاستدعاء `Scaffold.of`.
      bottomNavigationBar: Builder(
        builder: (BuildContext scaffoldContext) => BottomNavBar(
          currentLocation: currentLocation,
          onMoreTap: () => Scaffold.of(scaffoldContext).openDrawer(),
        ),
      ),
    );
  }
}
