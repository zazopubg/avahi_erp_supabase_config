import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/project.dart';
import '../../../../../domain/entities/project_milestone.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/projects_cubit.dart';
import '../../state/projects_state.dart';
import '../../widgets/project_progress_bar.dart';
import '../../widgets/project_status_badge.dart';
import '../desktop/project_details.dart';
import '../shared/project_route_args.dart';

/// نقطة الدخول الوحيدة لمسارات `/projects/:id`، `/projects/:id/members`،
/// `/projects/:id/milestones` معاً — بنفس نمط `MyProjectsScreen`/
/// `PunchListScreen`: تستقبل [ProjectRouteArgs] (المشروع مُختار سلفاً
/// عبر [ProjectsCubit.selectProject] من الشاشة السابقة)، تُعيد التأكد
/// من تحميل بيانات هذا المشروع بالذات عند دخول مباشر (Deep Link)، ثم
/// تفرّع العرض حسب [ShellMode]: [_ProjectOverviewMobileBody] (هذا
/// الملف) على الهاتف، [ProjectDetails] (`screens/desktop/project_details.dart`)
/// على سطح المكتب — دون أي مسار `go_router` منفصل للأخير، تماماً كما
/// تُفوَّض `PunchDashboard` من `PunchListScreen`.
class ProjectOverviewScreen extends StatefulWidget {
  const ProjectOverviewScreen({required this.args, super.key});

  final ProjectRouteArgs args;

  @override
  State<ProjectOverviewScreen> createState() => _ProjectOverviewScreenState();
}

class _ProjectOverviewScreenState extends State<ProjectOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // دعم الدخول المباشر (Deep Link) قبل أن يكون المشروع مُختاراً
    // مسبقاً ضمن [ProjectsCubit] — إعادة الاختيار هنا آمنة ورخيصة
    // (`selectProject` تعتمد أولاً على `myProjects` المحمَّلة كاش).
    final ProjectsData? data = widget.args.cubit.state.dataOrNull;
    if (data?.selectedProject?.id != widget.args.projectId) {
      widget.args.cubit.selectProject(widget.args.projectId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectsCubit>.value(
      value: widget.args.cubit,
      child: context.shellMode.isDesktop
          ? const ProjectDetails()
          : const _ProjectOverviewMobileBody(),
    );
  }
}

class _ProjectOverviewMobileBody extends StatelessWidget {
  const _ProjectOverviewMobileBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectsCubit, ProjectsState>(
      builder: (BuildContext context, ProjectsState state) {
        final ProjectsData? data = state.dataOrNull;
        final Project? project = data?.selectedProject;

        if (project == null) {
          return state.maybeWhen<Widget>(
            orElse: () => const Scaffold(body: LoadingIndicator()),
            error: (Failure failure) => Scaffold(
              appBar: AppBar(title: const Text('المشروع')),
              body: ErrorView(title: 'تعذّر تحميل المشروع', message: failure.message),
            ),
          );
        }

        final Map<String, num> dashboard = data!.dashboard;
        final int openTasks = (dashboard['openTasksCount'] ?? 0).toInt();
        final int openPunchItems = (dashboard['openPunchItemsCount'] ?? 0).toInt();
        final int membersCount = (dashboard['projectMembersCount'] ?? 0).toInt();
        final double attendanceRate = (dashboard['todayAttendanceRate'] ?? 0).toDouble();

        return Scaffold(
          appBar: AppBar(title: Text(project.name)),
          body: RefreshIndicator(
            onRefresh: () async {
              final ProjectsCubit cubit = context.read<ProjectsCubit>();
              await cubit.loadDashboard(project.id);
              await cubit.loadMilestones(project.id);
            },
            child: ListView(
              padding: const EdgeInsets.all(AvahiSpacing.md),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        project.clientName ?? project.code ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ProjectStatusBadge(status: project.status),
                  ],
                ),
                const SizedBox(height: AvahiSpacing.md),
                if (data.isDashboardLoading)
                  const LoadingIndicator(label: 'جارٍ تحميل لوحة المشروع...')
                else ...<Widget>[
                  ProjectProgressBar(
                    progress: attendanceRate,
                    label: 'نسبة الحضور اليوم',
                  ),
                  const SizedBox(height: AvahiSpacing.lg),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _OverviewStatTile(
                          icon: Icons.checklist_outlined,
                          label: 'مهام مفتوحة',
                          value: '$openTasks',
                          onTap: () => context.goNamed(RouteNames.tasks),
                        ),
                      ),
                      const SizedBox(width: AvahiSpacing.sm),
                      Expanded(
                        child: _OverviewStatTile(
                          icon: Icons.playlist_add_check,
                          label: 'ملاحظات مفتوحة',
                          value: '$openPunchItems',
                          onTap: () => context.goNamed(RouteNames.punchList),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AvahiSpacing.sm),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _OverviewStatTile(
                          icon: Icons.groups_outlined,
                          label: 'أعضاء الفريق',
                          value: '$membersCount',
                          onTap: () => context.pushNamed(
                            RouteNames.projectMembers,
                            pathParameters: <String, String>{'id': project.id},
                            extra: ProjectRouteArgs(
                              projectId: project.id,
                              cubit: context.read<ProjectsCubit>(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AvahiSpacing.sm),
                      Expanded(
                        child: _OverviewStatTile(
                          icon: Icons.camera_alt_outlined,
                          label: 'الصور',
                          value: '',
                          onTap: () => context.goNamed(RouteNames.photos),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AvahiSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'المراحل القادمة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.pushNamed(
                        RouteNames.projectMilestones,
                        pathParameters: <String, String>{'id': project.id},
                        extra: ProjectRouteArgs(
                          projectId: project.id,
                          cubit: context.read<ProjectsCubit>(),
                        ),
                      ),
                      child: const Text('عرض الكل'),
                    ),
                  ],
                ),
                if (data.isMilestonesLoading)
                  const LoadingIndicator()
                else if (data.upcomingMilestones.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.sm),
                    child: Text(
                      'لا توجد مراحل قادمة بعد.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  for (final ProjectMilestone m in data.upcomingMilestones.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AvahiSpacing.sm),
                      child: _MilestonePreviewTile(milestone: m),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverviewStatTile extends StatelessWidget {
  const _OverviewStatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AvahiSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(height: AvahiSpacing.xs),
            if (value.isNotEmpty)
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MilestonePreviewTile extends StatelessWidget {
  const _MilestonePreviewTile({required this.milestone});

  final ProjectMilestone milestone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            milestone.isOverdue ? Icons.warning_amber_rounded : Icons.flag_outlined,
            size: 18,
            color: milestone.isOverdue ? Colors.orange : null,
          ),
          const SizedBox(width: AvahiSpacing.sm),
          Expanded(
            child: Text(milestone.title, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: AvahiSpacing.sm),
          SizedBox(
            width: 60,
            child: ProjectProgressBar(
              progress: milestone.progressPercent / 100,
              showPercentLabel: false,
              height: 6,
            ),
          ),
        ],
      ),
    );
  }
}
