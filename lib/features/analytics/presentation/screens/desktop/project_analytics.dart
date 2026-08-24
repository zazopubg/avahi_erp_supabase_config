import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/entities/equipment.dart';
import '../../../../../domain/entities/project.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/status_badge.dart';
import '../../../../equipment/presentation/widgets/equipment_status_badge.dart' show EquipmentStatusBadge;
import '../../state/analytics_cubit.dart';
import '../../state/analytics_state.dart';
import '../../widgets/attendance_trend_chart.dart';
import '../../widgets/kpi_summary_row.dart';
import '../../widgets/task_distribution_chart.dart';
import 'analytics_dashboard.dart' show SectionCard;

/// لسان "المشاريع" ضمن `analytics_dashboard.dart` — تحليلات تفصيلية
/// لمشروع واحد يختاره المستخدم عبر [AvahiDropdown] أعلى الشاشة
/// ([AnalyticsCubit.selectProject]، تصفية عرض بحتة بلا استدعاء شبكة
/// إضافي — كل بيانات كل مشروع محمَّلة مسبقاً أصلاً ضمن [AnalyticsData]).
///
/// مكوّن عرض بحت — يستهلك [AnalyticsCubit] فقط لاستدعاء
/// [AnalyticsCubit.selectProject] عند تغيير الاختيار، وكل البيانات
/// المعروضة تصل جاهزة عبر [data].
class ProjectAnalytics extends StatelessWidget {
  const ProjectAnalytics({required this.data, super.key});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    if (data.companyProjects.isEmpty) {
      return const EmptyState(
        title: 'لا توجد مشاريع بعد',
        message: 'ستظهر هنا تحليلات كل مشروع بمجرد إنشائه.',
        icon: Icons.folder_off_outlined,
      );
    }

    final AnalyticsCubit cubit = context.read<AnalyticsCubit>();
    final Project selected = data.selectedProject ?? data.companyProjects.first;

    // اختيار أول مشروع تلقائياً عند أول دخول للسان (بلا مشروع مختار
    // مسبقاً) — يتجنّب شاشة فارغة تنتظر تفاعل المستخدم أولاً.
    if (data.selectedProjectId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cubit.selectProject(selected.id);
      });
    }

    final ProjectAnalyticsSummary? summary = data.projectSummaries[selected.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AvahiDropdown<String>(
            label: 'المشروع',
            value: selected.id,
            items: <AvahiDropdownItem<String>>[
              for (final Project project in data.companyProjects)
                AvahiDropdownItem<String>(
                  value: project.id,
                  label: project.nameAr ?? project.name,
                  icon: Icons.folder_outlined,
                ),
            ],
            onChanged: (String? id) => cubit.selectProject(id),
          ),
          const SizedBox(height: AvahiSpacing.md),
          if (summary == null)
            const EmptyState(
              title: 'اختر مشروعاً لعرض تحليلاته',
              icon: Icons.touch_app_outlined,
            )
          else ...<Widget>[
            _ProjectKpiRow(summary: summary),
            const SizedBox(height: AvahiSpacing.lg),
            SectionCard(
              title: 'توزيع حالات المهام — ${selected.nameAr ?? selected.name}',
              child: TaskDistributionChart(
                distribution: data.taskStatusDistributionFor(selected.id),
              ),
            ),
            const SizedBox(height: AvahiSpacing.md),
            SectionCard(
              title: 'اتجاه الحضور اليومي — ${selected.nameAr ?? selected.name}',
              child: AttendanceTrendChart(
                points: data.attendanceTrendFor(selected.id),
              ),
            ),
            const SizedBox(height: AvahiSpacing.md),
            SectionCard(
              title: 'معدات المشروع',
              child: _ProjectEquipmentList(
                equipment: data.equipmentForProject(selected.id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectKpiRow extends StatelessWidget {
  const _ProjectKpiRow({required this.summary});

  final ProjectAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AvahiSpacing.md,
      runSpacing: AvahiSpacing.md,
      children: <Widget>[
        SizedBox(
          width: 220,
          child: AnalyticsKpiCard(
            label: 'نسبة الإنجاز',
            value: '${summary.progressPercent.toStringAsFixed(0)}%',
            icon: Icons.trending_up_outlined,
            accent: AvahiStatus.success,
            subtitle:
                '${summary.completedTasksCount} من ${summary.totalTasksCount} مهمة',
          ),
        ),
        SizedBox(
          width: 220,
          child: AnalyticsKpiCard(
            label: 'مهام مفتوحة',
            value: '${summary.openTasksCount}',
            icon: Icons.checklist_outlined,
            accent: AvahiStatus.warning,
          ),
        ),
        SizedBox(
          width: 220,
          child: AnalyticsKpiCard(
            label: 'ملاحظات مفتوحة',
            value: '${summary.openPunchItemsCount}',
            icon: Icons.report_gmailerrorred_outlined,
            accent: AvahiStatus.danger,
          ),
        ),
        SizedBox(
          width: 220,
          child: AnalyticsKpiCard(
            label: 'أعضاء الفريق',
            value: '${summary.projectMembersCount}',
            icon: Icons.groups_outlined,
          ),
        ),
      ],
    );
  }
}

class _ProjectEquipmentList extends StatelessWidget {
  const _ProjectEquipmentList({required this.equipment});

  final List<Equipment> equipment;

  @override
  Widget build(BuildContext context) {
    if (equipment.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AvahiSpacing.md),
        child: Text('لا توجد معدات مُسندة لهذا المشروع حالياً.'),
      );
    }

    return Column(
      children: <Widget>[
        for (final Equipment item in equipment)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xxs),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.nameAr ?? item.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                EquipmentStatusBadge(status: item.status, dense: true),
              ],
            ),
          ),
      ],
    );
  }
}
