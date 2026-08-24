import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/entities/app_user.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/attendance_cubit.dart';
import '../../state/attendance_state.dart';
import '../../widgets/big_check_in_button.dart';
import '../../widgets/hours_calculator.dart';

/// شاشة تسجيل الانصراف — تُفتح عبر `Navigator.push` من
/// `check_in_screen.dart` عند وجود سجل حضور مفتوح لليوم الحالي
/// (`checkOutAt == null`). تعرض وقت الحضور، ساعات العمل المنقضية
/// حتى الآن، وزر تأكيد الانصراف.
class CheckOutScreen extends StatelessWidget {
  const CheckOutScreen({required this.user, super.key});

  final AppUser user;

  static final DateFormat _timeFormat = DateFormat.Hm('ar');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الانصراف')),
      body: BlocConsumer<AttendanceCubit, AttendanceState>(
        listener: (BuildContext context, AttendanceState state) {
          final AttendanceData? data = state.dataOrNull;
          if (data?.hasCheckedOutToday ?? false) {
            Navigator.of(context).pop();
          }
        },
        builder: (BuildContext context, AttendanceState state) {
          final AttendanceData? data = state.dataOrNull;
          final record = data?.todayRecord;
          if (data == null || record == null) return const LoadingIndicator();

          final bool isBusy = state is AttendanceCheckInProgress;

          return Padding(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(AvahiSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'وقت الحضور: ${_timeFormat.format(record.checkInAt)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      HoursCalculator(record: record),
                    ],
                  ),
                ),
                const SizedBox(height: AvahiSpacing.lg),
                BigCheckInButton(
                  label: 'تأكيد تسجيل الانصراف',
                  icon: Icons.logout,
                  isDanger: true,
                  isLoading: isBusy,
                  onPressed: () => context.read<AttendanceCubit>().checkOut(user: user),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
