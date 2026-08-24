import 'package:flutter/material.dart';

import '../../../../ui/widgets/common/avahi_dropdown.dart';
import '../state/tasks_state.dart';

/// مكوّن اختيار شخص لإسناد مهمة إليه — غلاف رفيع فوق [AvahiDropdown]
/// يستقبل [candidates] جاهزة (`TasksData.assignableUsers`، انظر
/// توثيق [TaskAssignee] لسبب اعتمادها معرّفات مختصرة بدل أسماء كاملة
/// حالياً) ويعرضها كقائمة منسدلة، مع خيار "بلا إسناد" ثابت أولاً.
///
/// مكوّن عرض بحت — لا يجلب أي بيانات بنفسه؛ يُستخدم من
/// `task_assign_dialog.dart` (سطح المكتب/الهاتف معاً) و`task_filter_bar.dart`
/// (كمرشِّح حسب المُسنَد إليه).
class AssigneeSelector extends StatelessWidget {
  const AssigneeSelector({
    required this.candidates,
    super.key,
    this.selectedUserId,
    this.label = 'المُسنَد إليه',
    this.unassignedLabel = 'بلا إسناد',
    this.onChanged,
    this.enabled = true,
  });

  final List<TaskAssignee> candidates;
  final String? selectedUserId;
  final String label;
  final String unassignedLabel;
  final bool enabled;

  /// يُستدعى بمعرّف المستخدم المُختار، أو `null` عند اختيار
  /// [unassignedLabel].
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AvahiDropdown<String?>(
      label: label,
      value: selectedUserId,
      enabled: enabled,
      onChanged: onChanged,
      items: <AvahiDropdownItem<String?>>[
        AvahiDropdownItem<String?>(
          value: null,
          label: unassignedLabel,
          icon: Icons.person_off_outlined,
        ),
        for (final TaskAssignee assignee in candidates)
          AvahiDropdownItem<String?>(
            value: assignee.userId,
            label: assignee.displayLabel,
            icon: Icons.person_outline,
          ),
      ],
    );
  }
}
