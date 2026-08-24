import 'package:avahi/core/utils/gps_helper.dart';
import 'package:avahi/domain/enums/check_method.dart';
import 'package:avahi/features/attendance/presentation/screens/mobile/check_in_screen.dart';
import 'package:avahi/features/attendance/presentation/state/attendance_cubit.dart';
import 'package:avahi/features/attendance/presentation/state/attendance_state.dart';
import 'package:avahi/features/attendance/presentation/widgets/geofence_alert_banner.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/pump_app.dart';

class MockAttendanceCubit extends MockCubit<AttendanceState>
    implements AttendanceCubit {}

void main() {
  late MockAttendanceCubit cubit;

  final AttendanceData readyData = AttendanceData(
    project: Fixtures.project(),
    checkMethod: CheckMethod.gps,
    gpsStatus: GpsPermissionStatus.granted,
  );

  setUp(() {
    cubit = MockAttendanceCubit();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required AttendanceState state,
    bool gloveModeEnabled = false,
  }) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<AttendanceState>.empty(), initialState: state);

    await tester.pumpAvahiApp(
      BlocProvider<AttendanceCubit>.value(
        value: cubit,
        child: CheckInScreen(user: Fixtures.appUser()),
      ),
      gloveModeEnabled: gloveModeEnabled,
    );
    await tester.pumpAndSettle();
  }

  group('CheckInScreen — بانر تحذير الجيوفنسينغ', () {
    testWidgets(
        'لا يظهر GeofenceAlertBanner في الحالة الجاهزة العادية (Ready)',
        (WidgetTester tester) async {
      await pumpScreen(tester, state: AttendanceReady(readyData));

      expect(find.byType(GeofenceAlertBanner), findsNothing);
    });

    testWidgets(
        'يظهر GeofenceAlertBanner فور دخول حالة '
        'AttendanceCheckInGeofenceWarning', (WidgetTester tester) async {
      final AttendanceData warningData = readyData.copyWith(
        lastCheckInDistanceMeters: 210,
      );

      await pumpScreen(
        tester,
        state: AttendanceCheckInGeofenceWarning(warningData),
      );

      expect(find.byType(GeofenceAlertBanner), findsOneWidget);
    });
  });

  group('CheckInScreen — تكبير الزر عند وضع القفازات (Glove Mode)', () {
    testWidgets('ارتفاع زر تسجيل الحضور الأدنى هو 52 عند تعطيل Glove Mode',
        (WidgetTester tester) async {
      await pumpScreen(
        tester,
        state: AttendanceReady(readyData),
      );

      final ElevatedButton button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      final Size? minSize = button.style?.minimumSize?.resolve(<WidgetState>{});

      expect(minSize?.height, 52);
    });

    testWidgets(
        'يكبر ارتفاع الزر الأدنى إلى 66 (52 + 14) فور تفعيل Glove Mode',
        (WidgetTester tester) async {
      await pumpScreen(
        tester,
        state: AttendanceReady(readyData),
        gloveModeEnabled: true,
      );

      final ElevatedButton button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      final Size? minSize = button.style?.minimumSize?.resolve(<WidgetState>{});

      expect(minSize?.height, 66);
    });
  });
}
