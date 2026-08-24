import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/project.dart';
import '../../../../../domain/enums/project_status.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/projects_cubit.dart';
import '../../state/projects_state.dart';
import '../../widgets/project_status_badge.dart';
import '../shared/project_route_args.dart';

/// عرض إداري شامل للمشاريع (سطح المكتب) — جدول [DataGridRtl] لكل
/// مشاريع الشركة، موجّه لأدوار `Admin`/`ProjectManager` (انظر
/// `Permission.projectsView`/`projectsCreate`)، بنفس نمط
/// `PunchDashboard`/`TasksBoardScreen`. يُفتح داخلياً عبر
/// `MyProjectsScreen._ProjectsDispatcher` عند [ShellMode.isDesktop]
/// — بلا مسار `go_router` منفصل.
class ProjectsList extends StatelessWidget {
  const ProjectsList({super.key});

  void _openProject(BuildContext context, Project project) {
    final ProjectsCubit cubit = context.read<ProjectsCubit>();
    cubit.selectProject(project.id);
    context.pushNamed(
      RouteNames.projectDetails,
      pathParameters: <String, String>{'id': project.id},
      extra: ProjectRouteArgs(projectId: project.id, cubit: cubit),
    );
  }

  Future<void> _openCreateProjectDialog(BuildContext context) async {
    final ProjectsCubit cubit = context.read<ProjectsCubit>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController codeController = TextEditingController();
    final TextEditingController clientController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('مشروع جديد'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AvahiTextField(controller: nameController, label: 'اسم المشروع'),
                const SizedBox(height: AvahiSpacing.sm),
                AvahiTextField(controller: codeController, label: 'رمز المشروع (اختياري)'),
                const SizedBox(height: AvahiSpacing.sm),
                AvahiTextField(controller: clientController, label: 'اسم العميل (اختياري)'),
              ],
            ),
          ),
          actions: <Widget>[
            AvahiButton(
              label: 'إلغاء',
              variant: AvahiButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AvahiButton(
              label: 'إنشاء',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || nameController.text.trim().isEmpty) return;
    if (!context.mounted) return;

    await cubit.createProject(
      name: nameController.text,
      code: codeController.text.isEmpty ? null : codeController.text,
      clientName: clientController.text.isEmpty ? null : clientController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectsCubit, ProjectsState>(
      builder: (BuildContext context, ProjectsState state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('المشاريع'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.md),
                child: AvahiButton(
                  label: 'مشروع جديد',
                  icon: Icons.add,
                  onPressed: () => _openCreateProjectDialog(context),
                ),
              ),
            ],
          ),
          body: state.when<Widget>(
            loading: () => const LoadingIndicator(label: 'جارٍ تحميل المشاريع...'),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل المشاريع',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser user, _) =>
                      context.read<ProjectsCubit>().loadInitial(user),
                );
              },
            ),
            loaded: (ProjectsData data) => Padding(
              padding: const EdgeInsets.all(AvahiSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AvahiTextField(
                          hint: 'ابحث باسم المشروع أو الرمز أو العميل...',
                          prefixIcon: Icons.search,
                          onChanged: (String q) =>
                              context.read<ProjectsCubit>().setSearchQuery(q),
                        ),
                      ),
                      const SizedBox(width: AvahiSpacing.md),
                      SizedBox(
                        width: 220,
                        child: AvahiDropdown<ProjectStatus?>(
                          value: data.statusFilter,
                          hint: 'الحالة',
                          items: <AvahiDropdownItem<ProjectStatus?>>[
                            const AvahiDropdownItem<ProjectStatus?>(value: null, label: 'الكل'),
                            for (final ProjectStatus s in ProjectStatus.values)
                              AvahiDropdownItem<ProjectStatus?>(value: s, label: s.displayLabel),
                          ],
                          onChanged: (ProjectStatus? s) =>
                              context.read<ProjectsCubit>().setStatusFilter(s),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AvahiSpacing.md),
                  Expanded(
                    child: DataGridRtl<Project>(
                      columns: <DataGridColumn<Project>>[
                        DataGridColumn<Project>(
                          label: 'اسم المشروع',
                          flex: 3,
                          cellBuilder: (BuildContext context, Project p) => Text(
                            p.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataGridColumn<Project>(
                          label: 'العميل',
                          flex: 2,
                          cellBuilder: (BuildContext context, Project p) =>
                              Text(p.clientName ?? '—'),
                        ),
                        DataGridColumn<Project>(
                          label: 'الحالة',
                                          cellBuilder: (BuildContext context, Project p) =>
                              ProjectStatusBadge(status: p.status, dense: true),
                        ),
                        DataGridColumn<Project>(
                          label: 'تاريخ البدء',
                                          cellBuilder: (BuildContext context, Project p) => Text(
                            p.startDate == null
                                ? '—'
                                : '${p.startDate!.year}/${p.startDate!.month.toString().padLeft(2, '0')}',
                          ),
                        ),
                        DataGridColumn<Project>(
                          label: '',
                                          cellBuilder: (BuildContext context, Project p) => Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => _openProject(context, p),
                              child: const Text('فتح'),
                            ),
                          ),
                        ),
                      ],
                      rows: data.filteredProjects,
                      rowKeyOf: (Project p) => p.id,
                      onRowTap: (Project p) => _openProject(context, p),
                      emptyTitle: data.hasActiveFilters
                          ? 'لا نتائج مطابقة للفلاتر'
                          : 'لا توجد مشاريع بعد',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
