import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/enums/task_status.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/empty_state.dart';

/// يترجم [TaskStatus] إلى تسمية عربية ولون دلالي مخصّص للرسم البياني
/// الدائري — نفس التسميات المستخدمة في `TaskStatusChip`
/// (`features/tasks/presentation/widgets/task_status_chip.dart`)
/// لضمان اتساق التسمية بين لوحة Kanban ولوحة التحليلات، لكن مُعاد
/// تعريفه هنا محلياً لأن الدالة الأصلية خاصة (`_visualsFor`) بذلك
/// الملف ولا يمكن استيرادها مباشرة.
(String, Color) _taskStatusVisuals(TaskStatus status, AvahiColors colors) {
  return switch (status) {
    TaskStatus.todo => ('قائمة الانتظار', colors.onSurfaceVariant),
    TaskStatus.inProgress => ('قيد التنفيذ', colors.info),
    TaskStatus.review => ('قيد المراجعة', colors.warning),
    TaskStatus.done => ('مكتملة', colors.success),
    TaskStatus.blocked => ('معلّقة', colors.danger),
  };
}

/// رسم بياني دائري (PieChart) لتوزيع حالات المهام — يستهلك
/// [AnalyticsData.taskStatusDistribution] (أو
/// [AnalyticsData.taskStatusDistributionFor] لمشروع واحد من
/// `project_analytics.dart`) عبر [distribution]، مع مفتاح ألوان
/// (Legend) جانبي يعرض التسمية والعدد لكل حالة.
///
/// مكوّن عرض بحت — لا يستدعي `AnalyticsCubit` مباشرة.
class TaskDistributionChart extends StatelessWidget {
  const TaskDistributionChart({
    required this.distribution,
    super.key,
    this.height = 220,
  });

  final Map<TaskStatus, int> distribution;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final int total =
        distribution.values.fold<int>(0, (int acc, int v) => acc + v);

    if (total == 0) {
      return SizedBox(
        height: height,
        child: const EmptyState(
          title: 'لا توجد مهام لعرض توزيعها',
          icon: Icons.pie_chart_outline,
        ),
      );
    }

    final List<MapEntry<TaskStatus, int>> nonZero = distribution.entries
        .where((MapEntry<TaskStatus, int> e) => e.value > 0)
        .toList(growable: false);

    return SizedBox(
      height: height,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: <PieChartSectionData>[
                  for (final MapEntry<TaskStatus, int> entry in nonZero)
                    PieChartSectionData(
                      value: entry.value.toDouble(),
                      color: _taskStatusVisuals(entry.key, colors).$2,
                      title: '${entry.value}',
                      radius: 56,
                      titleStyle: TextStyle(
                        color: colors.onBrandContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AvahiSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final MapEntry<TaskStatus, int> entry in nonZero)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AvahiSpacing.xxs,
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _taskStatusVisuals(entry.key, colors).$2,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AvahiSpacing.xs),
                        Expanded(
                          child: Text(
                            _taskStatusVisuals(entry.key, colors).$1,
                            style: context.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
