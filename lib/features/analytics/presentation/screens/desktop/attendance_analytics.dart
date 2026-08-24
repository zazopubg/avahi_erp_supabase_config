import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/number_formatter.dart';
import '../../../../../domain/entities/project.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/analytics_cubit.dart';
import '../../state/analytics_state.dart';
import '../../widgets/attendance_trend_chart.dart';
import '../../widgets/date_range_filter.dart';
import 'analytics_dashboard.dart' show SectionCard;

/// لسان "الحضور" ضمن `analytics_dashboard.dart` — سلسلة اتجاه الحضور
/// الزمنية الكاملة (نفس بيانات لسان "نظرة عامة" لكن بارتفاع أكبر
/// للتفصيل)، بالإضافة إلى جدول تفصيلي لنسبة حضور اليوم لكل مشروع على
/// حدة عبر [DataGridRtl] (`ui/widgets/desktop/`، Prompt 15) — يجيب عن
/// سؤال "أي المشاريع لديها أعلى/أدنى نسبة حضور اليوم؟" الذي لا يجيب
/// عنه الرسم البياني المجمَّع وحده.
///
/// مكوّن عرض بحت — يستهلك [AnalyticsCubit] فقط لاستدعاء
/// [AnalyticsCubit.setDateRange] عند تغيير المدى الزمني من
/// [DateRangeFilter] الخاص به (منفصل عن نسخة لسان "نظرة عامة" لكنه
/// يُحرّك **نفس** [AnalyticsData.rangeFrom]/[AnalyticsData.rangeTo] —
/// كلا اللسانين يبقيان متزامنين تلقائياً لأنهما يقرآن نفس [AnalyticsState]).
class AttendanceAnalytics extends StatelessWidget {
  const AttendanceAnalytics({required this.data, super.key});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final AnalyticsCubit cubit = context.read<AnalyticsCubit>();
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    final List<Project> sortedByRate = <Project>[...data.companyProjects]
      ..sort((Project a, Project b) {
        final double rateA = data.projectSummaries[a.id]?.todayAttendanceRate ?? 0;
        final double rateB = data.projectSummaries[b.id]?.todayAttendanceRate ?? 0;
        return rateB.compareTo(rateA);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DateRangeFilter(
            rangeFrom: data.rangeFrom,
            rangeTo: data.rangeTo,
            isRefreshing: data.isRefreshingRange,
            onRangeSelected: (record) =>
                cubit.setDateRange(from: record.$1, to: record.$2),
          ),
          const SizedBox(height: AvahiSpacing.md),
          SectionCard(
            title: 'اتجاه الحضور اليومي — كل المشاريع',
            child: AttendanceTrendChart(
              points: data.attendanceTrend,
              height: 300,
            ),
          ),
          const SizedBox(height: AvahiSpacing.md),
          SectionCard(
            title: 'نسبة حضور اليوم حسب المشروع',
            child: SizedBox(
              height: sortedByRate.isEmpty
                  ? 120
                  : (sortedByRate.length * 56).toDouble().clamp(120, 480),
              child: DataGridRtl<Project>(
                columns: <DataGridColumn<Project>>[
                  DataGridColumn<Project>(
                    label: 'المشروع',
                    flex: 3,
                    cellBuilder: (BuildContext context, Project project) =>
                        Text(project.nameAr ?? project.name),
                  ),
                  DataGridColumn<Project>(
                    label: 'الحاضرون اليوم',
                    cellBuilder: (BuildContext context, Project project) => Text(
                      '${data.projectSummaries[project.id]?.todayAttendanceCount ?? 0}'
                      ' / ${data.projectSummaries[project.id]?.projectMembersCount ?? 0}',
                    ),
                  ),
                  DataGridColumn<Project>(
                    label: 'نسبة الحضور',
                    cellBuilder: (BuildContext context, Project project) {
                      final double rate =
                          data.projectSummaries[project.id]?.todayAttendanceRate ?? 0;
                      return Text(
                        NumberFormatter.percent(rate),
                        style: TextStyle(
                          color: rate >= 0.75
                              ? colors.success
                              : rate >= 0.4
                                  ? colors.warning
                                  : colors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
                rows: sortedByRate,
                rowKeyOf: (Project p) => p.id,
                emptyTitle: 'لا توجد مشاريع لعرض بيانات حضورها',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
