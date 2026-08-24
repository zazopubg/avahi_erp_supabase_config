import 'package:flutter/material.dart';

import '../../../../domain/enums/task_status.dart';
import '../../../../ui/widgets/common/status_badge.dart';

/// شارة حالة مهمة — غلاف رفيع فوق [StatusBadge] العام يترجم
/// [TaskStatus] إلى تسمية عربية ولون دلالي ثابت، بنفس نمط
/// `AttendanceStatusBadge` (`features/attendance/presentation/widgets/`).
class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({required this.status, super.key, this.dense = false});

  final TaskStatus status;
  final bool dense;

  static (AvahiStatus, String, IconData) _visualsFor(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => (
          AvahiStatus.neutral,
          'قائمة الانتظار',
          Icons.inbox_outlined,
        ),
      TaskStatus.inProgress => (
          AvahiStatus.info,
          'قيد التنفيذ',
          Icons.autorenew,
        ),
      TaskStatus.review => (
          AvahiStatus.warning,
          'قيد المراجعة',
          Icons.rate_review_outlined,
        ),
      TaskStatus.done => (
          AvahiStatus.success,
          'مكتملة',
          Icons.check_circle,
        ),
      TaskStatus.blocked => (
          AvahiStatus.danger,
          'معلّقة',
          Icons.block,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (AvahiStatus visual, String label, IconData icon) = _visualsFor(
      status,
    );
    return StatusBadge(label: label, status: visual, icon: icon, dense: dense);
  }
}
