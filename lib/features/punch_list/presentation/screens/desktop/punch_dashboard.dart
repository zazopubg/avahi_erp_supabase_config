import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/project.dart';
import '../../../../../domain/entities/punch_item.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/punch_cubit.dart';
import '../../state/punch_state.dart';
import '../../widgets/punch_item_card.dart';
import '../../widgets/punch_status_filter.dart';
import '../../widgets/task_priority_selector_items.dart';
import 'punch_item_manage.dart';

/// لوحة متابعة سطح المكتب — تعرض **كل** العيوب المفتوحة عبر **كل**
/// مشاريع المستخدم معاً (بخلاف بقية شاشات الميزة المقيَّدة بمشروع
/// واحد)، مرتّبة زمنياً من الأقدم للأحدث، مع مؤشرات أداء علوية ولوحة
/// إدارة جانبية ([PunchItemManage]) — نظير `tasks_list_screen.dart`
/// (`features/tasks/`) من حيث تخطيط "قائمة + لوحة جانبية"، لكن بمصدر
/// بيانات مختلف تماماً ([PunchData.dashboardItems] لا [PunchData.items]).
///
/// تفترض وجود `BlocProvider<PunchCubit>` مُزوَّد مسبقاً من
/// `punch_list_screen.dart` (`PunchListScreen` تُفوِّض إليها مباشرة
/// عند `ShellMode.desktop`، بلا مسار `go_router` منفصل لها) — لا
/// تُنشئ نسخة `PunchCubit` خاصة بها.
class PunchDashboard extends StatefulWidget {
  const PunchDashboard({super.key});

  @override
  State<PunchDashboard> createState() => _PunchDashboardState();
}

class _PunchDashboardState extends State<PunchDashboard> {
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    // تحميل كسول — لا تُجلَب عيوب كل المشاريع إلا عند دخول لوحة سطح
    // المكتب فعلياً، انظر توثيق `PunchCubit.loadDashboard`.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PunchCubit>().loadDashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة متابعة قوائم الملاحظات')),
      body: BlocBuilder<PunchCubit, PunchState>(
        builder: (BuildContext context, PunchState state) {
          return state.when<Widget>(
            loading: () => const LoadingIndicator(),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل اللوحة',
              message: failure.message,
              onRetry: () => context.read<PunchCubit>().loadDashboard(),
            ),
            loaded: (PunchData data) {
              if (data.isDashboardLoading && data.dashboardItems.isEmpty) {
                return const LoadingIndicator(
                  label: 'جارٍ تجميع عيوب كل المشاريع...',
                );
              }

              final List<PunchItem> visible = _applyDashboardFilters(data);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AvahiSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _StatsRow(data: data),
                          const SizedBox(height: AvahiSpacing.lg),
                          PunchStatusFilter(
                            data: data,
                            onStatusChanged: (status) =>
                                context.read<PunchCubit>().setStatusFilter(status),
                            onSearchChanged: (query) =>
                                context.read<PunchCubit>().setSearchQuery(query),
                            onClearFilters: () =>
                                context.read<PunchCubit>().clearFilters(),
                          ),
                          const SizedBox(height: AvahiSpacing.md),
                          Expanded(
                            child: DataGridRtl<PunchItem>(
                              rows: visible,
                              rowKeyOf: (PunchItem item) => item.id,
                              emptyTitle: 'لا توجد عيوب مفتوحة عبر مشاريعك حالياً',
                              emptyIcon: Icons.playlist_add_check,
                              onRowTap: (PunchItem item) =>
                                  setState(() => _selectedItemId = item.id),
                              columns: <DataGridColumn<PunchItem>>[
                                DataGridColumn<PunchItem>(
                                  label: 'العنوان',
                                  flex: 3,
                                  cellBuilder: (context, item) => Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DataGridColumn<PunchItem>(
                                  label: 'المشروع',
                                  flex: 2,
                                  cellBuilder: (context, item) => Text(
                                    data.projectsById[item.projectId]?.name ?? '—',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DataGridColumn<PunchItem>(
                                  label: 'الأولوية',
                                  cellBuilder: (context, item) =>
                                      Text(punchPriorityLabelAr(item.priority)),
                                ),
                                DataGridColumn<PunchItem>(
                                  label: 'الحالة',
                                  cellBuilder: (context, item) =>
                                      PunchStatusBadge(status: item.status, dense: true),
                                ),
                                DataGridColumn<PunchItem>(
                                  label: 'أُنشئ في',
                                  cellBuilder: (context, item) =>
                                      Text(DateFormatter.shortDate(item.createdAt)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PunchItemManage(
                    itemId: _selectedItemId,
                    onClose: () => setState(() => _selectedItemId = null),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<PunchItem> _applyDashboardFilters(PunchData data) {
    final String query = data.searchQuery.trim().toLowerCase();
    return data.dashboardItems.where((PunchItem item) {
      if (data.statusFilter != null && item.status != data.statusFilter) {
        return false;
      }
      if (query.isNotEmpty && !item.title.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }
}

/// صف بطاقات مؤشرات أداء علوية — عدد العيوب المفتوحة عبر كل
/// المشاريع، عدد المتأخرة عن `dueDate`، وعدد المشاريع النشطة نفسها.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});

  final PunchData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            icon: Icons.report_problem_outlined,
            label: 'عيوب مفتوحة (كل المشاريع)',
            value: data.dashboardItems.length.toString(),
          ),
        ),
        const SizedBox(width: AvahiSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.event_busy_outlined,
            label: 'متأخرة عن الاستحقاق',
            value: data.overdueDashboardCount.toString(),
            isDanger: data.overdueDashboardCount > 0,
          ),
        ),
        const SizedBox(width: AvahiSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.apartment_outlined,
            label: 'مشاريع نشطة',
            value: data.myProjects
                .where((Project p) => p.status.isActive)
                .length
                .toString(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: isDanger ? colors.danger : colors.brand),
          const SizedBox(width: AvahiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: isDanger ? colors.danger : null,
                  ),
                ),
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
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
