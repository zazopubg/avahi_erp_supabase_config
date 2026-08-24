import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/modes/glove_mode_provider.dart';
import '../../nav_destinations.dart';

/// الشريط السفلي لقالب الهاتف (`MobileShell`) — أربع وجهات أساسية
/// (الرئيسية، مهامي، الحضور، التقارير، انظر
/// [AppNavDestinations.mobilePrimary]) بالإضافة لعنصر خامس ثابت
/// "المزيد" لا يمثّل وجهة تنقل فعلية بحد ذاته، بل يفتح [onMoreTap]
/// (عملياً [MobileDrawer] من `mobile_shell.dart`) لعرض بقية الميزات
/// المسموحة لدور المستخدم دون إثقال الشريط السفلي بأكثر من 5 عناصر.
///
/// مكوّن عرض بحت — لا يحمل أي منطق تصفية صلاحيات: العناصر الأربعة
/// الأساسية ثابتة دائماً لأن كل الأدوار تملك على الأقل الصلاحيات
/// الأساسية المقابلة لها (`worker` فما فوق)، بخلاف [MobileDrawer] الذي
/// يُصفّي فعلياً حسب [AppNavDestinations.visibleFor].
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    required this.currentLocation,
    required this.onMoreTap,
    super.key,
  });

  /// المسار الحالي المطابق (`GoRouterState.matchedLocation`) — يُستخدم
  /// لتحديد العنصر النشط بصرياً.
  final String currentLocation;

  final VoidCallback onMoreTap;

  static const List<NavDestination> _items = AppNavDestinations.mobilePrimary;

  @override
  Widget build(BuildContext context) {
    // 🆕 (Prompt 27) — انظر التوثيق الكامل لسبب `context.watch` هنا
    // بدل باراميتر صريح في `ui/widgets/common/avahi_button.dart`
    // (نفس المنطق تماماً: يبقي كل موقع استدعاء قديم يعمل دون تعديل).
    final bool isGloveMode = context.watch<GloveModeCubit>().state;
    final int matchedIndex = _items.indexWhere(
      (d) => d.routePath == currentLocation,
    );
    // المسار الحالي وجهة ثانوية (وُصل إليها عبر [MobileDrawer]) وليس
    // إحدى الوجهات الأربع الأساسية → تفعيل عنصر "المزيد" بصرياً بدل
    // تفعيل "الرئيسية" افتراضياً بشكل مضلِّل.
    final int activeIndex = matchedIndex < 0 ? _items.length : matchedIndex;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        // 🆕 (Prompt 27) وضع القفازات: أيقونات أكبر (28 بدل 24) ونص
        // تسمية أوضح — بالتوازي مع ارتفاع الشريط الأطول أدناه.
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => IconThemeData(
            size: isGloveMode ? 28 : 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => TextStyle(
            fontSize: isGloveMode ? 14 : 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      child: NavigationBar(
        // 🆕 (Prompt 27) ارتفاع أكبر (88 بدل الافتراضي 80) عند تفعيل
        // وضع القفازات — منطقة لمس أوسع رأسياً لكل وجهة.
        height: isGloveMode ? 88 : null,
        selectedIndex: activeIndex,
        onDestinationSelected: (int index) {
          if (index < _items.length) {
            context.goNamed(_items[index].routeName);
          } else {
            onMoreTap();
          }
        },
        destinations: <Widget>[
          for (final NavDestination item in _items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}
