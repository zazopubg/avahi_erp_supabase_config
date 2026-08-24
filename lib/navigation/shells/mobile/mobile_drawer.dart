import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/enums/user_role.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/usecases/auth/logout_usecase.dart';
import '../../../ui/theme/avahi_spacing.dart';
import '../../../ui/widgets/common/avatar.dart';
import '../../nav_destinations.dart';
import '../../role_labels.dart';

/// القائمة الجانبية المنسدلة لقالب الهاتف (`MobileShell`) — تُفتح من
/// عنصر "المزيد" في [BottomNavBar]. تعرض رأساً ببيانات المستخدم
/// الحالي، ثم **كل** وجهات التنقل المسموحة لدوره
/// ([AppNavDestinations.visibleFor]) — بما فيها الوجهات الأربع
/// الأساسية الموجودة أصلاً في الشريط السفلي (تكرار مقصود: يبقي هذه
/// القائمة "نظرة كاملة على كل الميزات المتاحة" دون استثناءات يصعب
/// تذكّرها)، وأخيراً إجراء تسجيل الخروج.
///
/// ⚠️ تستهلك `sl<IAuthRepository>().watchAuthState()` مباشرة (بدل
/// `AuthCubit` غير موجود بعد، `features/auth/` Prompt 13) لعرض بيانات
/// المستخدم الحالي تفاعلياً وتصفية الوجهات حسب دوره — سيُستبدل هذا
/// الاستهلاك المباشر بـ `context.watch<AuthCubit>()` عند بناء الميزة،
/// دون تغيير أي شيء في بنية هذه الودجة نفسها.
class MobileDrawer extends StatelessWidget {
  const MobileDrawer({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: StreamBuilder<AppUser?>(
        stream: sl<IAuthRepository>().watchAuthState(),
        builder: (context, snapshot) {
          final AppUser? user = snapshot.data;

          return SafeArea(
            child: Column(
              children: <Widget>[
                _DrawerHeader(user: user),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AvahiSpacing.xs,
                    ),
                    children: <Widget>[
                      for (final NavDestination destination
                          in AppNavDestinations.visibleFor(
                        user?.role ?? UserRole.worker,
                      ))
                        _DrawerItem(
                          destination: destination,
                          isActive: destination.routePath == currentLocation,
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: const Text('تسجيل الخروج'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await sl<LogoutUsecase>()();
                  },
                ),
                const SizedBox(height: AvahiSpacing.xs),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: context.colors.surfaceContainerHighest),
      child: Row(
        children: <Widget>[
          Avatar(
            name: user?.fullName,
            imageUrl: user?.avatarUrl,
            size: AvatarSize.large,
          ),
          const SizedBox(width: AvahiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  user?.fullName ?? '...',
                  style: context.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user != null)
                  Text(
                    user!.role.displayLabel,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.destination, required this.isActive});

  final NavDestination destination;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isActive,
      leading: Icon(isActive ? destination.selectedIcon : destination.icon),
      title: Text(destination.label),
      onTap: () {
        Navigator.of(context).pop();
        context.goNamed(destination.routeName);
      },
    );
  }
}
