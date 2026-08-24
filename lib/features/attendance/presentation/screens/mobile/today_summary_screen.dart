import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/attendance_cubit.dart';
import '../../state/attendance_state.dart';
import '../../widgets/attendance_status_badge.dart';
import '../../widgets/hours_calculator.dart';

/// شاشة تفاصيل حضور اليوم — تُفتح عبر زر "عرض التفاصيل" في شريط
/// `AppBar` الخاص بـ `check_in_screen.dart`. عرض قراءة فقط (بلا أي
/// إجراء تعديل) لكامل حقول سجل اليوم: أوقات الحضور/الانصراف،
/// الإحداثيات، حالة الجيوفنسينغ، الملاحظات، وحالة الاعتماد.
class TodaySummaryScreen extends StatelessWidget {
  const TodaySummaryScreen({super.key});

  static final DateFormat _timeFormat = DateFormat.Hm('ar');
  static final DateFormat _dateFormat = DateFormat.yMMMMd('ar');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل حضور اليوم')),
      body: BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (BuildContext context, AttendanceState state) {
          final AttendanceData? data = state.dataOrNull;
          if (data == null) return const LoadingIndicator();

          final record = data.todayRecord;
          if (record == null) {
            return const EmptyState(
              title: 'لم تسجّل حضوراً بعد اليوم',
              icon: Icons.event_busy,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            children: <Widget>[
              Text(_dateFormat.format(record.checkInAt), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AvahiSpacing.md),
              _SummaryTile(
                icon: Icons.login,
                label: 'وقت الحضور',
                value: _timeFormat.format(record.checkInAt),
              ),
              _SummaryTile(
                icon: Icons.logout,
                label: 'وقت الانصراف',
                value: record.checkOutAt != null ? _timeFormat.format(record.checkOutAt!) : 'لم يُسجَّل بعد',
              ),
              _SummaryTile(
                icon: Icons.timelapse,
                label: 'ساعات العمل',
                valueWidget: HoursCalculator(record: record),
              ),
              _SummaryTile(
                icon: record.checkMethod.isGps ? Icons.gps_fixed : Icons.qr_code,
                label: 'طريقة التسجيل',
                value: record.checkMethod.isGps ? 'الموقع الجغرافي (GPS)' : 'رمز QR',
              ),
              _SummaryTile(
                icon: record.geofenceValid ? Icons.check_circle : Icons.warning_amber_rounded,
                label: 'التحقق الجغرافي',
                value: record.geofenceValid
                    ? 'ضمن نطاق موقع المشروع'
                    : 'خارج نطاق موقع المشروع'
                        '${record.distanceMeters != null ? ' (${record.distanceMeters!.round()} م)' : ''}',
              ),
              _SummaryTile(
                icon: Icons.verified,
                label: 'حالة الاعتماد',
                valueWidget: AttendanceStatusBadge(status: record.status),
              ),
              if (record.notes != null && record.notes!.isNotEmpty)
                _SummaryTile(icon: Icons.notes, label: 'ملاحظات', value: record.notes),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AvahiSpacing.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          valueWidget ?? Text(value ?? '—', style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
