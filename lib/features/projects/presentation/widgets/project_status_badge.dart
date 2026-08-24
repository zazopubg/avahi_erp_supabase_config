import 'package:flutter/material.dart';

import '../../../../domain/enums/project_status.dart';
import '../../../../ui/widgets/common/status_badge.dart';

/// تسمية عربية موحّدة لعرض [ProjectStatus] — تُستخدم في [ProjectStatusBadge]
/// أدناه، وأيضاً في قوائم التصفية المنسدلة (`my_projects_screen.dart`/
/// `projects_list.dart`) دون تكرار نفس المنطق مرتين.
extension ProjectStatusLabelX on ProjectStatus {
  String get displayLabel {
    switch (this) {
      case ProjectStatus.active:
        return 'نشط';
      case ProjectStatus.onHold:
        return 'متوقف مؤقتاً';
      case ProjectStatus.completed:
        return 'مكتمل';
      case ProjectStatus.archived:
        return 'مؤرشف';
    }
  }
}

/// شارة حالة مشروع — غلاف رفيع فوق [StatusBadge] العام يحدد اللون/
/// النص المناسبين لكل [ProjectStatus]، بنفس نمط `PunchStatusBadge`
/// (`features/punch_list/`).
class ProjectStatusBadge extends StatelessWidget {
  const ProjectStatusBadge({required this.status, super.key, this.dense = false});

  final ProjectStatus status;
  final bool dense;

  AvahiStatus get _avahiStatus {
    switch (status) {
      case ProjectStatus.active:
        return AvahiStatus.success;
      case ProjectStatus.onHold:
        return AvahiStatus.warning;
      case ProjectStatus.completed:
        return AvahiStatus.info;
      case ProjectStatus.archived:
        return AvahiStatus.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: status.displayLabel, status: _avahiStatus, dense: dense);
  }
}
