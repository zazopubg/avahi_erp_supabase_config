import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/project.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_radius.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/projects_cubit.dart';
import '../../state/projects_state.dart';
import '../../widgets/project_progress_bar.dart';
import '../../widgets/project_status_badge.dart';
import '../shared/project_route_args.dart';

/// لوحة تفاصيل مشروع متكاملة (سطح المكتب) — رأس معلومات المشروع
/// (الاسم، العميل، الحالة، النطاق الزمني)، لوحة أرقام سريعة
/// (`IProjectRepository.getProjectDashboard`)، وشبكة روابط سريعة لكل
/// ميزات المشروع (المهام، العيوب، التقارير، الصور، المستندات، مع
/// رابط استباقي لميزة `/equipment` القادمة — Prompt 22)، إضافة إلى
/// أزرار فتح `project_members.dart`/`project_milestones.dart`/
/// `project_settings.dart`. تُفتح داخلياً من `ProjectOverviewScreen`
/// عند [ShellMode.isDesktop] — بلا مسار `go_router` منفصل.
class ProjectDetails extends StatelessWidget {
  const ProjectDetails({super.key});

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
              body: ErrorView(title: 'تعذّر تحميل المشروع', message: failure.message),
            ),
          );
        }

        final Map<String, num> dashboard = data!.dashboard;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => context.goNamed(RouteNames.projects),
            ),
            title: Text(project.name),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.sm),
                child: AvahiButton(
                  label: 'الإعدادات',
                  variant: AvahiButtonVariant.secondary,
                  icon: Icons.settings_outlined,
                  onPressed: () => context.pushNamed(
                    RouteNames.projectSettings,
                    pathParameters: <String, String>{'id': project.id},
                    extra: ProjectRouteArgs(
                      projectId: project.id,
                      cubit: context.read<ProjectsCubit>(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AvahiSpacing.lg),
            child: ListView(
              children: <Widget>[
                _HeaderCard(project: project, dashboard: dashboard, isLoading: data.isDashboardLoading),
                const SizedBox(height: AvahiSpacing.lg),
                Text(
                  'روابط سريعة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AvahiSpacing.sm),
                Wrap(
                  spacing: AvahiSpacing.sm,
                  runSpacing: AvahiSpacing.sm,
                  children: <Widget>[
                    _QuickLinkTile(
                      icon: Icons.checklist_outlined,
                      label: 'المهام',
                      onTap: () => context.goNamed(RouteNames.tasks),
                    ),
                    _QuickLinkTile(
                      icon: Icons.playlist_add_check,
                      label: 'العيوب (Punch List)',
                      onTap: () => context.goNamed(RouteNames.punchList),
                    ),
                    _QuickLinkTile(
                      icon: Icons.assignment_outlined,
                      label: 'التقارير الميدانية',
                      onTap: () => context.goNamed(RouteNames.fieldReports),
                    ),
                    _QuickLinkTile(
                      icon: Icons.camera_alt_outlined,
                      label: 'الصور',
                      onTap: () => context.goNamed(RouteNames.photos),
                    ),
                    _QuickLinkTile(
                      icon: Icons.folder_outlined,
                      label: 'المستندات',
                      onTap: () => context.goNamed(RouteNames.documents),
                    ),
                    // ⬜ رابط استباقي لميزة `/equipment` (Prompt 22) —
                    // لم تُبنَ بعد؛ يقود حالياً لشاشة `ComingSoonScreen`
                    // المؤقتة عبر نفس اسم المسار `RouteNames.equipment`
                    // (مسجَّل أصلاً منذ Prompt 12)، دون أي تعديل مطلوب
                    // لاحقاً هنا عند بناء الميزة فعلياً.
                    _QuickLinkTile(
                      icon: Icons.precision_manufacturing_outlined,
                      label: 'المعدات',
                      onTap: () => context.goNamed(RouteNames.equipment),
                    ),
                    _QuickLinkTile(
                      icon: Icons.groups_outlined,
                      label: 'فريق العمل',
                      onTap: () => context.pushNamed(
                        RouteNames.projectMembers,
                        pathParameters: <String, String>{'id': project.id},
                        extra: ProjectRouteArgs(
                          projectId: project.id,
                          cubit: context.read<ProjectsCubit>(),
                        ),
                      ),
                    ),
                    _QuickLinkTile(
                      icon: Icons.flag_outlined,
                      label: 'المراحل الرئيسية',
                      onTap: () => context.pushNamed(
                        RouteNames.projectMilestones,
                        pathParameters: <String, String>{'id': project.id},
                        extra: ProjectRouteArgs(
                          projectId: project.id,
                          cubit: context.read<ProjectsCubit>(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.project, required this.dashboard, required this.isLoading});

  final Project project;
  final Map<String, num> dashboard;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final double attendanceRate = (dashboard['todayAttendanceRate'] ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AvahiRadius.radiusLg,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      project.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (project.clientName != null || project.code != null)
                      Text(
                        <String>[
                          if (project.code != null) project.code!,
                          if (project.clientName != null) project.clientName!,
                        ].join(' • '),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              ProjectStatusBadge(status: project.status),
            ],
          ),
          const SizedBox(height: AvahiSpacing.md),
          if (isLoading)
            const LoadingIndicator()
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatBox(
                    label: 'مهام مفتوحة',
                    value: '${(dashboard['openTasksCount'] ?? 0).toInt()}',
                  ),
                ),
                Expanded(
                  child: _StatBox(
                    label: 'ملاحظات مفتوحة',
                    value: '${(dashboard['openPunchItemsCount'] ?? 0).toInt()}',
                  ),
                ),
                Expanded(
                  child: _StatBox(
                    label: 'أعضاء الفريق',
                    value: '${(dashboard['projectMembersCount'] ?? 0).toInt()}',
                  ),
                ),
                Expanded(
                  child: ProjectProgressBar(
                    progress: attendanceRate,
                    label: 'حضور اليوم',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  const _QuickLinkTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return InkWell(
      onTap: onTap,
      borderRadius: AvahiRadius.radiusMd,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(AvahiSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AvahiRadius.radiusMd,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: colors.brand),
            const SizedBox(width: AvahiSpacing.sm),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
