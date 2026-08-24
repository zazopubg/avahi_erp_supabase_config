import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/project_member_detail.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import '../state/equipment_cubit.dart';
import '../state/equipment_state.dart';

/// نافذة منبثقة لإسناد [equipment] إلى مشروع/مستخدم — الخطوة الأولى
/// اختيار مشروع من [myProjects] (أو "بلا مشروع" لإلغاء الإسناد
/// الكامل)، ثم يُحمَّل فريق عمل ذلك المشروع كسولاً عبر
/// [EquipmentCubit.loadProjectMembersForAssign] لاختيار مستخدم محدد
/// ضمنه — `equipment_registry.dart`/`equipment_details.dart`.
///
/// ⚠️ قرار تصميم: لا يوجد استعلام "كل أعضاء الشركة" مستقل عن مشروع
/// معيّن ضمن طبقة `domain/` الحالية (`GetProjectMembersUsecase` وحدها
/// المتاحة، تحتاج `projectId`) — لذا اختيار المستخدم هنا يعتمد أولاً
/// على اختيار مشروع، بنفس القيد الموثَّق في `EquipmentData.projectMembers`.
/// إسناد معدة لمشروع بلا مستخدم محدد (`assignedTo: null`) يبقى ممكناً
/// دوماً (المعدة "متاحة ضمن موقع المشروع" بلا شخص مسؤول بعينه).
class AssignEquipmentDialog extends StatefulWidget {
  const AssignEquipmentDialog({
    required this.cubit,
    required this.equipment,
    required this.myProjects,
    super.key,
  });

  final EquipmentCubit cubit;
  final Equipment equipment;
  final List<Project> myProjects;

  @override
  State<AssignEquipmentDialog> createState() => _AssignEquipmentDialogState();
}

class _AssignEquipmentDialogState extends State<AssignEquipmentDialog> {
  String? _projectId;
  String? _assignedTo;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _projectId = widget.equipment.projectId;
    _assignedTo = widget.equipment.assignedTo;
    if (_projectId != null) {
      widget.cubit.loadProjectMembersForAssign(_projectId!);
    }
  }

  @override
  void dispose() {
    widget.cubit.clearProjectMembers();
    super.dispose();
  }

  void _onProjectChanged(String? projectId) {
    setState(() {
      _projectId = projectId;
      _assignedTo = null;
    });
    widget.cubit.clearProjectMembers();
    if (projectId != null) {
      widget.cubit.loadProjectMembersForAssign(projectId);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final bool success = await widget.cubit.assignEquipment(
      equipment: widget.equipment,
      assignedTo: _assignedTo,
      projectId: _projectId,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر إسناد المعدة، حاول مجدداً.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إسناد "${widget.equipment.name}"'),
      content: SizedBox(
        width: 420,
        child: BlocBuilder<EquipmentCubit, EquipmentState>(
          bloc: widget.cubit,
          builder: (BuildContext context, EquipmentState state) {
            final EquipmentData? data = state.dataOrNull;
            final List<ProjectMemberDetail> members =
                data?.projectMembers ?? const <ProjectMemberDetail>[];
            final bool isLoading = data?.isMembersLoading ?? false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AvahiDropdown<String?>(
                  label: 'المشروع (اختياري — فارغ = إلغاء الإسناد الكامل)',
                  value: _projectId,
                  items: <AvahiDropdownItem<String?>>[
                    const AvahiDropdownItem<String?>(
                      value: null,
                      label: 'بلا مشروع (إلغاء الإسناد)',
                    ),
                    for (final Project project in widget.myProjects)
                      AvahiDropdownItem<String?>(
                        value: project.id,
                        label: project.name,
                      ),
                  ],
                  onChanged: _onProjectChanged,
                ),
                const SizedBox(height: AvahiSpacing.sm),
                if (_projectId == null)
                  const SizedBox.shrink()
                else if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AvahiSpacing.md),
                    child: LoadingIndicator(size: LoadingIndicatorSize.small),
                  )
                else
                  AvahiDropdown<String?>(
                    label: 'المستخدم المسؤول (اختياري)',
                    value: _assignedTo,
                    items: <AvahiDropdownItem<String?>>[
                      const AvahiDropdownItem<String?>(
                        value: null,
                        label: 'بلا مستخدم محدد',
                      ),
                      for (final ProjectMemberDetail member in members)
                        AvahiDropdownItem<String?>(
                          value: member.user.userId,
                          label: member.user.fullName,
                        ),
                    ],
                    onChanged: (String? value) =>
                        setState(() => _assignedTo = value),
                  ),
              ],
            );
          },
        ),
      ),
      actions: <Widget>[
        AvahiButton(
          label: 'إلغاء',
          variant: AvahiButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AvahiButton(
          label: 'حفظ الإسناد',
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
