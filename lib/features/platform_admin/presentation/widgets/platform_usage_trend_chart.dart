import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/platform_usage_snapshot.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/empty_state.dart';

/// رسم بياني خطي (LineChart) لاتجاه عدد المستأجرين النشطين يومياً —
/// يستهلك [PlatformUsageSnapshot.dailyActiveTenantsTrend]، بنفس بنية
/// `AttendanceTrendChart` (`features/analytics/`) تماماً (مُستنسخة
/// محلياً — انظر توثيق قرار عدم الاستيراد العابر للميزات في
/// `PlatformSectionCard`). 🆕 (Prompt 28)
class PlatformUsageTrendChart extends StatelessWidget {
  const PlatformUsageTrendChart({
    required this.points,
    super.key,
    this.height = 220,
  });

  final List<PlatformUsageTrendPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: const EmptyState(
          title: 'لا توجد بيانات كافية لعرض الاتجاه',
          icon: Icons.show_chart_outlined,
        ),
      );
    }

    final List<FlSpot> spots = <FlSpot>[
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].activeTenantsCount.toDouble()),
    ];

    final int maxCount = points
        .map((PlatformUsageTrendPoint p) => p.activeTenantsCount)
        .reduce((int a, int b) => a > b ? a : b);
    final double maxY = maxCount == 0 ? 4 : maxCount * 1.2;

    final int labelStep = (points.length / 6).ceil().clamp(1, 30);

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          top: AvahiSpacing.sm,
          end: AvahiSpacing.md,
        ),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: (maxY / 4).clamp(1, double.infinity),
              getDrawingHorizontalLine: (_) => FlLine(
                color: colors.outlineVariant,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (double value, TitleMeta meta) => Text(
                    value.toStringAsFixed(0),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.round();
                    if (index < 0 ||
                        index >= points.length ||
                        index % labelStep != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AvahiSpacing.xxs),
                      child: Text(
                        DateFormatter.shortDate(points[index].date)
                            .substring(5),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> spots) {
                  return spots.map((LineBarSpot spot) {
                    final PlatformUsageTrendPoint point =
                        points[spot.x.toInt()];
                    return LineTooltipItem(
                      '${DateFormatter.shortDate(point.date)}\n'
                      '${point.activeTenantsCount} مستأجر نشط',
                      TextStyle(color: colors.onSurface, fontSize: 12),
                    );
                  }).toList(growable: false);
                },
              ),
            ),
            lineBarsData: <LineChartBarData>[
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: colors.brand,
                barWidth: 3,
                dotData: FlDotData(show: points.length <= 14),
                belowBarData: BarAreaData(
                  show: true,
                  color: colors.brand.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
