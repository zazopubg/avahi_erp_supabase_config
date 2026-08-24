import 'package:flutter/material.dart';

import '../../../../domain/enums/attendance_type.dart';
import '../../../../ui/widgets/common/status_badge.dart';

/// شارة حالة اعتماد سجل الحضور — غلاف رفيع فوق [StatusBadge] العام
/// يترجم [AttendanceType] إلى تسمية عربية ولون دلالي ثابت، بنفس نمط
/// أي "شارة حالة مختصة بميزة" أخرى في المشروع (تُبقي [StatusBadge]
/// نفسه عاماً بلا أي معرفة بميزة الحضور تحديداً).
class AttendanceStatusBadge extends StatelessWidget {
  const AttendanceStatusBadge({required this.status, super.key, this.dense = false});

  final AttendanceType status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (AvahiStatus visual, String label, IconData icon) = switch (status) {
      AttendanceType.pending => (
          AvahiStatus.warning,
          'بانتظار الاعتماد',
          Icons.hourglass_top,
        ),
      AttendanceType.approved => (
          AvahiStatus.success,
          'مُعتمد',
          Icons.check_circle,
        ),
      AttendanceType.rejected => (
          AvahiStatus.danger,
          'مرفوض',
          Icons.cancel,
        ),
    };

    return StatusBadge(label: label, status: visual, icon: icon, dense: dense);
  }
}
