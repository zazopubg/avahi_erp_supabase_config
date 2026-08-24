import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/local_settings_service.dart';
import '../../../../ui/modes/glove_mode_provider.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';

/// شاشة وضع القفازات — تتحكم فعلياً بـ [GloveModeCubit] (`ui/modes/`،
/// Prompt 01)، أول شاشة تستهلك حالته منذ إنشائه (بخلاف `AvahiButton`/
/// `BottomNavBar` اللتين استُهلكتا للتو ضمن هذه الخطوة نفسها لتصبح
/// *متجاوبتين* معه — هذه الشاشة هي من يُغيّر قيمته أصلاً).
///
/// عند التبديل: [GloveModeCubit.toggle] يُعيد بناء **كل** مكان في
/// التطبيق يستهلكه عبر `context.watch` فوراً (`AvahiButton` بكل
/// أحجامه/أنماطه، `BottomNavBar`) — هذه الشاشة نفسها تعرض معاينة حية
/// مصغّرة أسفل المفتاح لإثبات الأثر الفعلي دون مغادرتها.
class GloveModeSettings extends StatelessWidget {
  const GloveModeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final bool isEnabled = context.watch<GloveModeCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('وضع القفازات')),
      body: ListView(
        padding: const EdgeInsets.all(AvahiSpacing.md),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.back_hand_outlined, color: colors.brand, size: 28),
              const SizedBox(width: AvahiSpacing.sm),
              Expanded(
                child: Text(
                  'يكبّر أزرار الشاشة (كزر تسجيل الحضور) والشريط '
                  'السفلي وعناصر اللمس الأساسية، لتسهيل الاستخدام '
                  'أثناء ارتداء قفازات العمل الميدانية.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AvahiSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AvahiSpacing.md,
              vertical: AvahiSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تفعيل وضع القفازات'),
              value: isEnabled,
              onChanged: (bool value) => _onChanged(context, value),
            ),
          ),
          const SizedBox(height: AvahiSpacing.xl),
          Text(
            'معاينة',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AvahiSpacing.sm),
          const AvahiButton(
            label: 'تسجيل حضور',
            icon: Icons.qr_code_scanner,
            size: AvahiButtonSize.large,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Future<void> _onChanged(BuildContext context, bool value) async {
    context.read<GloveModeCubit>().toggle();
    await sl<LocalSettingsService>().saveGloveMode(value);
  }
}
