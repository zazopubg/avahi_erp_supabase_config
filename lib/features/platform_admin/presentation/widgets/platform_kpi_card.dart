import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/status_badge.dart';

/// بطاقة مؤشر واحدة (KPI) — بنفس تصميم `AnalyticsKpiCard` في
/// `features/analytics/` تماماً (مُستنسخة محلياً — انظر توثيق قرار
/// عدم الاستيراد العابر للميزات في `PlatformSectionCard`). 🆕 (Prompt 28)
class PlatformKpiCard extends StatelessWidget {
  const PlatformKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
    this.accent = AvahiStatus.info,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final AvahiStatus accent;
  final String? subtitle;

  Color _accentColor(AvahiColors colors) {
    return switch (accent) {
      AvahiStatus.success => colors.success,
      AvahiStatus.danger => colors.danger,
      AvahiStatus.warning => colors.warning,
      AvahiStatus.info => colors.info,
      AvahiStatus.neutral => colors.onSurfaceVariant,
    };
  }

  Color _accentContainer(AvahiColors colors) {
    return switch (accent) {
      AvahiStatus.success => colors.successContainer,
      AvahiStatus.danger => colors.dangerContainer,
      AvahiStatus.warning => colors.warningContainer,
      AvahiStatus.info => colors.infoContainer,
      AvahiStatus.neutral => colors.surfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AvahiRadius.radiusMd,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(AvahiSpacing.xs),
                decoration: BoxDecoration(
                  color: _accentContainer(colors),
                  borderRadius: AvahiRadius.radiusSm,
                ),
                child: Icon(icon, size: 20, color: _accentColor(colors)),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AvahiSpacing.sm),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AvahiSpacing.xxs),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
