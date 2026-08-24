import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/field_report.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/reports_inbox_cubit.dart';
import '../../state/reports_inbox_state.dart';
import '../../widgets/report_status_badge.dart';

/// تصدير تقارير المشروع ضمن مدى تاريخي مختار — يعرض معاينة جدولية عبر
/// [DataGridRtl] لكل [ReportsInboxData.reportsInExportRange]، ثم يبني
/// نص CSV (UTF-8 مع BOM؛ متوافق مع فتح مباشر في Excel) وينسخه لحافظة
/// النظام عبر [Clipboard.setData] — لا اعتماد على `PrintService`/
/// `ShareService` (غير مُستهلكتين بعد من هذه الميزة، انظر التوثيق في
/// `core/di/core_module.dart`)؛ التصدير الفعلي كملف PDF/تنزيل مباشر
/// مؤجَّل لـ `features/documents/` (Prompt 21).
class ReportExportScreen extends StatefulWidget {
  const ReportExportScreen({super.key});

  @override
  State<ReportExportScreen> createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends State<ReportExportScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsInboxCubit, ReportsInboxState>(
      builder: (BuildContext context, ReportsInboxState state) {
        final ReportsInboxData? data = state.dataOrNull;
        if (data == null) return const Center(child: CircularProgressIndicator());

        final List<FieldReport> rangeReports = data.reportsInExportRange;

        return Padding(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _DateRangeField(
                      label: 'من تاريخ',
                      date: data.exportFrom,
                      onPick: (DateTime picked) => context
                          .read<ReportsInboxCubit>()
                          .setExportRange(from: picked, to: data.exportTo),
                    ),
                  ),
                  const SizedBox(width: AvahiSpacing.md),
                  Expanded(
                    child: _DateRangeField(
                      label: 'إلى تاريخ',
                      date: data.exportTo,
                      onPick: (DateTime picked) => context
                          .read<ReportsInboxCubit>()
                          .setExportRange(from: data.exportFrom, to: picked),
                    ),
                  ),
                  const SizedBox(width: AvahiSpacing.md),
                  if (data.exportFrom != null || data.exportTo != null)
                    TextButton.icon(
                      onPressed: () =>
                          context.read<ReportsInboxCubit>().setExportRange(),
                      icon: const Icon(Icons.clear),
                      label: const Text('إزالة المدى'),
                    ),
                ],
              ),
              const SizedBox(height: AvahiSpacing.md),
              Expanded(
                child: rangeReports.isEmpty
                    ? const EmptyState(
                        icon: Icons.file_download_outlined,
                        title: 'لا توجد تقارير ضمن هذا المدى',
                        message: 'وسّع المدى التاريخي أو أزله لعرض كل تقارير المشروع.',
                      )
                    : DataGridRtl<FieldReport>(
                        rowKeyOf: (FieldReport r) => r.id,
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
                            label: 'الحالة',
                            cellBuilder: (_, FieldReport r) =>
                                ReportStatusBadge(status: r.status, dense: true),
                          ),
                        ],
                        rows: rangeReports,
                      ),
              ),
              const SizedBox(height: AvahiSpacing.md),
              AvahiButton(
                label: 'نسخ ${rangeReports.length} تقرير كـ CSV',
                icon: Icons.copy_all_outlined,
                isFullWidth: true,
                onPressed: rangeReports.isEmpty
                    ? null
                    : () => _copyAsCsv(context, rangeReports),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyAsCsv(BuildContext context, List<FieldReport> reports) async {
    final StringBuffer buffer = StringBuffer()
      ..writeln('التاريخ,العمل المُنجز,عدد العمّال,الطقس,الحرارة,الحالة');

    for (final FieldReport r in reports) {
      buffer.writeln(
        <String>[
          DateFormatter.shortDate(r.reportDate),
          _csvEscape(r.workPerformed ?? ''),
          '${r.laborCount}',
          r.weatherCondition?.name ?? '',
          r.temperatureC?.toStringAsFixed(1) ?? '',
          r.status.dbValue,
        ].join(','),
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      context.showSnackBar('تم نسخ ${reports.length} تقرير بصيغة CSV إلى الحافظة.');
    }
  }

  String _csvEscape(String value) {
    final bool needsQuoting = value.contains(',') || value.contains('"') || value.contains('\n');
    final String escaped = value.replaceAll('"', '""');
    return needsQuoting ? '"$escaped"' : escaped;
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({required this.label, required this.date, required this.onPick});

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(date == null ? 'غير محدد' : DateFormatter.shortDate(date!)),
      ),
    );
  }
}
