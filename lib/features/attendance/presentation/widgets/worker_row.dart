import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/attendance_record.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import 'attendance_status_badge.dart';
import 'hours_calculator.dart';

/// صف عامل واحد ضمن لوحة المراقبة اللحظية `attendance_monitor.dart`
/// (سطح المكتب) — يعرض معرّف المستخدم (مختصراً؛ حل عرض أسماء كاملة
/// مؤجَّل عمداً لـ `features/users/`، Prompt 26 — انظر ملاحظة داخل
/// `attendance_cubit.dart` وتوثيق التصميم أعلاه)، وقت الحضور/الانصراف،
/// ساعات العمل، حالة الاعتماد، وتمييز لوني واضح عند
/// `geofenceValid = false`.
///
/// مكوّن عرض بحت — [onApprove]/[onReject] اختياريان؛ عند تركهما `null`
/// (مثال: مستخدم بلا صلاحية [Permission.attendanceApproveTeam]، أو
/// سجل مُعتمد/مرفوض مسبقاً) لا تُعرض أزرار الإجراء إطلاقاً.
class WorkerRow extends StatelessWidget {
  const WorkerRow({
    required this.record,
    super.key,
    this.onApprove,
    this.onReject,
    this.dense = false,
  });

  final AttendanceRecord record;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool dense;

  static final DateFormat _timeFormat = DateFormat.Hm('ar');

  String get _shortUserId =>
      record.userId.length > 8 ? '#${record.userId.substring(0, 8)}' : '#${record.userId}';

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final bool showActions =
        record.status.isPending && (onApprove != null || onReject != null);

    return Container(
      margin: const EdgeInsets.only(bottom: AvahiSpacing.xs),
      padding: EdgeInsets.symmetric(
        horizontal: AvahiSpacing.sm,
        vertical: dense ? AvahiSpacing.xs : AvahiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          right: BorderSide(
            width: 4,
            color: record.geofenceValid ? colors.success : colors.danger,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: dense ? 14 : 18,
            backgroundColor: colors.brandContainer,
            child: Icon(Icons.person, color: colors.onBrandContainer, size: dense ? 14 : 18),
          ),
          const SizedBox(width: AvahiSpacing.sm),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_shortUserId, style: Theme.of(context).textTheme.titleSmall),
                if (!record.geofenceValid)
                  Text(
                    'خارج نطاق الموقع',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.danger),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              _timeFormat.format(record.checkInAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              record.checkOutAt != null ? _timeFormat.format(record.checkOutAt!) : '—',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: HoursCalculator(record: record, dense: true)),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AttendanceStatusBadge(status: record.status, dense: true),
            ),
          ),
          if (showActions)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (onApprove != null)
                  IconButton(
                    icon: Icon(Icons.check_circle, color: colors.success),
                    tooltip: 'اعتماد',
                    onPressed: onApprove,
                  ),
                if (onReject != null)
                  IconButton(
                    icon: Icon(Icons.cancel, color: colors.danger),
                    tooltip: 'رفض',
                    onPressed: onReject,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
