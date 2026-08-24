import 'package:flutter/material.dart';

import '../../../../domain/enums/leave_status.dart';
import '../../../../ui/widgets/common/status_badge.dart';

/// شارة حالة طلب إجازة — تُترجم [LeaveStatus] إلى [AvahiStatus]/تسمية
/// عربية جاهزة، بنفس نمط `report_status_badge.dart`
/// (`features/field_reports/`, Prompt 17) و`punch_status_badge.dart`
/// (`features/punch_list/`, Prompt 19) تماماً. 🆕
class LeaveStatusBadge extends StatelessWidget {
  const LeaveStatusBadge({required this.status, super.key, this.dense = false});

  final LeaveStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (AvahiStatus avahiStatus, String label, IconData icon) = switch (status) {
      LeaveStatus.pending => (AvahiStatus.warning, 'بانتظار الاعتماد', Icons.hourglass_top),
      LeaveStatus.approved => (AvahiStatus.success, 'مقبولة', Icons.check_circle_outline),
      LeaveStatus.rejected => (AvahiStatus.danger, 'مرفوضة', Icons.cancel_outlined),
      LeaveStatus.cancelled => (AvahiStatus.neutral, 'ملغاة', Icons.block_outlined),
    };

    return StatusBadge(label: label, status: avahiStatus, icon: icon, dense: dense);
  }
}
