import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import 'notification_type_icon.dart';

/// عنصر إشعار واحد ضمن قائمة — [NotificationTypeIcon]، العنوان
/// والنص، الوقت النسبي (`DateFormatter.relative`)، ونقطة زرقاء صغيرة
/// + خلفية مُبرزة للإشعارات غير المقروءة. العنصر البصري المشترك بين
/// `notifications_screen.dart` و`notification_panel.dart`، بنفس فلسفة
/// `EquipmentCard`/`DocumentCard`.
///
/// مكوّن عرض بحت — [onTap] هو من يتولى فعلياً استدعاء
/// `NotificationsCubit.markAsRead` والتنقّل عبر [notificationRouteName]؛
/// هذا المكوّن نفسه لا يعرف شيئاً عن `Cubit`/`go_router`.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    super.key,
    this.onTap,
    this.isMarkingAsRead = false,
    this.dense = false,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  /// صحيح أثناء انتظار استجابة `markAsRead` لهذا الإشعار تحديداً —
  /// يعرض مؤشر تحميل مصغّر بدل النقطة الزرقاء.
  final bool isMarkingAsRead;

  /// عند `true`، تُستخدم مسافات/أحجام خط أصغر — `notification_panel.dart`
  /// (اللوحة المنسدلة المضغوطة على سطح المكتب).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final bool unread = !notification.isRead;

    return Material(
      color: unread ? colors.infoContainer.withValues(alpha: 0.35) : null,
      borderRadius: AvahiRadius.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AvahiRadius.radiusMd,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? AvahiSpacing.xs : AvahiSpacing.sm,
            vertical: dense ? AvahiSpacing.xxs : AvahiSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NotificationTypeIcon(
                type: notification.type,
                size: dense ? 30 : 36,
              ),
              const SizedBox(width: AvahiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      notification.title,
                      maxLines: dense ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (dense ? context.textTheme.bodyMedium : context.textTheme.titleSmall)
                              ?.copyWith(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (notification.body != null &&
                        notification.body!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: AvahiSpacing.xxs),
                      Text(
                        notification.body!,
                        maxLines: dense ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AvahiSpacing.xxs),
                    Text(
                      DateFormatter.relative(notification.createdAt),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AvahiSpacing.xs),
              SizedBox(
                width: 18,
                height: 18,
                child: isMarkingAsRead
                    ? const LoadingIndicator(size: LoadingIndicatorSize.small)
                    : unread
                        ? Align(
                            alignment: AlignmentDirectional.topEnd,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
