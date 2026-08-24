import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../state/equipment_state.dart';

/// رسم بياني خطي لساعات التشغيل التراكمية لمعدة واحدة عبر
/// `fl_chart` — يعرض [entries] (سجل الجلسة الحالية فقط، انظر توثيق
/// القرار الكامل في [EquipmentData.usageLogByEquipmentId]) كخط تراكمي
/// صاعد، مع نقطة لكل تسجيل ساعات.
///
/// مكوّن عرض بحت — لا يستدعي `EquipmentCubit` مباشرة، ويعرض حالة
/// فارغة بسيطة عندما تكون [entries] فارغة (لم تُسجَّل أي ساعات بعد
/// خلال هذه الجلسة) بدل رسم بياني خالٍ من المعنى.
class UsageHoursChart extends StatelessWidget {
  const UsageHoursChart({
    required this.entries,
    super.key,
    this.height = 180,
  });

  final List<UsageLogEntry> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    if (entries.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'سجّل ساعات تشغيل خلال هذه الجلسة لعرض الرسم البياني.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final List<FlSpot> spots = <FlSpot>[
      for (int i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), entries[i].cumulativeHoursAfter),
    ];

    final double minY = entries
        .map((UsageLogEntry e) => e.cumulativeHoursAfter)
        .reduce((double a, double b) => a < b ? a : b);
    final double maxY = entries
        .map((UsageLogEntry e) => e.cumulativeHoursAfter)
        .reduce((double a, double b) => a > b ? a : b);
    final double padding = (maxY - minY).abs() < 1 ? 1 : (maxY - minY) * 0.15;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          top: AvahiSpacing.sm,
          end: AvahiSpacing.md,
        ),
        child: LineChart(
          LineChartData(
            minY: (minY - padding).clamp(0, double.infinity),
            maxY: maxY + padding,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: ((maxY - minY) / 3).clamp(1, double.infinity),
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
                  reservedSize: 40,
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
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AvahiSpacing.xxs),
                      child: Text(
                        DateFormatter.shortDate(entries[index].loggedAt)
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
                    final UsageLogEntry entry = entries[spot.x.toInt()];
                    return LineTooltipItem(
                      '${entry.cumulativeHoursAfter.toStringAsFixed(1)} ساعة\n'
                      '+${entry.additionalHours.toStringAsFixed(1)}',
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
