import 'package:avahi/core/errors/failure.dart';
import 'package:avahi/domain/entities/attendance_record.dart';
import 'package:avahi/domain/enums/attendance_type.dart';
import 'package:avahi/domain/enums/check_method.dart';
import 'package:avahi/domain/repositories/i_attendance_repository.dart';
import 'package:avahi/domain/usecases/attendance/check_in_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

void main() {
  late MockAttendanceRepository repository;
  late CheckInUsecase usecase;

  // مركز المشروع (جيوفنسينغ 150 متراً) — نفس مركز `Fixtures.project`.
  const double centerLat = 36.1911;
  const double centerLng = 44.0092;
  const double radiusMeters = 150;

  setUpAll(() {
    registerFallbackValue(
      Fixtures.attendanceRecord(checkInAt: Fixtures.baseTime),
    );
  });

  setUp(() {
    repository = MockAttendanceRepository();
    usecase = CheckInUsecase(repository);
  });

  group('CheckInUsecase — نجاح ضمن نطاق الجيوفنسينغ', () {
    test('يسجّل حضوراً صالحاً (geofenceValid = true) عند نقطة داخل النطاق',
        () async {
      when(() => repository.checkIn(any())).thenAnswer(
        (Invocation invocation) async {
          final AttendanceRecord record =
              invocation.positionalArguments.first as AttendanceRecord;
          return Right<Failure, AttendanceRecord>(record);
        },
      );

      final ResultOf<AttendanceRecord> result = await usecase.call(
        companyId: 'company-1',
        projectId: 'project-1',
        userId: 'user-1',
        checkInLatitude: centerLat,
        checkInLongitude: centerLng,
        projectCenterLatitude: centerLat,
        projectCenterLongitude: centerLng,
        geofenceRadiusMeters: radiusMeters,
        checkInAt: Fixtures.baseTime,
      );

      expect(result.isRight, isTrue);
      final AttendanceRecord record = result.getOrNull()!;
      expect(record.geofenceValid, isTrue);
      expect(record.status, AttendanceType.pending);
      expect(record.checkMethod, CheckMethod.gps);
      verify(() => repository.checkIn(any())).called(1);
    });
  });

  group('CheckInUsecase — نجاح خارج نطاق الجيوفنسينغ (تحذير)', () {
    test(
        'يسجّل الحضور فعلياً (لا يُرفَض) لكن بعلم geofenceValid = false عند '
        'نقطة تبعد أكثر من نصف القطر المسموح', () async {
      AttendanceRecord? capturedRecord;
      when(() => repository.checkIn(any())).thenAnswer(
        (Invocation invocation) async {
          capturedRecord =
              invocation.positionalArguments.first as AttendanceRecord;
          return Right<Failure, AttendanceRecord>(capturedRecord!);
        },
      );

      // نقطة أبعد بحوالي 0.01 درجة (~1.1 كم) عن المركز — خارج نطاق الـ 150م.
      final ResultOf<AttendanceRecord> result = await usecase.call(
        companyId: 'company-1',
        projectId: 'project-1',
        userId: 'user-1',
        checkInLatitude: centerLat + 0.01,
        checkInLongitude: centerLng,
        projectCenterLatitude: centerLat,
        projectCenterLongitude: centerLng,
        geofenceRadiusMeters: radiusMeters,
        checkInAt: Fixtures.baseTime,
      );

      expect(result.isRight, isTrue);
      expect(capturedRecord, isNotNull);
      expect(capturedRecord!.geofenceValid, isFalse);
      expect(capturedRecord!.distanceMeters, greaterThan(radiusMeters));
    });
  });

  group('CheckInUsecase — تحقق التوقيت', () {
    test('يرفض تسجيل حضور بتوقيت مستقبلي دون استدعاء المستودع أصلاً',
        () async {
      final DateTime future = Fixtures.baseTime.add(const Duration(days: 1));

      final ResultOf<AttendanceRecord> result = await usecase.call(
        companyId: 'company-1',
        projectId: 'project-1',
        userId: 'user-1',
        checkInLatitude: centerLat,
        checkInLongitude: centerLng,
        projectCenterLatitude: centerLat,
        projectCenterLongitude: centerLng,
        geofenceRadiusMeters: radiusMeters,
        checkInAt: future,
      );

      expect(result.isLeft, isTrue);
      final Failure failure = result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'attendance.check_in_in_future');
      verifyNever(() => repository.checkIn(any()));
    });
  });

  group('CheckInUsecase — رفض تكرار (تمرير فشل المستودع كما هو)', () {
    test('يعيد فشل المستودع دون تعديل عند رفض تسجيل مكرر لنفس اليوم',
        () async {
      const ValidationFailure duplicateFailure = ValidationFailure(
        message: 'سجّل هذا المستخدم حضوره اليوم فعلاً ضمن هذا المشروع.',
        code: 'attendance.duplicate_check_in',
      );
      when(() => repository.checkIn(any())).thenAnswer(
        (_) async => const Left<Failure, AttendanceRecord>(duplicateFailure),
      );

      final ResultOf<AttendanceRecord> result = await usecase.call(
        companyId: 'company-1',
        projectId: 'project-1',
        userId: 'user-1',
        checkInLatitude: centerLat,
        checkInLongitude: centerLng,
        projectCenterLatitude: centerLat,
        projectCenterLongitude: centerLng,
        geofenceRadiusMeters: radiusMeters,
        checkInAt: Fixtures.baseTime,
      );

      expect(result.isLeft, isTrue);
      final Failure failure = result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect(failure, same(duplicateFailure));
      verify(() => repository.checkIn(any())).called(1);
    });
  });
}
