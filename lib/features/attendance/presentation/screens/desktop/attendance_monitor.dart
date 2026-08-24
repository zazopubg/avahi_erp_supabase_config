import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/attendance_record.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/attendance_cubit.dart';
import '../../state/attendance_state.dart';
import '../../widgets/worker_row.dart';

/// لوحة مراقبة الحضور اللحظية (Realtime) — سطح المكتب، لدور
/// المشرف/رئيس العمال/مدير المشروع (صلاحية
/// [Permission.attendanceApproveTeam]). تعرض إحصاءات سريعة (حاضرون
/// اليوم / بانتظار الاعتماد)، ثم قائمة [WorkerRow] مباشرة تُحدَّث تلقائياً
/// عبر بث `AttendanceCubit.loadMonitor` (بلا أي تحديث يدوي مطلوب من
/// المستخدم)، مع تمييز لوني واضح (شريط جانبي أحمر/أخضر ضمن [WorkerRow]
/// نفسها) لأي سجل `geofenceValid = false`.
class AttendanceMonitor extends StatefulWidget {
  const AttendanceMonitor({required this.user, super.key});

  final AppUser user;

  @override
  State<AttendanceMonitor> createState() => _AttendanceMonitorState();
}

class _AttendanceMonitorState extends State<AttendanceMonitor> {
  @override
  void initState() {
    super.initState();
    final AttendanceCubit cubit = context.read<AttendanceCubit>();
    final AttendanceData? data = cubit.state.dataOrNull;
    if (data != null) cubit.loadMonitor(data.project.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (BuildContext context, AttendanceState state) {
        final AttendanceData? data = state.dataOrNull;
        if (data == null) return const LoadingIndicator();

        if (data.isMonitorLoading && data.monitorRecords.isEmpty) {
          return const LoadingIndicator(label: 'جارٍ تحميل بيانات المراقبة...');
        }

        return Padding(
          padding: const EdgeInsets.all(AvahiSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StatCard(
                      icon: Icons.groups,
                      label: 'حاضرون اليوم',
                      value: '${data.monitorRecords.length}',
                    ),
                  ),
                  const SizedBox(width: AvahiSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.hourglass_top,
                      label: 'بانتظار الاعتماد',
                      value: '${data.pendingApprovalCount}',
                    ),
                  ),
                  const SizedBox(width: AvahiSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.warning_amber_rounded,
                      label: 'خارج نطاق الموقع',
                      value: '${data.monitorRecords.where((AttendanceRecord r) => !r.geofenceValid).length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AvahiSpacing.lg),
              Expanded(
                child: data.monitorRecords.isEmpty
                    ? const EmptyState(
                        title: 'لا يوجد حضور مُسجَّل اليوم بعد',
                        icon: Icons.groups_outlined,
                      )
                    : ListView.builder(
                        itemCount: data.monitorRecords.length,
                        itemBuilder: (BuildContext context, int index) {
                          final AttendanceRecord record = data.monitorRecords[index];
                          return WorkerRow(
                            key: ValueKey<String>(record.id),
                            record: record,
                            onApprove: record.status.isPending
                                ? () => context.read<AttendanceCubit>().reviewAttendance(
                                      attendanceId: record.id,
                                      approve: true,
                                      reviewerId: widget.user.userId,
                                    )
                                : null,
                            onReject: record.status.isPending
                                ? () => context.read<AttendanceCubit>().reviewAttendance(
                                      attendanceId: record.id,
                                      approve: false,
                                      reviewerId: widget.user.userId,
                                    )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

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
      child: Row(
        children: <Widget>[
          Icon(icon, color: colors.brand),
          const SizedBox(width: AvahiSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
