import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/project_member_detail.dart';
import '../../../../../navigation/role_labels.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dialog.dart';
import '../../../../../ui/widgets/common/avatar.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/projects_cubit.dart';
import '../../state/projects_state.dart';
import '../../widgets/member_role_selector.dart';
import '../shared/project_route_args.dart';

/// إدارة فريق عمل المشروع — قائمة الأعضاء المُسندين حالياً
/// ([ProjectMemberDetail]) مع إمكانية إزالة كل عضو، وزر "إضافة عضو"
/// يفتح [MemberRoleSelector] ضمن `AvahiDialog` لاختيار عضو شركة غير
/// مُسند بعد. مسار مستقل `/projects/:id/members` (سطح المكتب بشكل
/// أساسي، لكن يعمل بمرونة على أي حجم شاشة).
class ProjectMembersScreen extends StatefulWidget {
  const ProjectMembersScreen({required this.args, super.key});

  final ProjectRouteArgs args;

  @override
  State<ProjectMembersScreen> createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends State<ProjectMembersScreen> {
  @override
  void initState() {
    super.initState();
    final ProjectsData? data = widget.args.cubit.state.dataOrNull;
    if (data?.selectedProject?.id != widget.args.projectId) {
      widget.args.cubit.selectProject(widget.args.projectId);
    } else if (data!.members.isEmpty) {
      widget.args.cubit.loadMembers(widget.args.projectId);
    }
  }

  Future<void> _openAddMemberDialog(BuildContext context) async {
    final ProjectsCubit cubit = context.read<ProjectsCubit>();
    await cubit.loadAvailableMembers(widget.args.projectId);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('إضافة عضو للمشروع'),
          content: SizedBox(
            width: 420,
            child: BlocBuilder<ProjectsCubit, ProjectsState>(
              bloc: cubit,
              builder: (BuildContext context, ProjectsState state) {
                final ProjectsData? data = state.dataOrNull;
                return MemberRoleSelector(
                  availableMembers: data?.availableMembers ?? const <AppUser>[],
                  isLoading: data?.isAvailableMembersLoading ?? true,
                  isSubmitting: data?.isMemberActionInProgress ?? false,
                  onMemberSelected: (AppUser user) async {
                    final bool ok = await cubit.addMember(
                      projectId: widget.args.projectId,
                      userId: user.userId,
                    );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            AvahiButton(
              label: 'إغلاق',
              variant: AvahiButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRemoveMember(BuildContext context, ProjectMemberDetail member) {
    final ProjectsCubit cubit = context.read<ProjectsCubit>();
    return AvahiDialog.show(
      context,
      title: 'إزالة العضو',
      message: 'هل تريد إزالة "${member.user.fullName}" من فريق هذا المشروع؟',
      confirmLabel: 'إزالة',
      cancelLabel: 'إلغاء',
      isDestructive: true,
      onConfirm: () {
        Navigator.of(context).pop();
        cubit.removeMember(member);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectsCubit>.value(
      value: widget.args.cubit,
      child: BlocBuilder<ProjectsCubit, ProjectsState>(
        builder: (BuildContext context, ProjectsState state) {
          final ProjectsData? data = state.dataOrNull;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => context.pop(),
              ),
              title: Text('فريق العمل — ${data?.selectedProject?.name ?? ''}'),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.md),
                  child: AvahiButton(
                    label: 'إضافة عضو',
                    icon: Icons.person_add_alt_1,
                    onPressed: () => _openAddMemberDialog(context),
                  ),
                ),
              ],
            ),
            body: state.maybeWhen<Widget>(
              orElse: () => const LoadingIndicator(),
              error: (Failure failure) => ErrorView(
                title: 'تعذّر تحميل بيانات المشروع',
                message: failure.message,
              ),
              loaded: (ProjectsData d) {
                if (d.isMembersLoading) {
                  return const LoadingIndicator(label: 'جارٍ تحميل فريق العمل...');
                }
                if (d.members.isEmpty) {
                  return const EmptyState(
                    title: 'لا يوجد أعضاء بعد',
                    message: 'أضف أول عضو لفريق هذا المشروع عبر زر "إضافة عضو" أعلاه.',
                    icon: Icons.groups_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AvahiSpacing.lg),
                  itemCount: d.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AvahiSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    final ProjectMemberDetail member = d.members[index];
                    return ListTile(
                      tileColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      leading: Avatar(
                        imageUrl: member.user.avatarUrl,
                        name: member.user.fullName,
                      ),
                      title: Text(member.user.fullName),
                      subtitle: Text(member.user.jobTitle ?? member.user.role.displayLabel),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove_outlined),
                        tooltip: 'إزالة من المشروع',
                        onPressed: d.isMemberActionInProgress
                            ? null
                            : () => _confirmRemoveMember(context, member),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
