import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../domain/enums/sync_state.dart' as domain;
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../../../../ui/widgets/common/sync_indicator.dart' as ui_sync;
import '../state/settings_cubit.dart';
import '../state/settings_state.dart';
import '../widgets/setting_tile.dart';

/// شاشة المزامنة — تتحكم فعلياً بـ `SyncScheduler` (`data/sync/`،
/// Prompt 09/27) عبر [SettingsCubit]: اختيار تفعيل/تعطيل المزامنة
/// التلقائية، زر "مزامنة الآن"، وعرض آخر وقت مزامنة ناجحة + عدد
/// السجلات المعلَّقة (Outbox) بشكل حي.
///
/// تُزوِّد [SettingsCubit] الخاصة بها هنا (وليس على مستوى
/// `settings_screen.dart`) — انظر توثيق القرار الكامل في تلك الشاشة.
class SyncSettings extends StatelessWidget {
  const SyncSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (_) => sl<SettingsCubit>()..loadInitial(),
      child: const _SyncSettingsView(),
    );
  }
}

class _SyncSettingsView extends StatelessWidget {
  const _SyncSettingsView();

  /// يحوّل حالة المزامنة من `domain/enums/sync_state.dart` (المصدر
  /// الحقيقي لحالة `SyncScheduler`) إلى تعداد [ui_sync.SyncState]
  /// المحلي الذي يفهمه [ui_sync.SyncIndicator] (`ui/widgets/common/`،
  /// له أربع حالات فقط بلا `conflict`) — [domain.SyncState.conflict]
  /// يُعرض بصرياً كـ "فشلت المزامنة" (نفس الأيقونة/اللون التحذيري)
  /// لكن هذه الشاشة تضيف نصاً توضيحياً منفصلاً أدناه لتمييز التعارض
  /// عن الفشل الشبكي البسيط صراحة.
  ui_sync.SyncState _toUiState(domain.SyncState state) => switch (state) {
        domain.SyncState.synced => ui_sync.SyncState.synced,
        domain.SyncState.syncing => ui_sync.SyncState.syncing,
        domain.SyncState.pending => ui_sync.SyncState.pending,
        domain.SyncState.failed => ui_sync.SyncState.failed,
        domain.SyncState.conflict => ui_sync.SyncState.failed,
      };

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Scaffold(
      appBar: AppBar(title: const Text('المزامنة')),
      body: BlocBuilder<SettingsCubit, SettingsData>(
        builder: (BuildContext context, SettingsData state) {
          return ListView(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            children: <Widget>[
              Container(
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
                    ui_sync.SyncIndicator(
                      state: _toUiState(state.syncState),
                      size: 20,
                    ),
                    if (state.syncState == domain.SyncState.conflict) ...<Widget>[
                      const SizedBox(height: AvahiSpacing.xxs),
                      Text(
                        'يوجد تعارض بين نسخة محلية وأخرى على السحابة '
                        'يتطلب انتباهك.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.danger,
                            ),
                      ),
                    ],
                    const SizedBox(height: AvahiSpacing.sm),
                    Text(
                      'آخر مزامنة ناجحة: ${_formatLastSync(state.lastSuccessfulSyncAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AvahiSpacing.xxs),
                    Text(
                      'سجلات بانتظار المزامنة: ${state.pendingOutboxCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AvahiSpacing.md),
              AvahiButton(
                label: 'مزامنة الآن',
                icon: Icons.sync,
                isFullWidth: true,
                isLoading: state.isSyncTriggeringNow,
                onPressed: () => context.read<SettingsCubit>().triggerSyncNow(),
              ),
              const SizedBox(height: AvahiSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outline),
                ),
                child: SettingTile(
                  icon: Icons.autorenew_outlined,
                  title: 'مزامنة تلقائية',
                  subtitle: state.isSyncAutoEnabled
                      ? 'تعمل في الخلفية عند توفر الاتصال'
                      : 'مُعطَّلة — استخدم "مزامنة الآن" يدوياً',
                  showChevron: false,
                  trailing: Switch(
                    value: state.isSyncAutoEnabled,
                    onChanged: (bool value) =>
                        context.read<SettingsCubit>().setSyncAutoEnabled(value),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatLastSync(DateTime? timestamp) {
    if (timestamp == null) return 'لا توجد بعد';
    return DateFormat('yyyy/MM/dd — HH:mm', 'ar').format(timestamp);
  }
}
