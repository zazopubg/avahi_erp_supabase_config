import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/project_milestone.dart';
import '../../../../../domain/enums/milestone_status.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_radius.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dialog.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/projects_cubit.dart';
import '../../state/projects_state.dart';
import '../../widgets/project_progress_bar.dart';
import '../shared/project_route_args.dart';

/// تسمية عربية موحّدة لعرض [MilestoneStatus] ضمن قائمة الاختيار في
/// حوار تحديث المرحلة أعلاه.
extension _MilestoneStatusLabelX on MilestoneStatus {
  String get displayLabel {
    switch (this) {
      case MilestoneStatus.pending:
        return 'لم يبدأ';
      case MilestoneStatus.inProgress:
        return 'قيد التنفيذ';
      case MilestoneStatus.completed:
        return 'مكتملة';
      case MilestoneStatus.delayed:
        return 'متأخرة';
    }
  }
}

/// إدارة المراحل الرئيسية (Milestones) لمشروع — قائمة كل المراحل مع
/// نسبة الإنجاز وتاريخ الاستحقاق وحالة كل مرحلة، وزر "مرحلة جديدة".
/// مسار مستقل `/projects/:id/milestones`.
class ProjectMilestonesScreen extends StatefulWidget {
  const ProjectMilestonesScreen({required this.args, super.key});

  final ProjectRouteArgs args;

  @override
  State<ProjectMilestonesScreen> createState() => _ProjectMilestonesScreenState();
}

class _ProjectMilestonesScreenState extends State<ProjectMilestonesScreen> {
  @override
  void initState() {
    super.initState();
    final ProjectsData? data = widget.args.cubit.state.dataOrNull;
    if (data?.selectedProject?.id != widget.args.projectId) {
      widget.args.cubit.selectProject(widget.args.projectId);
    } else if (data!.milestones.isEmpty) {
      widget.args.cubit.loadMilestones(widget.args.projectId);
    }
  }

  Future<void> _openCreateMilestoneDialog(BuildContext context) async {
    final ProjectsCubit cubit = context.read<ProjectsCubit>();
    final TextEditingController titleController = TextEditingController();
    DateTime? dueDate;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('مرحلة رئيسية جديدة'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AvahiTextField(controller: titleController, label: 'عنوان المرحلة'),
                    const SizedBox(height: AvahiSpacing.sm),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            dueDate == null
                                ? 'بلا تاريخ استحقاق'
                                : 'الاستحقاق: ${dueDate!.year}/${dueDate!.month.toString().padLeft(2, '0')}/${dueDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                            );
                            if (picked != null) setState(() => dueDate = picked);
                          },
                          child: const Text('اختيار تاريخ'),
                        ),
                      ],
                    ),
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
      },
    );

    if (confirmed != true || titleController.text.trim().isEmpty) return;
    if (!context.mounted) return;

    await cubit.createMilestone(
      projectId: widget.args.projectId,
      title: titleController.text,
      dueDate: dueDate,
    );
  }

  Future<void> _openUpdateMilestoneDialog(
    BuildContext context,
    ProjectMilestone milestone,
  ) async {
    final ProjectsCubit cubit = context.read<ProjectsCubit>();
    MilestoneStatus status = milestone.status;
    double progress = milestone.progressPercent.toDouble();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(milestone.title),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AvahiDropdown<MilestoneStatus>(
                      value: status,
                      label: 'الحالة',
                      items: <AvahiDropdownItem<MilestoneStatus>>[
                        for (final MilestoneStatus s in MilestoneStatus.values)
                          AvahiDropdownItem<MilestoneStatus>(
                            value: s,
                            label: s.displayLabel,
                          ),
                      ],
                      onChanged: (MilestoneStatus? s) {
                        if (s == null) return;
                        setState(() {
                          status = s;
                          if (s == MilestoneStatus.completed) progress = 100;
                        });
                      },
                    ),
                    const SizedBox(height: AvahiSpacing.md),
                    Text('نسبة الإنجاز: ${progress.round()}%'),
                    Slider(
                      value: progress,
                      max: 100,
                      divisions: 20,
                      onChanged: status == MilestoneStatus.completed
                          ? null
                          : (double v) => setState(() => progress = v),
                    ),
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
                  label: 'حفظ',
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    await cubit.updateMilestoneProgress(
      milestone: milestone,
      status: status,
      progressPercent: progress.round(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProjectMilestone milestone) {
    final ProjectsCubit cubit = context.read<ProjectsCubit>();
    return AvahiDialog.show(
      context,
      title: 'حذف المرحلة',
      message: 'هل تريد حذف مرحلة "${milestone.title}" نهائياً؟',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
      isDestructive: true,
      onConfirm: () {
        Navigator.of(context).pop();
        cubit.deleteMilestone(milestone.id);
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
              title: Text('المراحل الرئيسية — ${data?.selectedProject?.name ?? ''}'),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.md),
                  child: AvahiButton(
                    label: 'مرحلة جديدة',
                    icon: Icons.add,
                    onPressed: () => _openCreateMilestoneDialog(context),
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
                if (d.isMilestonesLoading) {
                  return const LoadingIndicator(label: 'جارٍ تحميل المراحل...');
                }
                if (d.milestones.isEmpty) {
                  return const EmptyState(
                    title: 'لا توجد مراحل بعد',
                    message: 'أضف أول مرحلة رئيسية لهذا المشروع عبر زر "مرحلة جديدة" أعلاه.',
                    icon: Icons.flag_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AvahiSpacing.lg),
                  itemCount: d.milestones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AvahiSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    final ProjectMilestone m = d.milestones[index];
                    return _MilestoneRow(
                      milestone: m,
                      onEdit: () => _openUpdateMilestoneDialog(context, m),
                      onDelete: () => _confirmDelete(context, m),
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

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone, required this.onEdit, required this.onDelete});

  final ProjectMilestone milestone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AvahiRadius.radiusMd,
        border: Border.all(
          color: milestone.isOverdue ? colors.danger : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  milestone.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (milestone.description != null)
                  Text(
                    milestone.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (milestone.dueDate != null)
                  Text(
                    'الاستحقاق: ${milestone.dueDate!.year}/${milestone.dueDate!.month.toString().padLeft(2, '0')}/${milestone.dueDate!.day.toString().padLeft(2, '0')}'
                    '${milestone.isOverdue ? ' (متأخرة)' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: milestone.isOverdue ? colors.danger : colors.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ProjectProgressBar(progress: milestone.progressPercent / 100),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تحديث الحالة',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'حذف',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
