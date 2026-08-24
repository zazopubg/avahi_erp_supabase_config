import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/enums/check_method.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/attendance_cubit.dart';
import '../../state/attendance_state.dart';
import '../../widgets/attendance_status_badge.dart';
import '../../widgets/big_check_in_button.dart';
import '../../widgets/geofence_alert_banner.dart';
import '../../widgets/gps_status_indicator.dart';
import '../../widgets/hours_calculator.dart';
import 'check_out_screen.dart';
import 'qr_scan_screen.dart';

/// شاشة الدخول الرئيسية لدور العامل الميداني — تبويب "الدخول" ضمن
/// [AttendanceMobileHome]. تحتوي مبدّل طريقة التسجيل (GPS/QR)،
/// [GpsStatusIndicator]، [BigCheckInButton]، وعند تحذير الجيوفنسينغ
/// تظهر [GeofenceAlertBanner] فوق كل شيء (تحذير تفاعلي غير حاجب).
///
/// إن كان المستخدم قد سجّل حضوره اليوم فعلاً وبانتظار تسجيل انصراف،
/// تُستبدل بطاقة "تسجيل الحضور" بملخص الحضور الحالي + زر الانتقال
/// لشاشة تسجيل الانصراف.
class CheckInScreen extends StatelessWidget {
  const CheckInScreen({required this.user, super.key});

  final AppUser user;

  static final DateFormat _timeFormat = DateFormat.Hm('ar');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (BuildContext context, AttendanceState state) {
        final AttendanceData? data = state.dataOrNull;
        if (data == null) return const LoadingIndicator();

        final AttendanceCubit cubit = context.read<AttendanceCubit>();
        final bool isBusy = state is AttendanceCheckInProgress;
        final bool showGeofenceWarning = state is AttendanceCheckInGeofenceWarning;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                data.project.nameAr ?? data.project.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AvahiSpacing.xxs),
              Text(
                'المشروع الحالي لتسجيل الحضور',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AvahiSpacing.md),
              if (showGeofenceWarning) ...<Widget>[
                GeofenceAlertBanner(distanceMeters: data.lastCheckInDistanceMeters),
                const SizedBox(height: AvahiSpacing.md),
              ],
              if (data.checkMethod.isGps) ...<Widget>[
                GpsStatusIndicator(
                  status: data.gpsStatus,
                  onRetry: cubit.refreshGpsStatus,
                ),
                const SizedBox(height: AvahiSpacing.md),
              ],
              SegmentedButton<CheckMethod>(
                segments: const <ButtonSegment<CheckMethod>>[
                  ButtonSegment<CheckMethod>(
                    value: CheckMethod.gps,
                    label: Text('عبر الموقع (GPS)'),
                    icon: Icon(Icons.gps_fixed),
                  ),
                  ButtonSegment<CheckMethod>(
                    value: CheckMethod.qr,
                    label: Text('عبر رمز QR'),
                    icon: Icon(Icons.qr_code_scanner),
                  ),
                ],
                selected: <CheckMethod>{data.checkMethod},
                onSelectionChanged: (Set<CheckMethod> selection) =>
                    cubit.setCheckMethod(selection.first),
              ),
              const SizedBox(height: AvahiSpacing.lg),
              if (data.hasCheckedInToday)
                _TodaySummaryCard(data: data, user: user)
              else
                BigCheckInButton(
                  label: 'تسجيل الحضور',
                  icon: Icons.login,
                  isLoading: isBusy,
                  onPressed: () {
                    if (data.checkMethod.isGps) {
                      cubit.checkInGps(user: user);
                    } else {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => QrScanScreen(user: user),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.data, required this.user});

  final AttendanceData data;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final record = data.todayRecord!;
    final bool checkedOut = record.checkOutAt != null;

    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AvahiSpacing.xs),
              Expanded(
                child: Text(
                  'سجّلت حضورك اليوم الساعة ${CheckInScreen._timeFormat.format(record.checkInAt)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              AttendanceStatusBadge(status: record.status, dense: true),
            ],
          ),
          const SizedBox(height: AvahiSpacing.sm),
          HoursCalculator(record: record),
          const SizedBox(height: AvahiSpacing.md),
          if (!checkedOut)
            BigCheckInButton(
              label: 'تسجيل الانصراف',
              icon: Icons.logout,
              isDanger: true,
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => CheckOutScreen(user: user),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
