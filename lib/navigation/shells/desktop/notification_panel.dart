import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/errors/failure.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/entities/app_user.dart';
import '../../../features/auth/presentation/state/auth_cubit.dart';
import '../../../features/auth/presentation/state/auth_state.dart';
import '../../../features/notifications/presentation/state/notifications_cubit.dart';
import '../../../features/notifications/presentation/state/notifications_state.dart';
import '../../../features/notifications/presentation/widgets/notification_tile.dart';
import '../../../features/notifications/presentation/widgets/unread_badge.dart';
import '../../../ui/theme/avahi_radius.dart';
import '../../../ui/theme/avahi_spacing.dart';
import '../../../ui/widgets/common/empty_state.dart';
import '../../../ui/widgets/common/error_view.dart';
import '../../../ui/widgets/common/loading_indicator.dart';
import '../../route_names.dart';

/// لوحة إشعارات منسدلة لسطح المكتب — كانت **Placeholder فقط** في
/// Prompt 12 (شكل عام بلا مصدر بيانات فعلي). أصبحت الآن (Prompt 23)
/// تستهلك [NotificationsCubit] فعلياً: أحدث الإشعارات، عداد حي غير
/// المقروء، وزر "تعليم الكل كمقروء" — انظر [NotificationPanel.show].
///
/// ⚠️ قرار تصميم (نسخة `Cubit` مستقلة لكل فتحة للوحة، لا مشاركة مع
/// `notifications_screen.dart`): كل فتحة لـ [NotificationPanel] تُنشئ
/// `sl<NotificationsCubit>()` خاصة بها وتُغلقها معها (`StatefulWidget`
/// + `dispose`) — بنفس القاعدة العامة "كل نقطة دخول شاشة تحصل على
/// نسخة `Cubit` خاصة بها" (`features_module.dart`)، بما في ذلك زر
/// "عرض الكل" الذي يفتح `/notifications` بنسخته المستقلة تماماً. أي
/// تحديث (تعليم كمقروء...) من أي من الاثنين يصل تلقائياً للآخر عند
/// فتحه لاحقاً عبر التحميل الأولي (`loadInitial`) الذي يقرأ دائماً من
/// نفس مصدر الحقيقة (`INotificationRepository` المحلي أولاً).
class NotificationPanel extends StatefulWidget {
  const NotificationPanel({required this.user, super.key});

  final AppUser user;

  /// طريقة مختصرة لعرض اللوحة كبطاقة عائمة أسفل [anchorContext]
  /// (عادة سياق زر الجرس نفسه في `topbar.dart`). لا تعرض شيئاً إن لم
  /// تكن هناك جلسة مصادَق عليها حالياً (نظرياً لا يحدث هذا أصلاً — زر
  /// الجرس نفسه لا يظهر إلا ضمن `AdaptiveShell` المحمي بـ `AuthGuard`).
  static Future<void> show(BuildContext anchorContext) async {
    final AuthState authState = anchorContext.read<AuthCubit>().state;
    final AppUser? user = authState.whenOrNull<AppUser?>(
      authenticated: (AppUser u, _) => u,
    );
    if (user == null) return;

    final RenderBox button = anchorContext.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(anchorContext).context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu<void>(
      context: anchorContext,
      position: position,
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: NotificationPanel(user: user),
        ),
      ],
    );
  }

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  late final NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<NotificationsCubit>()..loadInitial(widget.user);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsCubit>.value(
      value: _cubit,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(AvahiSpacing.sm),
        decoration: const BoxDecoration(borderRadius: AvahiRadius.radiusMd),
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (BuildContext context, NotificationsState state) {
            final NotificationsData? data = state.dataOrNull;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _PanelHeader(data: data),
                const Divider(height: AvahiSpacing.md),
                Flexible(
                  child: SizedBox(
                    height: 260,
                    child: state.when<Widget>(
                      loading: () => const LoadingIndicator(),
                      error: (Failure failure) => ErrorView(
                        title: 'تعذّر تحميل الإشعارات',
                        message: failure.message,
                        onRetry: () => context
                            .read<NotificationsCubit>()
                            .loadInitial(widget.user),
                      ),
                      loaded: (NotificationsData d) {
                        final List<AppNotification> latest = d.latest();
                        if (latest.isEmpty) {
                          return const EmptyState(
                            title: 'لا توجد إشعارات حالياً',
                            message:
                                'ستظهر إشعاراتك هنا فور تفعيل هذه الميزة.',
                            icon: Icons.notifications_none_outlined,
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: latest.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AvahiSpacing.xxs),
                          itemBuilder: (BuildContext context, int index) {
                            final AppNotification notification = latest[index];
                            return NotificationTile(
                              dense: true,
                              notification: notification,
                              isMarkingAsRead: d.markingAsReadIds.contains(
                                notification.id,
                              ),
                              onTap: () async {
                                final NotificationsCubit cubit =
                                    context.read<NotificationsCubit>();
                                await cubit.markAsRead(notification);
                                if (!context.mounted) return;
                                final String? routeName =
                                    notificationRouteName(
                                  notification.relatedEntityType,
                                );
                                Navigator.of(context).pop();
                                if (routeName != null) {
                                  context.goNamed(routeName);
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const Divider(height: AvahiSpacing.md),
                const _ViewAllButton(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.data});

  final NotificationsData? data;

  @override
  Widget build(BuildContext context) {
    final int unreadCount = data?.unreadCount ?? 0;
    return Row(
      children: <Widget>[
        Text('الإشعارات', style: Theme.of(context).textTheme.titleSmall),
        if (unreadCount > 0) ...<Widget>[
          const SizedBox(width: AvahiSpacing.xs),
          UnreadBadge(count: unreadCount, dense: true),
        ],
        const Spacer(),
        if (data != null)
          TextButton.icon(
            onPressed: unreadCount == 0
                ? null
                : () => context.read<NotificationsCubit>().markAllAsRead(),
            icon: data!.isMarkingAllAsRead
                ? const LoadingIndicator(size: LoadingIndicatorSize.small)
                : const Icon(Icons.done_all_outlined, size: 16),
            label: const Text('تعليم الكل كمقروء'),
          ),
      ],
    );
  }
}

/// يغلق اللوحة المنسدلة ثم يفتح `/notifications` (الشاشة الكاملة) —
/// الإغلاق أولاً ضروري لأن `showMenu` يُبقي اللوحة فوق كل شيء وإلا
/// ظهرت شاشة الإشعارات الكاملة خلفها بصرياً حتى إغلاقها يدوياً.
class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
        context.goNamed(RouteNames.notifications);
      },
      child: const Text('عرض الكل'),
    );
  }
}
