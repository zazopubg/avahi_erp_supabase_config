import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../domain/entities/field_report.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/reports_inbox_cubit.dart';
import '../../state/reports_inbox_state.dart';
import '../../widgets/report_status_badge.dart';
import '../../widgets/weather_selector.dart';
import 'report_review_screen.dart';

/// عرض "الوارد" الحي (Realtime) — تقارير [ReportStatus.submitted] فقط
/// بانتظار الاعتماد، مُحدَّثة لحظياً عبر
/// `WatchProjectReportsUsecase` (`ReportsInboxCubit._subscribeToRealtime`).
/// تخطيط ثنائي الأعمدة قياسي لسطح المكتب (بنفس نمط `tasks_list_screen.dart`):
/// [DataGridRtl] + شريط بحث في عمود موسَّع، و[ReportReviewScreen] ثابتة
/// على اليسار تعرض تفاصيل التقرير المُختار.
class ReportsInbox extends StatefulWidget {
  const ReportsInbox({super.key});

  @override
  State<ReportsInbox> createState() => _ReportsInboxState();
}

class _ReportsInboxState extends State<ReportsInbox> {
  String? _selectedReportId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsInboxCubit, ReportsInboxState>(
      builder: (BuildContext context, ReportsInboxState state) {
        final ReportsInboxData? data = state.dataOrNull;
        if (data == null) return const Center(child: CircularProgressIndicator());

        final List<FieldReport> submitted = data.reports
            .where((FieldReport r) => r.status.isSubmitted)
            .where((FieldReport r) {
              final String query = data.searchQuery.trim().toLowerCase();
              if (query.isEmpty) return true;
              return (r.workPerformed?.toLowerCase().contains(query) ?? false) ||
                  (r.notes?.toLowerCase().contains(query) ?? false);
            })
            .toList(growable: false)
          ..sort((FieldReport a, FieldReport b) => b.reportDate.compareTo(a.reportDate));

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AvahiSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AvahiTextField(
                            label: 'بحث ضمن الوارد',
                            hint: 'ابحث في وصف العمل أو الملاحظات',
                            prefixIcon: Icons.search,
                            onChanged: context.read<ReportsInboxCubit>().setSearchQuery,
                          ),
                        ),
                        const SizedBox(width: AvahiSpacing.md),
                        _PendingCountChip(count: submitted.length),
                      ],
                    ),
                    const SizedBox(height: AvahiSpacing.md),
                    Expanded(
                      child: DataGridRtl<FieldReport>(
                        rowKeyOf: (FieldReport r) => r.id,
                        onRowTap: (FieldReport r) =>
                            setState(() => _selectedReportId = r.id),
                        emptyTitle: 'لا توجد تقارير بانتظار الاعتماد',
                        emptyIcon: Icons.inbox_outlined,
                        columns: <DataGridColumn<FieldReport>>[
                          DataGridColumn<FieldReport>(
                            label: 'التاريخ',
                            cellBuilder: (_, FieldReport r) =>
                                Text(DateFormatter.shortDate(r.reportDate)),
                          ),
                          DataGridColumn<FieldReport>(
                            label: 'العمل المُنجز',
                            flex: 3,
                            cellBuilder: (_, FieldReport r) => Text(
                              r.workPerformed ?? '—',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataGridColumn<FieldReport>(
                            label: 'العمّال',
                            cellBuilder: (_, FieldReport r) => Text('${r.laborCount}'),
                          ),
                          DataGridColumn<FieldReport>(
                            label: 'الطقس',
                            cellBuilder: (_, FieldReport r) => Text(
                              r.weatherCondition == null
                                  ? '—'
                                  : weatherConditionDisplay(r.weatherCondition!).$2,
                            ),
                          ),
                          DataGridColumn<FieldReport>(
                            label: 'الحالة',
                            cellBuilder: (_, FieldReport r) =>
                                ReportStatusBadge(status: r.status, dense: true),
                          ),
                        ],
                        rows: submitted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedReportId != null)
              ReportReviewScreen(
                reportId: _selectedReportId!,
                onClose: () => setState(() => _selectedReportId = null),
              ),
          ],
        );
      },
    );
  }
}

class _PendingCountChip extends StatelessWidget {
  const _PendingCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Chip(
      avatar: const Icon(Icons.hourglass_top, size: 16),
      label: Text('$count بانتظار الاعتماد'),
      backgroundColor: colors.tertiaryContainer,
    );
  }
}
