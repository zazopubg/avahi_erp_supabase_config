import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../domain/entities/audit_log.dart';
import '../../../../../domain/entities/company.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../../ui/widgets/common/status_badge.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/platform_admin_cubit.dart';
import '../../state/platform_admin_state.dart';

/// لسان "سجل التدقيق" ضمن `admin_dashboard.dart` — سجل [AuditLog] عابر
/// لكل الشركات معاً (بخلاف أي سجل تدقيق مستقبلي مقتصر على شركة واحدة)،
/// قابل للفلترة حسب المستأجر/نوع العملية/اسم الجدول. أول استهلاك فعلي
/// لجدول `audit_logs` (موجود منذ Prompt 03، يُملأ تلقائياً عبر DB
/// triggers منذ Prompt 03/017، لكن بلا أي شاشة تعرضه قبل هذه الخطوة).
/// 🆕 (Prompt 28)
class AuditLogsViewerScreen extends StatelessWidget {
  const AuditLogsViewerScreen({super.key});

  static const List<String> _actionOptions = <String>[
    'INSERT',
    'UPDATE',
    'DELETE',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
      builder: (BuildContext context, PlatformAdminState state) {
        final PlatformAdminData? data = state.dataOrNull;
        if (data == null) return const SizedBox.shrink();

        final PlatformAdminCubit cubit = context.read<PlatformAdminCubit>();
        final Map<String, Company> companiesById = <String, Company>{
          for (final Company c in data.companies) c.id: c,
        };

        return Padding(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: AvahiDropdown<String?>(
                      label: 'المستأجر',
                      value: data.auditLogCompanyFilter,
                      items: <AvahiDropdownItem<String?>>[
                        const AvahiDropdownItem<String?>(
                          value: null,
                          label: 'كل المستأجرين',
                        ),
                        for (final Company c in data.companies)
                          AvahiDropdownItem<String?>(
                            value: c.id,
                            label: c.nameAr?.isNotEmpty == true
                                ? c.nameAr!
                                : c.name,
                          ),
                      ],
                      onChanged: (String? id) => cubit.setAuditLogFilters(
                        companyId: id,
                        clearCompanyId: id == null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AvahiSpacing.sm),
                  Expanded(
                    child: AvahiDropdown<String?>(
                      label: 'نوع العملية',
                      value: data.auditLogActionFilter,
                      items: <AvahiDropdownItem<String?>>[
                        const AvahiDropdownItem<String?>(
                          value: null,
                          label: 'كل العمليات',
                        ),
                        for (final String action in _actionOptions)
                          AvahiDropdownItem<String?>(
                            value: action,
                            label: action,
                          ),
                      ],
                      onChanged: (String? action) => cubit.setAuditLogFilters(
                        action: action,
                        clearAction: action == null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AvahiSpacing.sm),
                  Expanded(
                    child: AvahiTextField(
                      label: 'اسم الجدول (اختياري)',
                      hint: 'مثال: projects',
                      onSubmitted: (String value) => cubit.setAuditLogFilters(
                        tableName: value.trim().isEmpty ? null : value.trim(),
                        clearTableName: value.trim().isEmpty,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AvahiSpacing.md),
              Expanded(
                child: data.isLoadingAuditLogs
                    ? const LoadingIndicator()
                    : DataGridRtl<AuditLog>(
                        rows: data.auditLogs,
                        emptyTitle: 'لا توجد سجلات تدقيق مطابقة',
                        emptyIcon: Icons.history_outlined,
                        rowKeyOf: (AuditLog log) => log.id,
                        columns: <DataGridColumn<AuditLog>>[
                          DataGridColumn<AuditLog>(
                            label: 'الوقت',
                            flex: 2,
                            cellBuilder: (BuildContext context, AuditLog log) =>
                                Text(DateFormatter.dateTime(log.createdAt)),
                          ),
                          DataGridColumn<AuditLog>(
                            label: 'المستأجر',
                            flex: 2,
                            cellBuilder: (BuildContext context, AuditLog log) {
                              final Company? company =
                                  log.companyId == null
                                      ? null
                                      : companiesById[log.companyId];
                              return Text(
                                company == null
                                    ? '—'
                                    : (company.nameAr?.isNotEmpty == true
                                        ? company.nameAr!
                                        : company.name),
                              );
                            },
                          ),
                          DataGridColumn<AuditLog>(
                            label: 'العملية',
                            cellBuilder: (BuildContext context, AuditLog log) =>
                                _actionBadge(log.action),
                          ),
                          DataGridColumn<AuditLog>(
                            label: 'الجدول',
                            flex: 2,
                            cellBuilder: (BuildContext context, AuditLog log) =>
                                Text(log.tableName),
                          ),
                          DataGridColumn<AuditLog>(
                            label: 'معرّف السجل',
                            flex: 2,
                            cellBuilder: (BuildContext context, AuditLog log) =>
                                Text(
                              log.recordId ?? '—',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBadge(String action) {
    return switch (action) {
      'INSERT' => const StatusBadge(
          label: 'إضافة',
          status: AvahiStatus.success,
          dense: true,
        ),
      'DELETE' => const StatusBadge(
          label: 'حذف',
          status: AvahiStatus.danger,
          dense: true,
        ),
      _ => const StatusBadge(
          label: 'تعديل',
          status: AvahiStatus.warning,
          dense: true,
        ),
    };
  }
}
