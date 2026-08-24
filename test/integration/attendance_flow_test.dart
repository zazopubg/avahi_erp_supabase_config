import 'package:avahi/core/errors/failure.dart';
import 'package:avahi/core/services/location_service.dart';
import 'package:avahi/core/utils/gps_helper.dart';
import 'package:avahi/domain/entities/app_user.dart';
import 'package:avahi/domain/entities/attendance_record.dart';
import 'package:avahi/domain/entities/project.dart';
import 'package:avahi/domain/repositories/i_attendance_repository.dart';
import 'package:avahi/domain/repositories/i_project_repository.dart';
import 'package:avahi/domain/usecases/attendance/check_in_usecase.dart';
import 'package:avahi/domain/usecases/attendance/check_out_usecase.dart';
import 'package:avahi/domain/usecases/attendance/get_my_attendance_history_usecase.dart';
import 'package:avahi/domain/usecases/attendance/get_project_attendance_usecase.dart';
import 'package:avahi/domain/usecases/attendance/get_today_attendance_usecase.dart';
import 'package:avahi/domain/usecases/attendance/qr_check_in_usecase.dart';
import 'package:avahi/domain/usecases/attendance/review_attendance_usecase.dart';
import 'package:avahi/domain/usecases/attendance/watch_project_attendance_usecase.dart';
import 'package:avahi/domain/usecases/projects/get_my_projects_usecase.dart';
import 'package:avahi/features/attendance/presentation/state/attendance_cubit.dart';
import 'package:avahi/features/attendance/presentation/state/attendance_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';

class MockProjectRepository extends Mock implements IProjectRepository {}

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

class MockLocationService extends Mock implements LocationService {}

class FakeAttendanceRecord extends Fake implements AttendanceRecord {}

void main() {
  late MockProjectRepository projectRepository;
  late MockAttendanceRepository attendanceRepository;
  late MockLocationService locationService;
  late AttendanceCubit cubit;

  final Project project = Fixtures.project();
  final AppUser user = Fixtures.appUser();

  setUpAll(() {
    registerFallbackValue(FakeAttendanceRecord());
  });

  setUp(() {
    projectRepository = MockProjectRepository();
    attendanceRepository = MockAttendanceRepository();
    locationService = MockLocationService();

    cubit = AttendanceCubit(
      getMyProjectsUsecase: GetMyProjectsUsecase(projectRepository),
      getTodayAttendanceUsecase: GetTodayAttendanceUsecase(attendanceRepository),
      checkInUsecase: CheckInUsecase(attendanceRepository),
      qrCheckInUsecase: QrCheckInUsecase(attendanceRepository),
      checkOutUsecase: CheckOutUsecase(attendanceRepository),
      reviewAttendanceUsecase: ReviewAttendanceUsecase(attendanceRepository),
      getMyAttendanceHistoryUsecase:
          GetMyAttendanceHistoryUsecase(attendanceRepository),
      getProjectAttendanceUsecase: GetProjectAttendanceUsecase(attendanceRepository),
      watchProjectAttendanceUsecase:
          WatchProjectAttendanceUsecase(attendanceRepository),
      locationService: locationService,
    );
  });

  tearDown(() => cubit.close());

  test(
      'التدفّق الكامل: تحميل أولي ← تسجيل حضور ضمن النطاق (GPS) ← تسجيل '
      'انصراف ← ملخص اليوم النهائي مكتمل', () async {
    // ── الخطوة 1: التحميل الأولي — لا يوجد سجل حضور اليوم بعد ──────
    when(() => projectRepository.getMyProjects('user-1'))
        .thenAnswer((_) async => Right<Failure, List<Project>>(<Project>[project]));
    when(
      () => attendanceRepository.getTodayAttendance(
        userId: 'user-1',
        projectId: 'project-1',
      ),
    ).thenAnswer((_) async => const Right<Failure, AttendanceRecord?>(null));
    when(() => locationService.ensurePermission()).thenAnswer(
      (_) async => const Right<Failure, GpsPermissionStatus>(GpsPermissionStatus.granted),
    );

    await cubit.loadInitial(user);

    expect(cubit.state, isA<AttendanceReady>());
    AttendanceData data = cubit.state.dataOrNull!;
    expect(data.hasCheckedInToday, isFalse);
    expect(data.project.id, 'project-1');
    expect(data.gpsStatus, GpsPermissionStatus.granted);

    // ── الخطوة 2: تسجيل حضور عبر GPS — بالضبط عند مركز الجيوفنسينغ ──
    when(() => locationService.currentLocation()).thenAnswer(
      (_) async => const Right<Failure, GeoPoint>(
        GeoPoint(latitude: 36.1911, longitude: 44.0092),
      ),
    );
    when(() => attendanceRepository.checkIn(any())).thenAnswer(
      (Invocation invocation) async => Right<Failure, AttendanceRecord>(
        invocation.positionalArguments.first as AttendanceRecord,
      ),
    );

    await cubit.checkInGps(user: user);

    expect(cubit.state, isA<AttendanceCheckInSuccess>());
    data = cubit.state.dataOrNull!;
    expect(data.hasCheckedInToday, isTrue);
    expect(data.todayRecord!.geofenceValid, isTrue);
    expect(data.hasCheckedOutToday, isFalse);
    verify(() => attendanceRepository.checkIn(any())).called(1);

    final AttendanceRecord recordAfterCheckIn = data.todayRecord!;

    // ── الخطوة 3: تسجيل انصراف لنفس سجل اليوم ──────────────────────
    when(
      () => attendanceRepository.checkOut(
        attendanceId: recordAfterCheckIn.id,
        checkOutAt: any(named: 'checkOutAt'),
        checkOutLatitude: any(named: 'checkOutLatitude'),
        checkOutLongitude: any(named: 'checkOutLongitude'),
      ),
    ).thenAnswer((Invocation invocation) async {
      final DateTime checkOutAt =
          invocation.namedArguments[#checkOutAt] as DateTime;
      return Right<Failure, AttendanceRecord>(
        recordAfterCheckIn.copyWith(checkOutAt: checkOutAt),
      );
    });

    await cubit.checkOut(user: user);

    // ── الخطوة 4: ملخص اليوم النهائي — حضور وانصراف مكتملان معاً ────
    expect(cubit.state, isA<AttendanceReady>());
    data = cubit.state.dataOrNull!;
    expect(data.hasCheckedInToday, isTrue);
    expect(data.hasCheckedOutToday, isTrue);
    expect(data.todayRecord!.checkOutAt, isNotNull);
    expect(
      data.todayRecord!.checkOutAt!.isAfter(data.todayRecord!.checkInAt) ||
          data.todayRecord!.checkOutAt!.isAtSameMomentAs(data.todayRecord!.checkInAt),
      isTrue,
    );
    verify(
      () => attendanceRepository.checkOut(
        attendanceId: recordAfterCheckIn.id,
        checkOutAt: any(named: 'checkOutAt'),
        checkOutLatitude: any(named: 'checkOutLatitude'),
        checkOutLongitude: any(named: 'checkOutLongitude'),
      ),
    ).called(1);
  });

  test(
      'التدفّق عند تسجيل حضور خارج نطاق الجيوفنسينغ: يبقى تحذيراً '
      'تفاعلياً (لا رفضاً)، والانصراف يبقى ممكناً بعده بشكل طبيعي',
      () async {
    when(() => projectRepository.getMyProjects('user-1'))
        .thenAnswer((_) async => Right<Failure, List<Project>>(<Project>[project]));
    when(
      () => attendanceRepository.getTodayAttendance(
        userId: 'user-1',
        projectId: 'project-1',
      ),
    ).thenAnswer((_) async => const Right<Failure, AttendanceRecord?>(null));
    when(() => locationService.ensurePermission()).thenAnswer(
      (_) async => const Right<Failure, GpsPermissionStatus>(GpsPermissionStatus.granted),
    );
    await cubit.loadInitial(user);

    // نقطة أبعد بوضوح من نصف قطر الـ 150م المسموح.
    when(() => locationService.currentLocation()).thenAnswer(
      (_) async => const Right<Failure, GeoPoint>(
        GeoPoint(latitude: 36.20, longitude: 44.0092),
      ),
    );
    when(() => attendanceRepository.checkIn(any())).thenAnswer(
      (Invocation invocation) async => Right<Failure, AttendanceRecord>(
        invocation.positionalArguments.first as AttendanceRecord,
      ),
    );

    await cubit.checkInGps(user: user);

    expect(cubit.state, isA<AttendanceCheckInGeofenceWarning>());
    final AttendanceData data = cubit.state.dataOrNull!;
    expect(data.hasCheckedInToday, isTrue);
    expect(data.todayRecord!.geofenceValid, isFalse);
    // السجل محفوظ فعلياً رغم التحذير — وليس مرفوضاً بالكامل.
    expect(data.lastCheckInDistanceMeters, greaterThan(150));
  });
}
