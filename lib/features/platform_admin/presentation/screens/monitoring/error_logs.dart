import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../domain/entities/company.dart';
import '../../../../../domain/entities/error_log_entry.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/status_badge.dart';
import '../../state/platform_admin_cubit.dart';
import '../../state/platform_admin_state.dart';

/// لسان "الأخطاء" ضمن `admin_dashboard.dart` — أحدث سجلات الأخطاء
/// التشغيلية عبر [ErrorLogEntry] (بيانات تجريبية بالكامل — مُقرَّة
/// صراحة ضمن سياق Prompt 28؛ انظر توثيق القرار الكامل في
/// `ErrorLogEntry`). 🆕 (Prompt 28)
class ErrorLogsScreen extends StatelessWidget {
  const ErrorLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
      builder: (BuildContext context, PlatformAdminState state) {
        final PlatformAdminData? data = state.dataOrNull;
        if (data == null) return const SizedBox.shrink();

        if (data.errorLogs.isEmpty) {
          return const EmptyState(
            title: 'لا توجد سجلات أخطاء حديثة',
            icon: Icons.check_circle_outline,
          );
        }

        final Map<String, Company> companiesById = <String, Company>{
          for (final Company c in data.companies) c.id: c,
        };

        return ListView.separated(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          itemCount: data.errorLogs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AvahiSpacing.xs),
          itemBuilder: (BuildContext context, int index) {
            final ErrorLogEntry entry = data.errorLogs[index];
            final Company? company =
                entry.companyId == null ? null : companiesById[entry.companyId];

            return Container(
              padding: const EdgeInsets.all(AvahiSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _severityBadge(entry.severity),
                      const SizedBox(width: AvahiSpacing.sm),
                      Expanded(
                        child: Text(
                          entry.source,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (entry.isResolved)
                        const StatusBadge(
                          label: 'مُعالَج',
                          status: AvahiStatus.success,
                          dense: true,
                        ),
                      const SizedBox(width: AvahiSpacing.sm),
                      Text(
                        DateFormatter.relative(entry.occurredAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AvahiSpacing.xs),
                  Text(entry.message),
                  if (company != null) ...<Widget>[
                    const SizedBox(height: AvahiSpacing.xxs),
                    Text(
                      company.nameAr?.isNotEmpty == true
                          ? company.nameAr!
                          : company.name,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _severityBadge(ErrorLogSeverity severity) {
    return switch (severity) {
      ErrorLogSeverity.info => const StatusBadge(
          label: 'معلومة',
          status: AvahiStatus.info,
          dense: true,
        ),
      ErrorLogSeverity.warning => const StatusBadge(
          label: 'تحذير',
          status: AvahiStatus.warning,
          dense: true,
        ),
      ErrorLogSeverity.error => const StatusBadge(
          label: 'خطأ',
          status: AvahiStatus.danger,
          dense: true,
        ),
      ErrorLogSeverity.critical => const StatusBadge(
          label: 'حرج',
          status: AvahiStatus.danger,
          dense: true,
        ),
    };
  }
}
