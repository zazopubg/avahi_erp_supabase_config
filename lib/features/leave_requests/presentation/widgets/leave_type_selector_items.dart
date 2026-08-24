import '../../../../domain/enums/leave_type.dart';
import '../../../../ui/widgets/common/avahi_dropdown.dart';

/// تسمية عربية لنوع الإجازة [LeaveType] — تستخدمها
/// `create_leave_request_screen.dart` (قائمة الاختيار) و
/// `leave_request_card.dart`/`leave_request_review.dart` (العرض)
/// معاً، بنفس نمط `punchPriorityLabelAr`
/// (`task_priority_selector_items.dart`، `features/punch_list/`). 🆕
String leaveTypeLabelAr(LeaveType type) => switch (type) {
      LeaveType.annual => 'إجازة سنوية',
      LeaveType.sick => 'إجازة مرضية',
      LeaveType.emergency => 'إجازة طارئة',
      LeaveType.unpaid => 'إجازة بدون راتب',
      LeaveType.other => 'أخرى',
    };

final List<AvahiDropdownItem<LeaveType>> kLeaveTypeDropdownItems = LeaveType
    .values
    .map(
      (LeaveType t) => AvahiDropdownItem<LeaveType>(
        value: t,
        label: leaveTypeLabelAr(t),
      ),
    )
    .toList(growable: false);
