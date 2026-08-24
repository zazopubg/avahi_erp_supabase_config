import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/project.dart';
import '../../../../../domain/enums/project_status.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/projects_cubit.dart';
import '../../state/projects_state.dart';
import '../../widgets/project_card.dart';
import '../../widgets/project_status_badge.dart';
import '../desktop/projects_list.dart';
import '../shared/project_route_args.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.projects` (`/projects`) —
/// بنفس نمط `PunchListScreen` تماماً: توفّر [ProjectsCubit] محلياً
/// عبر `sl<ProjectsCubit>()..loadInitial(user)` ثم تفرّع العرض حسب
/// [ShellMode] فقط (`_ProjectsDispatcher`).
///
/// ⚠️ قرار تسمية: بنفس منطق `PunchListScreen` (انظر توثيقها)، هذا
/// الصنف يجمع نقطة الدخول الموحَّدة **و**واجهة الهاتف نفسها
/// (`_MyProjectsMobileBody`، قائمة "مشاريعي" — مطابق حرفياً لاسم
/// الملف `my_projects_screen.dart` في شجرة Prompt 20) معاً، بينما
/// يُفوَّض عرض سطح المكتب داخلياً إلى [ProjectsList]
/// (`screens/desktop/projects_list.dart`) دون أي مسار `go_router`
/// منفصل لها.
class MyProjectsScreen extends StatelessWidget {
  const MyProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<ProjectsCubit>(
              create: (_) => sl<ProjectsCubit>()..loadInitial(user),
              child: const _ProjectsDispatcher(),
            );
          },
        );
      },
    );
  }
}

class _ProjectsDispatcher extends StatelessWidget {
  const _ProjectsDispatcher();

  @override
  Widget build(BuildContext context) {
    if (context.shellMode.isDesktop) return const ProjectsList();
    return const _MyProjectsMobileBody();
  }
}

class _MyProjectsMobileBody extends StatefulWidget {
  const _MyProjectsMobileBody();

  @override
  State<_MyProjectsMobileBody> createState() => _MyProjectsMobileBodyState();
}

class _MyProjectsMobileBodyState extends State<_MyProjectsMobileBody> {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AvahiTextField(controller: nameController, label: 'اسم المشروع'),
              const SizedBox(height: AvahiSpacing.sm),
              AvahiTextField(controller: codeController, label: 'رمز المشروع (اختياري)'),
              const SizedBox(height: AvahiSpacing.sm),
              AvahiTextField(controller: clientController, label: 'اسم العميل (اختياري)'),
            ],
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
            title: const Text('مشاريعي'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'مشروع جديد',
                onPressed: () => _openCreateProjectDialog(context),
              ),
            ],
          ),
          body: state.when<Widget>(
            loading: () => const LoadingIndicator(label: 'جارٍ تحميل مشاريعك...'),
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
            loaded: (ProjectsData data) => RefreshIndicator(
              onRefresh: () => context.read<ProjectsCubit>().refresh(),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AvahiSpacing.md,
                      AvahiSpacing.sm,
                      AvahiSpacing.md,
                      0,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: AvahiTextField(
                            hint: 'ابحث باسم المشروع أو الرمز أو العميل...',
                            prefixIcon: Icons.search,
                            onChanged: (String q) =>
                                context.read<ProjectsCubit>().setSearchQuery(q),
                          ),
                        ),
                        const SizedBox(width: AvahiSpacing.sm),
                        AvahiDropdown<ProjectStatus?>(
                          value: data.statusFilter,
                          hint: 'الحالة',
                          items: <AvahiDropdownItem<ProjectStatus?>>[
                            const AvahiDropdownItem<ProjectStatus?>(
                              value: null,
                              label: 'الكل',
                            ),
                            for (final ProjectStatus s in ProjectStatus.values)
                              AvahiDropdownItem<ProjectStatus?>(
                                value: s,
                                label: s.displayLabel,
                              ),
                          ],
                          onChanged: (ProjectStatus? s) =>
                              context.read<ProjectsCubit>().setStatusFilter(s),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: data.filteredProjects.isEmpty
                        ? EmptyState(
                            title: data.hasActiveFilters
                                ? 'لا نتائج مطابقة للفلاتر'
                                : 'لا توجد مشاريع بعد',
                            message: data.hasActiveFilters
                                ? 'جرّب تعديل معايير التصفية.'
                                : 'أنشئ أول مشروع عبر زر "+" أعلاه.',
                            icon: Icons.apartment_outlined,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AvahiSpacing.md),
                            itemCount: data.filteredProjects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AvahiSpacing.sm),
                            itemBuilder: (BuildContext context, int index) {
                              final Project project = data.filteredProjects[index];
                              return ProjectCard(
                                project: project,
                                onTap: () => _openProject(context, project),
                              );
                            },
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
