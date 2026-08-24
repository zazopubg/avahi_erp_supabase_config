import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/project.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/empty_state.dart';

/// رسم بياني شريطي (BarChart) لنسب تقدّم المشاريع — يستهلك
/// [AnalyticsData.projectProgressList] مباشرة (قائمة مرتَّبة تنازلياً
/// مسبقاً)، ويقتصر على أول [maxProjects] مشروعاً لتفادي ازدحام بصري
/// عند وجود عشرات المشاريع (`analytics_dashboard.dart` يعرض القائمة
/// الكاملة كجدول نصي في `export_analytics_screen.dart`/PDF بدل ذلك).
///
/// مكوّن عرض بحت — لا يحمل أي منطق فرز أو حساب نسب؛ يصل [projects]
/// جاهزاً من [AnalyticsData.projectProgressList].
class ProjectProgressChart extends StatelessWidget {
  const ProjectProgressChart({
    required this.projects,
    super.key,
    this.maxProjects = 8,
    this.height = 260,
  });

  final List<MapEntry<Project, double>> projects;
  final int maxProjects;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    if (projects.isEmpty) {
      return SizedBox(
        height: height,
        child: const EmptyState(
          title: 'لا توجد مشاريع لعرض تقدّمها',
          icon: Icons.bar_chart_outlined,
        ),
      );
    }

    final List<MapEntry<Project, double>> visible =
        projects.take(maxProjects).toList(growable: false);

    Color barColorFor(double percent) {
      if (percent >= 75) return colors.success;
      if (percent >= 40) return colors.info;
      if (percent > 0) return colors.warning;
      return colors.outlineVariant;
    }

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          top: AvahiSpacing.sm,
          end: AvahiSpacing.md,
        ),
        child: BarChart(
          BarChartData(
            maxY: 100,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 25,
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
                  reservedSize: 36,
                  interval: 25,
                  getTitlesWidget: (double value, TitleMeta meta) => Text(
                    '${value.toStringAsFixed(0)}%',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.round();
                    if (index < 0 || index >= visible.length) {
                      return const SizedBox.shrink();
                    }
                    final Project project = visible[index].key;
                    final String name = project.nameAr ?? project.name;
                    final String short =
                        name.length > 10 ? '${name.substring(0, 9)}…' : name;
                    return Padding(
                      padding: const EdgeInsets.only(top: AvahiSpacing.xxs),
                      child: Text(
                        short,
                        textAlign: TextAlign.center,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (
                  BarChartGroupData group,
                  int groupIndex,
                  BarChartRodData rod,
                  int rodIndex,
                ) {
                  final Project project = visible[groupIndex].key;
                  final String displayName = project.nameAr ?? project.name;
                  return BarTooltipItem(
                    '$displayName\n${rod.toY.toStringAsFixed(0)}%',
                    TextStyle(color: colors.onSurface, fontSize: 12),
                  );
                },
              ),
            ),
            barGroups: <BarChartGroupData>[
              for (int i = 0; i < visible.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: visible[i].value,
                      color: barColorFor(visible[i].value),
                      width: 22,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: colors.surfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
