import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/field_report.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_shadows.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import 'report_status_badge.dart';
import 'weather_selector.dart';

/// بطاقة عرض ملخّصة لتقرير ميداني واحد — تُستخدم في كل قوائم الميزة:
/// `my_reports_screen.dart`، `report_drafts_screen.dart`،
/// `reports_inbox.dart`، و`reports_archive.dart` (سطر واحد لكل تقرير).
class ReportCard extends StatelessWidget {
  const ReportCard({
    required this.report,
    super.key,
    this.onTap,
    this.trailing,
    this.subtitleOverride,
  });

  final FieldReport report;
  final VoidCallback? onTap;

  /// عنصر إضافي اختياري في نهاية البطاقة (مثال: زر مراجعة سريعة في
  /// `reports_inbox.dart`) — إن تُرك `null` تُعرض [ReportStatusBadge] فقط.
  final Widget? trailing;

  /// نص فرعي بديل (مثال: اسم منشئ التقرير في `reports_inbox.dart`
  /// الإداري) — افتراضياً يُعرض ملخّص "العمل المُنجز".
  final String? subtitleOverride;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String workSummary = (report.workPerformed == null || report.workPerformed!.trim().isEmpty)
        ? 'بلا وصف عمل بعد'
        : report.workPerformed!;

    return Material(
      color: colors.surface,
      borderRadius: AvahiRadius.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AvahiRadius.radiusMd,
        child: Container(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AvahiRadius.radiusMd,
            boxShadow: AvahiShadows.sm(AvahiColors.of(Theme.of(context).brightness)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _WeatherGlyph(report: report, colors: colors),
              const SizedBox(width: AvahiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          DateFormatter.shortDate(report.reportDate),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: AvahiSpacing.xs),
                        ReportStatusBadge(status: report.status, dense: true),
                      ],
                    ),
                    const SizedBox(height: AvahiSpacing.xxs),
                    Text(
                      subtitleOverride ?? workSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AvahiSpacing.xxs),
                    Row(
                      children: <Widget>[
                        Icon(Icons.people_outline, size: 14, color: colors.onSurfaceVariant),
                        const SizedBox(width: AvahiSpacing.xxs),
                        Text(
                          '${report.laborCount} عامل',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AvahiSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherGlyph extends StatelessWidget {
  const _WeatherGlyph({required this.report, required this.colors});

  final FieldReport report;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    if (report.weatherCondition == null) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: colors.surfaceContainerHighest,
        child: Icon(Icons.help_outline, size: 18, color: colors.onSurfaceVariant),
      );
    }

    final (IconData icon, String label) = weatherConditionDisplay(report.weatherCondition!);
    return Tooltip(
      message: report.temperatureC == null
          ? label
          : '$label، ${report.temperatureC!.toStringAsFixed(0)}°م',
      child: CircleAvatar(
        radius: 18,
        backgroundColor: colors.primaryContainer,
        child: Icon(icon, size: 18, color: colors.onPrimaryContainer),
      ),
    );
  }
}
