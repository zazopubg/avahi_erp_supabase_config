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

/// القائمة الجانبية الثابتة لقالب سطح المكتب (`DesktopShell`) — تعرض
/// شعار التطبيق، ثم **كل** وجهات التنقل المسموحة لدور المستخدم الحالي
/// ([AppNavDestinations.visibleFor]، "كل الميزات حسب الدور")، وأخيراً
/// بطاقة مستخدم مصغّرة أسفلها بزر تسجيل خروج — على عكس [MobileDrawer]
/// المؤقت (يُفتح/يُغلق)، هذه القائمة **ثابتة العرض دائماً** طالما
/// [DesktopShell] نشط (`ShellMode.desktop`).
///
/// ⚠️ نفس ملاحظة `mobile_drawer.dart`: تستهلك
/// `sl<IAuthRepository>().watchAuthState()` مباشرة كحل مؤقت قبل بناء
/// `AuthCubit` فعلي (`features/auth/`، Prompt 13).
class Sidebar extends StatelessWidget {
  const Sidebar({required this.currentLocation, super.key});

  final String currentLocation;

  static const double _width = 260;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: ColoredBox(
        color: context.colors.surface,
        child: StreamBuilder<AppUser?>(
          stream: sl<IAuthRepository>().watchAuthState(),
          builder: (context, snapshot) {
            final AppUser? user = snapshot.data;

            return Column(
              children: <Widget>[
                const _SidebarLogo(),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AvahiSpacing.sm,
                      horizontal: AvahiSpacing.xs,
                    ),
                    children: <Widget>[
                      for (final NavDestination destination
                          in AppNavDestinations.visibleFor(
                        user?.role ?? UserRole.worker,
                      ))
                        _SidebarItem(
                          destination: destination,
                          isActive: destination.routePath == currentLocation,
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _SidebarUserFooter(user: user),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AvahiSpacing.md,
        vertical: AvahiSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.construction, color: context.colors.primary, size: 28),
          const SizedBox(width: AvahiSpacing.xs),
          Text('أفاهي', style: context.textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.destination, required this.isActive});

  final NavDestination destination;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        selected: isActive,
        selectedTileColor: context.colors.primaryContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        leading: Icon(isActive ? destination.selectedIcon : destination.icon),
        title: Text(destination.label),
        onTap: () => context.goNamed(destination.routeName),
      ),
    );
  }
}

class _SidebarUserFooter extends StatelessWidget {
  const _SidebarUserFooter({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AvahiSpacing.sm),
      child: Row(
        children: <Widget>[
          Avatar(
            name: user?.fullName,
            imageUrl: user?.avatarUrl,
            size: AvatarSize.small,
          ),
          const SizedBox(width: AvahiSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  user?.fullName ?? '...',
                  style: context.textTheme.bodyMedium,
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
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_outlined, size: 20),
            onPressed: () => sl<LogoutUsecase>()(),
          ),
        ],
      ),
    );
  }
}
