import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/status_badge.dart';
import '../state/analytics_state.dart';

/// بطاقة مؤشر واحدة ضمن [KpiSummaryRow] — قيمة كبيرة + تسمية + أيقونة
/// دلالية، بنفس أسلوب `_KpiCard` الخاص في `manager_home.dart`
/// (`features/home/`)، لكن معلَّنة هنا كمكوّن عام قابل لإعادة
/// الاستخدام عبر كل شاشات `features/analytics/` الأربع (بخلاف نسخة
/// `manager_home.dart` المحصورة في تلك الشاشة وحدها).
class AnalyticsKpiCard extends StatelessWidget {
  const AnalyticsKpiCard({
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

/// صف بطاقات المؤشرات الرئيسية (KPIs) أعلى `analytics_dashboard.dart`
/// — ست بطاقات مبنية مباشرة من Getters المشتقة في [AnalyticsData]
/// (`activeProjectsCount`/`averageProgressPercent`/`totalOpenTasksCount`/
/// `totalOpenPunchItemsCount`/`averageTodayAttendanceRate`/
/// `equipmentInMaintenanceCount`)، بتخطيط [Wrap] متجاوب يلتفّ تلقائياً
/// عند ضيق العرض بدل تجاوز الشاشة أفقياً (`Row` بسيط لا يناسب ست
/// بطاقات على شاشات سطح المكتب الأضيق).
///
/// مكوّن عرض بحت — لا يحمل أي منطق حساب؛ كل القيم تصل جاهزة عبر
/// [data].
class KpiSummaryRow extends StatelessWidget {
  const KpiSummaryRow({required this.data, super.key});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final List<AnalyticsKpiCard> cards = <AnalyticsKpiCard>[
      AnalyticsKpiCard(
        label: 'المشاريع النشطة',
        value: '${data.activeProjectsCount}',
        icon: Icons.folder_open_outlined,
      ),
      AnalyticsKpiCard(
        label: 'متوسط نسبة الإنجاز',
        value: NumberFormatter.percent(data.averageProgressPercent / 100),
        icon: Icons.trending_up_outlined,
        accent: AvahiStatus.success,
      ),
      AnalyticsKpiCard(
        label: 'مهام مفتوحة',
        value: '${data.totalOpenTasksCount}',
        icon: Icons.checklist_outlined,
        accent: AvahiStatus.warning,
      ),
      AnalyticsKpiCard(
        label: 'ملاحظات مفتوحة',
        value: '${data.totalOpenPunchItemsCount}',
        icon: Icons.report_gmailerrorred_outlined,
        accent: AvahiStatus.danger,
      ),
      AnalyticsKpiCard(
        label: 'متوسط نسبة حضور اليوم',
        value: NumberFormatter.percent(data.averageTodayAttendanceRate),
        subtitle: '${data.totalTodayAttendanceCount} حاضر اليوم',
        icon: Icons.how_to_reg_outlined,
      ),
      AnalyticsKpiCard(
        label: 'معدات قيد الصيانة',
        value: '${data.equipmentInMaintenanceCount}',
        subtitle: '${data.equipmentInUseCount} قيد الاستخدام',
        icon: Icons.build_outlined,
        accent: AvahiStatus.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // ثلاث بطاقات في الصف الواحد على الشاشات الواسعة، بطاقتان على
        // الشاشات المتوسطة — نفس عتبات `ShellMode` التقريبية المستخدمة
        // في `analytics_dashboard.dart` نفسها.
        final int columns = constraints.maxWidth >= 1100
            ? 6
            : constraints.maxWidth >= 720
                ? 3
                : 2;
        final double cardWidth =
            (constraints.maxWidth - (AvahiSpacing.md * (columns - 1))) /
                columns;

        return Wrap(
          spacing: AvahiSpacing.md,
          runSpacing: AvahiSpacing.md,
          children: <Widget>[
            for (final AnalyticsKpiCard card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}
