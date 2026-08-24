import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../state/settings_cubit.dart';
import '../state/settings_state.dart';
import '../widgets/setting_tile.dart';

/// تسميات عرض عربية لكل [NotificationCategories] — مصدر عرض بحت،
/// بنفس فلسفة `UserRoleLabelX.displayLabel` (`role_labels.dart`).
extension _NotificationCategoryLabel on String {
  String get displayLabel => switch (this) {
        NotificationCategories.taskUpdates => 'تحديثات المهام',
        NotificationCategories.attendanceReminders => 'تذكيرات الحضور',
        NotificationCategories.leaveApprovals => 'موافقات الإجازات',
        NotificationCategories.reportReviews => 'مراجعة التقارير',
        NotificationCategories.equipmentAlerts => 'تنبيهات المعدات',
        _ => this,
      };

  IconData get displayIcon => switch (this) {
        NotificationCategories.taskUpdates => Icons.task_alt_outlined,
        NotificationCategories.attendanceReminders =>
          Icons.access_time_outlined,
        NotificationCategories.leaveApprovals => Icons.event_available_outlined,
        NotificationCategories.reportReviews => Icons.description_outlined,
        NotificationCategories.equipmentAlerts => Icons.build_outlined,
        _ => Icons.notifications_outlined,
      };
}

/// شاشة الإشعارات — تتحكم بإذن المتصفح الفعلي عبر `NotificationService`
/// (`WebNotificationService`، أول ربط فعلي لها، Prompt 27) وبتفضيلات
/// كل تصنيف إشعار على حدة، عبر [SettingsCubit].
class NotificationSettings extends StatelessWidget {
  const NotificationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (_) => sl<SettingsCubit>()..loadInitial(),
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: BlocBuilder<SettingsCubit, SettingsData>(
        builder: (BuildContext context, SettingsData state) {
          return ListView(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            children: <Widget>[
              _PermissionCard(state: state, colors: colors),
              const SizedBox(height: AvahiSpacing.lg),
              Text(
                'تصنيفات الإشعارات',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AvahiSpacing.xs),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outline),
                ),
                child: Column(
                  children: <Widget>[
                    for (final String category in NotificationCategories.all)
                      SettingTile(
                        icon: category.displayIcon,
                        title: category.displayLabel,
                        showChevron: false,
                        enabled: state.notificationPermissionGranted,
                        trailing: Switch(
                          value: state.notificationCategories[category] ?? true,
                          onChanged: !state.notificationPermissionGranted
                              ? null
                              : (bool value) => context
                                  .read<SettingsCubit>()
                                  .setNotificationCategoryEnabled(
                                    category,
                                    value,
                                  ),
                        ),
                      ),
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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.state, required this.colors});

  final SettingsData state;
  final AvahiColors colors;

  @override
  Widget build(BuildContext context) {
    final String message;
    final Color color;
    final IconData icon;

    if (state.notificationPermissionGranted) {
      message = 'إشعارات المتصفح مفعَّلة على هذا الجهاز.';
      color = colors.success;
      icon = Icons.notifications_active_outlined;
    } else if (state.notificationPermissionDenied) {
      message = 'تم رفض إذن الإشعارات مسبقاً. فعِّله من إعدادات المتصفح '
          'نفسه لهذا الموقع.';
      color = colors.danger;
      icon = Icons.notifications_off_outlined;
    } else {
      message = 'فعِّل إشعارات المتصفح لتصلك تنبيهات المهام والحضور '
          'والإجازات فور حدوثها.';
      color = colors.warning;
      icon = Icons.notifications_none_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: color),
              const SizedBox(width: AvahiSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (!state.notificationPermissionGranted &&
              !state.notificationPermissionDenied) ...<Widget>[
            const SizedBox(height: AvahiSpacing.sm),
            AvahiButton(
              label: 'طلب إذن الإشعارات',
              icon: Icons.notifications_outlined,
              isLoading: state.isRequestingNotificationPermission,
              onPressed: () =>
                  context.read<SettingsCubit>().requestNotificationPermission(),
            ),
          ],
        ],
      ),
    );
  }
}
