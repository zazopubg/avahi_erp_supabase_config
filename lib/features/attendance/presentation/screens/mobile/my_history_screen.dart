import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/attendance_record.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/attendance_cubit.dart';
import '../../state/attendance_state.dart';
import '../../widgets/attendance_status_badge.dart';
import '../../widgets/hours_calculator.dart';

/// سجل حضور المستخدم الشخصي (آخر 30 يوماً) — تبويب "سجلي" ضمن
/// [AttendanceMobileHome]. يستدعي `AttendanceCubit.loadHistory` عند
/// أول دخول ([initState]) فقط، تجنباً لإعادة الجلب في كل إعادة بناء.
class MyHistoryScreen extends StatefulWidget {
  const MyHistoryScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends State<MyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceCubit>().loadHistory(userId: widget.user.userId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (BuildContext context, AttendanceState state) {
        final AttendanceData? data = state.dataOrNull;
        if (data == null) return const LoadingIndicator();

        if (data.isHistoryLoading && data.history.isEmpty) {
          return const LoadingIndicator(label: 'جارٍ تحميل السجل...');
        }

        if (data.history.isEmpty) {
          return const EmptyState(
            title: 'لا يوجد سجل حضور خلال آخر 30 يوماً',
            icon: Icons.history,
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<AttendanceCubit>().loadHistory(
                userId: widget.user.userId,
              ),
          child: ListView.separated(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            itemCount: data.history.length,
            separatorBuilder: (_, __) => const SizedBox(height: AvahiSpacing.xs),
            itemBuilder: (BuildContext context, int index) {
              final AttendanceRecord record = data.history[index];
              return _HistoryTile(record: record);
            },
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final AttendanceRecord record;

  static final DateFormat _dateFormat = DateFormat.MMMEd('ar');
  static final DateFormat _timeFormat = DateFormat.Hm('ar');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _dateFormat.format(record.checkInAt),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AvahiSpacing.xxs),
                Text(
                  '${_timeFormat.format(record.checkInAt)}'
                  ' – '
                  '${record.checkOutAt != null ? _timeFormat.format(record.checkOutAt!) : '—'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          HoursCalculator(record: record, dense: true),
          const SizedBox(width: AvahiSpacing.sm),
          AttendanceStatusBadge(status: record.status, dense: true),
        ],
      ),
    );
  }
}
