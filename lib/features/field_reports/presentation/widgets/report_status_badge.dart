import 'package:flutter/material.dart';

import '../../../../domain/enums/report_status.dart';
import '../../../../ui/widgets/common/status_badge.dart';

/// شارة حالة تقرير ميداني — تُترجم [ReportStatus] إلى [AvahiStatus]/
/// تسمية عربية جاهزة، بنفس نمط شارات الحالة الأخرى عبر التطبيق
/// (`task_status_badge` الضمني ضمن `task_card.dart`، Prompt 16).
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({required this.status, super.key, this.dense = false});

  final ReportStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (AvahiStatus avahiStatus, String label, IconData icon) = switch (status) {
      ReportStatus.draft => (AvahiStatus.neutral, 'مسوّدة', Icons.edit_note_outlined),
      ReportStatus.submitted => (AvahiStatus.warning, 'بانتظار الاعتماد', Icons.hourglass_top),
      ReportStatus.reviewed => (AvahiStatus.success, 'معتمد', Icons.check_circle_outline),
      ReportStatus.rejected => (AvahiStatus.danger, 'مرفوض', Icons.cancel_outlined),
    };

    return StatusBadge(label: label, status: avahiStatus, icon: icon, dense: dense);
  }
}
