import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/entities/attendance_record.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../widgets/attendance_status_badge.dart';
import '../../widgets/hours_calculator.dart';

/// جدول سجلات حضور تفصيلي — يُستخدم ضمن `attendance_report.dart`
/// (وقابل لإعادة الاستخدام لاحقاً ضمن `attendance_monitor.dart` كعرض
/// بديل للقائمة). غلاف رفيع فوق [DataGridRtl] العام
/// (`ui/widgets/desktop/`) يعرّف أعمدة الحضور الستة تحديداً.
///
/// مكوّن عرض بحت — لا يحمل أي منطق جلب بيانات.
class AttendanceTable extends StatelessWidget {
  const AttendanceTable({required this.records, super.key});

  final List<AttendanceRecord> records;

  static final DateFormat _dateFormat = DateFormat.MMMEd('ar');
  static final DateFormat _timeFormat = DateFormat.Hm('ar');

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return DataGridRtl<AttendanceRecord>(
      rows: records,
      rowKeyOf: (AttendanceRecord r) => r.id,
      emptyTitle: 'لا توجد سجلات حضور ضمن هذا المدى',
      columns: <DataGridColumn<AttendanceRecord>>[
        DataGridColumn<AttendanceRecord>(
          label: 'التاريخ',
          flex: 2,
          cellBuilder: (BuildContext context, AttendanceRecord r) =>
              Text(_dateFormat.format(r.checkInAt)),
        ),
        DataGridColumn<AttendanceRecord>(
          label: 'الحضور',
          cellBuilder: (BuildContext context, AttendanceRecord r) =>
              Text(_timeFormat.format(r.checkInAt)),
        ),
        DataGridColumn<AttendanceRecord>(
          label: 'الانصراف',
          cellBuilder: (BuildContext context, AttendanceRecord r) => Text(
            r.checkOutAt != null ? _timeFormat.format(r.checkOutAt!) : '—',
          ),
        ),
        DataGridColumn<AttendanceRecord>(
          label: 'ساعات العمل',
          cellBuilder: (BuildContext context, AttendanceRecord r) =>
              HoursCalculator(record: r, dense: true),
        ),
        DataGridColumn<AttendanceRecord>(
          label: 'الموقع',
          cellBuilder: (BuildContext context, AttendanceRecord r) => Icon(
            r.geofenceValid ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 18,
            color: r.geofenceValid ? colors.success : colors.danger,
          ),
        ),
        DataGridColumn<AttendanceRecord>(
          label: 'الحالة',
          flex: 2,
          cellBuilder: (BuildContext context, AttendanceRecord r) =>
              AttendanceStatusBadge(status: r.status, dense: true),
        ),
      ],
    );
  }
}
