import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// شريط تقدّم موحّد لعرض نسبة إنجاز مشروع أو مرحلة رئيسية (0.0-1.0)،
/// مع تسمية نسبة مئوية اختيارية أعلاه — `project_overview.dart`
/// (نسبة إنجاز المشروع الإجمالية)، `project_milestones.dart` (نسبة كل
/// مرحلة على حدة).
///
/// مكوّن عرض بحت — لا يحسب النسبة بنفسه؛ المستدعي يمرّر [progress]
/// جاهزة (مثال: `dashboard['openTasksCount']` مقارنة بإجمالي المهام، أو
/// [ProjectMilestone.progressPercent] / 100).
class ProjectProgressBar extends StatelessWidget {
  const ProjectProgressBar({
    required this.progress,
    super.key,
    this.label,
    this.showPercentLabel = true,
    this.height = 8,
  });

  /// نسبة الإنجاز بين 0.0 و1.0 — تُقيَّد تلقائياً ضمن هذا المجال.
  final double progress;

  /// تسمية نصية اختيارية تُعرض قبل النسبة المئوية (مثال: "نسبة الإنجاز").
  final String? label;
  final bool showPercentLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final double clamped = progress.clamp(0.0, 1.0);
    final int percent = (clamped * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null || showPercentLabel) ...<Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (label != null)
                Text(label!, style: Theme.of(context).textTheme.labelMedium),
              if (showPercentLabel)
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.brand,
                      ),
                ),
            ],
          ),
          const SizedBox(height: AvahiSpacing.xxs),
        ],
        ClipRRect(
          borderRadius: AvahiRadius.radiusFull,
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: height,
            backgroundColor: colors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              clamped >= 1.0 ? colors.success : colors.brand,
            ),
          ),
        ),
      ],
    );
  }
}
