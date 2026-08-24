import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../domain/entities/field_report.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/reports_inbox_cubit.dart';
import '../../state/reports_inbox_state.dart';
import '../../widgets/report_status_badge.dart';
import 'report_review_screen.dart';

/// أرشيف التقارير — كل التقارير التي انتهت دورة مراجعتها
/// (`ReportStatus.reviewed`/`ReportStatus.rejected`)، بتصفية محلية
/// مستقلة عن `reports_inbox.dart` (لا تشارك [ReportsInboxData.statusFilter]
/// كي لا يتعارض التبويبان عند التنقّل بينهما ضمن نفس
/// `field_reports_desktop_home.dart`). نفس تخطيط `reports_inbox.dart`
/// ثنائي الأعمدة (جدول + [ReportReviewScreen] جانبية للاطلاع فقط، بلا
/// أزرار اعتماد/رفض لأن الحالة نهائية).
class ReportsArchive extends StatefulWidget {
  const ReportsArchive({super.key});

  @override
  State<ReportsArchive> createState() => _ReportsArchiveState();
}

enum _ArchiveFilter { all, reviewed, rejected }

class _ReportsArchiveState extends State<ReportsArchive> {
  _ArchiveFilter _filter = _ArchiveFilter.all;
  String? _selectedReportId;

  bool _matches(FieldReport report) {
    if (!report.status.isReviewed && !report.status.isRejected) return false;
    return switch (_filter) {
      _ArchiveFilter.all => true,
      _ArchiveFilter.reviewed => report.status.isReviewed,
      _ArchiveFilter.rejected => report.status.isRejected,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsInboxCubit, ReportsInboxState>(
      builder: (BuildContext context, ReportsInboxState state) {
        final ReportsInboxData? data = state.dataOrNull;
        if (data == null) return const Center(child: CircularProgressIndicator());

        final List<FieldReport> archived = data.reports.where(_matches).toList(growable: false)
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
                    SegmentedButton<_ArchiveFilter>(
                      segments: const <ButtonSegment<_ArchiveFilter>>[
                        ButtonSegment<_ArchiveFilter>(
                          value: _ArchiveFilter.all,
                          label: Text('الكل'),
                        ),
                        ButtonSegment<_ArchiveFilter>(
                          value: _ArchiveFilter.reviewed,
                          label: Text('معتمد'),
                          icon: Icon(Icons.check_circle_outline),
                        ),
                        ButtonSegment<_ArchiveFilter>(
                          value: _ArchiveFilter.rejected,
                          label: Text('مرفوض'),
                          icon: Icon(Icons.cancel_outlined),
                        ),
                      ],
                      selected: <_ArchiveFilter>{_filter},
                      onSelectionChanged: (Set<_ArchiveFilter> selection) =>
                          setState(() => _filter = selection.first),
                    ),
                    const SizedBox(height: AvahiSpacing.md),
                    Expanded(
                      child: DataGridRtl<FieldReport>(
                        rowKeyOf: (FieldReport r) => r.id,
                        onRowTap: (FieldReport r) =>
                            setState(() => _selectedReportId = r.id),
                        emptyTitle: 'لا توجد تقارير مؤرشَفة مطابقة',
                        emptyIcon: Icons.archive_outlined,
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
                            label: 'الحالة',
                            cellBuilder: (_, FieldReport r) =>
                                ReportStatusBadge(status: r.status, dense: true),
                          ),
                          DataGridColumn<FieldReport>(
                            label: 'آخر تحديث',
                            cellBuilder: (_, FieldReport r) =>
                                Text(DateFormatter.shortDate(r.updatedAt)),
                          ),
                        ],
                        rows: archived,
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
