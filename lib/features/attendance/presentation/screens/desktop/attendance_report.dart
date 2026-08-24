import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/entities/attendance_record.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/attendance_cubit.dart';
import '../../state/attendance_state.dart';
import '../../widgets/hours_calculator.dart';
import 'attendance_table.dart';

/// تقرير استخراج الحضور الشهري — سطح المكتب. يتيح اختيار شهر
/// (السابق/التالي)، ويعرض إحصاءات ملخّصة (إجمالي أيام الحضور،
/// متوسط ساعات العمل، عدد السجلات خارج نطاق الموقع) فوق
/// [AttendanceTable] الكامل لسجلات الشهر المُختار.
///
/// "الاستخراج" هنا هو التحميل والعرض المنظّم للبيانات عبر
/// `AttendanceCubit.loadReport`؛ تصدير الملف (CSV/PDF) مؤجَّل لميزة
/// لاحقة (`features/documents/`، Prompt 21) حيث تتوفر خدمة مشاركة
/// ملفات مركزية بدلاً من تكرارها هنا.
class AttendanceReport extends StatefulWidget {
  const AttendanceReport({super.key});

  @override
  State<AttendanceReport> createState() => _AttendanceReportState();
}

class _AttendanceReportState extends State<AttendanceReport> {
  late DateTime _month;

  static final DateFormat _monthFormat = DateFormat.yMMMM('ar');

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _month = DateTime(now.year, now.month);
    final AttendanceCubit cubit = context.read<AttendanceCubit>();
    final AttendanceData? data = cubit.state.dataOrNull;
    if (data != null) cubit.loadReport(projectId: data.project.id, month: _month);
  }

  void _changeMonth(int offset) {
    final DateTime newMonth = DateTime(_month.year, _month.month + offset);
    setState(() => _month = newMonth);
    final AttendanceCubit cubit = context.read<AttendanceCubit>();
    final AttendanceData? data = cubit.state.dataOrNull;
    if (data != null) cubit.loadReport(projectId: data.project.id, month: newMonth);
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (BuildContext context, AttendanceState state) {
        final AttendanceData? data = state.dataOrNull;
        if (data == null) return const LoadingIndicator();

        final List<AttendanceRecord> records = data.reportRecords;
        final int totalDays = records.map((AttendanceRecord r) => DateTime(r.checkInAt.year, r.checkInAt.month, r.checkInAt.day)).toSet().length;
        final List<Duration> workedDurations = records
            .map(AttendanceHoursLogic.workedDuration)
            .whereType<Duration>()
            .toList(growable: false);
        final Duration avgDuration = workedDurations.isEmpty
            ? Duration.zero
            : Duration(
                minutes: workedDurations.map((Duration d) => d.inMinutes).reduce((int a, int b) => a + b) ~/
                    workedDurations.length,
              );
        final int outsideGeofenceCount = records.where((AttendanceRecord r) => !r.geofenceValid).length;

        return Padding(
          padding: const EdgeInsets.all(AvahiSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Expanded(
                    child: Text(
                      _monthFormat.format(_month),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: AvahiSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ReportStat(label: 'إجمالي أيام الحضور', value: '$totalDays'),
                  ),
                  const SizedBox(width: AvahiSpacing.md),
                  Expanded(
                    child: _ReportStat(
                      label: 'متوسط ساعات العمل اليومي',
                      value: AttendanceHoursLogic.format(avgDuration),
                    ),
                  ),
                  const SizedBox(width: AvahiSpacing.md),
                  Expanded(
                    child: _ReportStat(
                      label: 'سجلات خارج نطاق الموقع',
                      value: '$outsideGeofenceCount',
                      color: outsideGeofenceCount > 0 ? colors.danger : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AvahiSpacing.lg),
              Expanded(
                child: data.isReportLoading
                    ? const LoadingIndicator(label: 'جارٍ استخراج التقرير...')
                    : AttendanceTable(records: records),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
