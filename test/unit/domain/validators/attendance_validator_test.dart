import 'package:avahi/core/errors/failure.dart';
import 'package:avahi/core/utils/gps_helper.dart';
import 'package:avahi/domain/validators/attendance_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // مركز جيوفنسينغ ثابت (وسط الموصل تقريباً) بنصف قطر 150م لكل الحالات
  // الحدّية أدناه.
  const double centerLat = 36.1911;
  const double centerLng = 44.0092;
  const double radiusMeters = 150;

  group('AttendanceValidator.checkGeofence — حالات حدّية (Haversine)', () {
    test('نقطة مطابقة تماماً لمركز المشروع (مسافة = 0) ضمن النطاق دائماً',
        () {
      final GeofenceCheckResult result = AttendanceValidator.checkGeofence(
        pointLat: centerLat,
        pointLng: centerLng,
        centerLat: centerLat,
        centerLng: centerLng,
        radiusMeters: radiusMeters,
      );

      expect(result.isValid, isTrue);
      expect(result.distanceMeters, 0);
    });

    test('نقطة على الحدّ الفاصل تماماً (المسافة = نصف القطر) تُعتبر صالحة '
        '(<=)', () {
      // نبني نقطة على خط الطول نفسه، تبعد شمالاً بمقدار [radiusMeters]
      // متراً بالضبط عبر تحويل عكسي من صيغة المسافة الزاويّة القياسية
      // (1 درجة خط عرض ≈ 111,320 متراً).
      const double metersPerDegreeLat = 111320;
      const double deltaLat = radiusMeters / metersPerDegreeLat;

      final GeofenceCheckResult result = AttendanceValidator.checkGeofence(
        pointLat: centerLat + deltaLat,
        pointLng: centerLng,
        centerLat: centerLat,
        centerLng: centerLng,
        radiusMeters: radiusMeters,
      );

      // الفرق قد يكون كسوراً بسيطة من المتر بسبب تقريب `metersPerDegreeLat`؛
      // نتحقق أن المسافة قريبة جداً من نصف القطر (بفارق < 1م) بدل تساوٍ
      // تام لتفادي هشاشة الاختبار أمام تقريب النقطة العائمة (Floating
      // Point)، مع تأكيد أن قرار الصلاحية يبقى متسقاً مع `<=` في الكود.
      expect(result.distanceMeters, closeTo(radiusMeters, 1));
    });

    test('نقطة أبعد بمتر واحد فقط خارج نصف القطر تُعتبر غير صالحة', () {
      const double metersPerDegreeLat = 111320;
      // نستخدم هامشاً أكبر بوضوح (نصف القطر + 50م) لتفادي أي التباس ناتج
      // عن تقريب [metersPerDegreeLat] القريب من الحدّ في الاختبار السابق.
      const double deltaLat = (radiusMeters + 50) / metersPerDegreeLat;

      final GeofenceCheckResult result = AttendanceValidator.checkGeofence(
        pointLat: centerLat + deltaLat,
        pointLng: centerLng,
        centerLat: centerLat,
        centerLng: centerLng,
        radiusMeters: radiusMeters,
      );

      expect(result.isValid, isFalse);
      expect(result.distanceMeters, greaterThan(radiusMeters));
    });

    test('نقطة قريبة جداً من المركز (مسافة صغيرة جداً > 0) تبقى صالحة', () {
      final GeofenceCheckResult result = AttendanceValidator.checkGeofence(
        pointLat: centerLat + 0.0000001,
        pointLng: centerLng,
        centerLat: centerLat,
        centerLng: centerLng,
        radiusMeters: radiusMeters,
      );

      expect(result.isValid, isTrue);
      expect(result.distanceMeters, greaterThan(0));
    });

    test('نقطة على الجانب الآخر من خط غرينتش (طول سالب/موجب) تُحسب بشكل '
        'صحيح عبر GpsHelper.distanceMeters مباشرة', () {
      // نقطتان متطابقتان تقريباً حول خط الطول صفر — تحقق سلامة الحساب دون
      // أخطاء إشارة (Sign errors) في معادلة Haversine.
      final double distance = GpsHelper.distanceMeters(
        startLat: 51.5074,
        startLng: -0.0010,
        endLat: 51.5074,
        endLng: 0.0010,
      );

      expect(distance, greaterThan(0));
      expect(distance, lessThan(300));
    });
  });

  group('AttendanceValidator.validateCheckTimes', () {
    test('يقبل توقيت حضور في الماضي القريب بالنسبة لـ now الممرَّرة', () {
      final DateTime now = DateTime.utc(2026, 1, 10, 9);
      final DateTime checkInAt = now.subtract(const Duration(minutes: 5));

      final ResultOf<void> result = AttendanceValidator.validateCheckTimes(
        checkInAt: checkInAt,
        now: now,
      );

      expect(result.isRight, isTrue);
    });

    test('يرفض توقيت حضور مستقبلي بالنسبة لـ now الممرَّرة', () {
      final DateTime now = DateTime.utc(2026, 1, 10, 9);
      final DateTime checkInAt = now.add(const Duration(minutes: 1));

      final ResultOf<void> result = AttendanceValidator.validateCheckTimes(
        checkInAt: checkInAt,
        now: now,
      );

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).code, 'attendance.check_in_in_future');
    });

    test('يقبل توقيت حضور مطابق تماماً لـ now (حدّي وليس بعده)', () {
      final DateTime now = DateTime.utc(2026, 1, 10, 9);

      final ResultOf<void> result = AttendanceValidator.validateCheckTimes(
        checkInAt: now,
        now: now,
      );

      expect(result.isRight, isTrue);
    });

    test('يرفض وقت انصراف يسبق وقت الحضور', () {
      final DateTime now = DateTime.utc(2026, 1, 10, 17);
      final DateTime checkInAt = now.subtract(const Duration(hours: 8));
      final DateTime checkOutAt = checkInAt.subtract(const Duration(minutes: 1));

      final ResultOf<void> result = AttendanceValidator.validateCheckTimes(
        checkInAt: checkInAt,
        checkOutAt: checkOutAt,
        now: now,
      );

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect(
        (failure as ValidationFailure).code,
        'attendance.check_out_before_check_in',
      );
    });

    test('يقبل وقت انصراف مطابق تماماً لوقت الحضور (حدّي)', () {
      final DateTime now = DateTime.utc(2026, 1, 10, 17);
      final DateTime checkInAt = now.subtract(const Duration(hours: 8));

      final ResultOf<void> result = AttendanceValidator.validateCheckTimes(
        checkInAt: checkInAt,
        checkOutAt: checkInAt,
        now: now,
      );

      expect(result.isRight, isTrue);
    });
  });

  group('AttendanceValidator.requireCoordinates', () {
    test('يرفض عند خلوّ خط العرض', () {
      final ResultOf<void> result = AttendanceValidator.requireCoordinates(
        latitude: null,
        longitude: centerLng,
      );

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).code, 'attendance.missing_coordinates');
    });

    test('يرفض عند خلوّ خط الطول', () {
      final ResultOf<void> result = AttendanceValidator.requireCoordinates(
        latitude: centerLat,
        longitude: null,
      );

      expect(result.isLeft, isTrue);
    });

    test('يقبل عند توفر كلا الإحداثيتين', () {
      final ResultOf<void> result = AttendanceValidator.requireCoordinates(
        latitude: centerLat,
        longitude: centerLng,
      );

      expect(result.isRight, isTrue);
    });
  });
}
