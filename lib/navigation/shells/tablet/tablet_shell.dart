import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/enums/user_role.dart';
import '../../../domain/repositories/repositories.dart';
import '../../nav_destinations.dart';
import '../desktop/topbar.dart';

/// قالب الجهاز اللوحي — وسط بين [MobileShell] (شريط سفلي + قائمة
/// منسدلة) و[DesktopShell] (قائمة جانبية عريضة ثابتة): `NavigationRail`
/// مضغوط (أيقونات فقط، بلا نص ظاهر دائماً) على يمين الشاشة (RTL) بجانب
/// نفس [Topbar] المستخدم في `DesktopShell` — استغلال أفضل للعرض
/// المتوسط (600-1024) دون ازدحام شريط سفلي بأيقونات كثيرة، ودون هدر
/// عرض قائمة جانبية كاملة لا تحتاجها شاشة بهذا الحجم بعد.
///
/// ⚠️ نفس ملاحظة `sidebar.dart`/`mobile_drawer.dart`: يستهلك
/// `sl<IAuthRepository>().watchAuthState()` مباشرة كحل مؤقت قبل
/// `AuthCubit` فعلي (`features/auth/`، Prompt 13).
class TabletShell extends StatelessWidget {
  const TabletShell({required this.state, required this.child, super.key});

  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String currentLocation = state.uri.path;

    return Scaffold(
      body: StreamBuilder<AppUser?>(
        stream: sl<IAuthRepository>().watchAuthState(),
        builder: (context, snapshot) {
          final AppUser? user = snapshot.data;
          final List<NavDestination> destinations = AppNavDestinations
              .visibleFor(user?.role ?? UserRole.worker);

          final int selectedIndex = destinations.indexWhere(
            (d) => d.routePath == currentLocation,
          );

          return Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                labelType: NavigationRailLabelType.selected,
                onDestinationSelected: (int index) {
                  context.goNamed(destinations[index].routeName);
                },
                destinations: <NavigationRailDestination>[
                  for (final NavDestination d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
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
          );
        },
      ),
    );
  }
}
