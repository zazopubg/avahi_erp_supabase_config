import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/empty_state.dart';
import '../../../../ui/widgets/common/error_view.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../state/notifications_cubit.dart';
import '../state/notifications_state.dart';
import '../widgets/notification_tile.dart';
import '../widgets/unread_badge.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.notifications` (`/notifications`)
/// — شاشة **موحَّدة** لكل المنصات (لا فرق `mobile/`/`desktop/` منفصل،
/// بخلاف بقية الميزات المحورية): قائمة إشعارات كاملة قابلة للتصفية
/// (الكل/غير المقروء)، مع "تعليم الكل كمقروء" و`RefreshIndicator`،
/// بعرض متجاوب طبيعي بحكم بساطة المحتوى (قائمة عمودية واحدة) دون
/// حاجة فعلية لتخطيط سطح مكتب مختلف — القرار نفسه المتّبع أصلاً في
/// `attendance_screen.dart`/`tasks_screen.dart` لبعض شاشاتها الفرعية
/// البسيطة.
///
/// توفّر [NotificationsCubit] محلياً عبر `sl<NotificationsCubit>()..
/// loadInitial(user)` — بنفس نمط `DocumentsListScreen`/`TasksScreen`.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<NotificationsCubit>(
              create: (_) => sl<NotificationsCubit>()..loadInitial(user),
              child: const _NotificationsBody(),
            );
          },
        );
      },
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody();

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    final NotificationsCubit cubit = context.read<NotificationsCubit>();
    await cubit.markAsRead(notification);
    if (!context.mounted) return;

    final String? routeName = notificationRouteName(
      notification.relatedEntityType,
    );
    if (routeName != null) {
      context.goNamed(routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (BuildContext context, NotificationsState state) {
        final int unreadCount = state.dataOrNull?.unreadCount ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('الإشعارات'),
                if (unreadCount > 0) ...<Widget>[
                  const SizedBox(width: AvahiSpacing.xs),
                  UnreadBadge(count: unreadCount, dense: true),
                ],
              ],
            ),
            actions: <Widget>[
              state.dataOrNull == null
                  ? const SizedBox.shrink()
                  : Row(
                      children: <Widget>[
                        const Text('غير المقروء فقط'),
                        Switch(
                          value: state.dataOrNull!.unreadOnlyFilter,
                          onChanged: (bool value) => context
                              .read<NotificationsCubit>()
                              .setUnreadOnlyFilter(value),
                        ),
                      ],
                    ),
              IconButton(
                tooltip: 'تعليم الكل كمقروء',
                icon: state.dataOrNull?.isMarkingAllAsRead ?? false
                    ? const LoadingIndicator(size: LoadingIndicatorSize.small)
                    : const Icon(Icons.done_all_outlined),
                onPressed: unreadCount == 0
                    ? null
                    : () => context.read<NotificationsCubit>().markAllAsRead(),
              ),
              const SizedBox(width: AvahiSpacing.xs),
            ],
          ),
          body: state.when<Widget>(
            loading: () =>
                const LoadingIndicator(label: 'جارٍ تحميل الإشعارات...'),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل الإشعارات',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser user, _) => context
                      .read<NotificationsCubit>()
                      .loadInitial(user),
                );
              },
            ),
            loaded: (NotificationsData data) {
              final List<AppNotification> items = data.filteredNotifications;

              if (items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => context.read<NotificationsCubit>().refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      SizedBox(
                        height: 400,
                        child: EmptyState(
                          title: data.unreadOnlyFilter
                              ? 'لا توجد إشعارات غير مقروءة'
                              : 'لا توجد إشعارات حالياً',
                          message: data.unreadOnlyFilter
                              ? 'كل الإشعارات مقروءة، أحسنت المتابعة!'
                              : 'ستظهر إشعاراتك هنا فور توفّرها.',
                          icon: Icons.notifications_none_outlined,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<NotificationsCubit>().refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AvahiSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AvahiSpacing.xxs),
                  itemBuilder: (BuildContext context, int index) {
                    final AppNotification notification = items[index];
                    return NotificationTile(
                      notification: notification,
                      isMarkingAsRead:
                          data.markingAsReadIds.contains(notification.id),
                      onTap: () => _openNotification(context, notification),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
