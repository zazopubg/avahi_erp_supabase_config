import 'package:flutter/material.dart';

import '../../../../domain/entities/project.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import 'project_status_badge.dart';

/// بطاقة مشروع مختصرة — الاسم، الرمز/العميل، شارة الحالة، ونطاق
/// التواريخ إن توفّرت. تُستخدم في `my_projects_screen.dart` (قائمة
/// شبكية/عمودية على الهاتف) و`projects_list.dart` (كصف ضمن
/// `DataGridRtl` على سطح المكتب اختيارياً)، بنفس نمط `PunchItemCard`.
class ProjectCard extends StatelessWidget {
  const ProjectCard({required this.project, super.key, this.onTap});

  final Project project;
  final VoidCallback? onTap;

  String _formatRange(BuildContext context) {
    final DateTime? start = project.startDate;
    final DateTime? end = project.endDate;
    if (start == null && end == null) return '';
    String fmt(DateTime d) =>
        '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    if (start != null && end != null) return '${fmt(start)} → ${fmt(end)}';
    if (start != null) return 'بدأ: ${fmt(start)}';
    return 'حتى: ${fmt(end!)}';
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String dateRange = _formatRange(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AvahiRadius.radiusMd,
      child: Container(
        padding: const EdgeInsets.all(AvahiSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AvahiRadius.radiusMd,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        project.name,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (project.code != null || project.clientName != null) ...<Widget>[
                        const SizedBox(height: AvahiSpacing.xxs),
                        Text(
                          <String>[
                            if (project.code != null) project.code!,
                            if (project.clientName != null) project.clientName!,
                          ].join(' • '),
                          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AvahiSpacing.sm),
                ProjectStatusBadge(status: project.status, dense: true),
              ],
            ),
            if (project.address != null) ...<Widget>[
              const SizedBox(height: AvahiSpacing.sm),
              Row(
                children: <Widget>[
                  Icon(Icons.place_outlined, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: AvahiSpacing.xxs),
                  Expanded(
                    child: Text(
                      project.address!,
                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (dateRange.isNotEmpty) ...<Widget>[
              const SizedBox(height: AvahiSpacing.xs),
              Row(
                children: <Widget>[
                  Icon(Icons.event_outlined, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: AvahiSpacing.xxs),
                  Text(
                    dateRange,
                    style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
