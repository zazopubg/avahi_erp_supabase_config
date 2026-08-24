import '../../core/errors/failure.dart';
import '../../core/utils/gps_helper.dart';

/// نتيجة التحقق الجغرافي (Geofence) لعملية تسجيل حضور — تُبنى فوق
/// معادلة Haversine في [GpsHelper.isWithinGeofence]/[GpsHelper.distanceMeters].
class GeofenceCheckResult {
  const GeofenceCheckResult({required this.isValid, required this.distanceMeters});

  /// صحيح إذا كانت نقطة تسجيل الحضور ضمن نطاق الجيوفنسينغ.
  final bool isValid;

  /// المسافة الفعلية بالأمتار بين نقطة الحضور ومركز المشروع.
  final double distanceMeters;
}

/// تحقّقات نطاق `attendance/` — منطق Haversine للجيوفنسينغ + تحقّقات
/// أساسية على توقيت التسجيل. لا يعتمد على أي طبقة `data/`؛ Dart نقي.
abstract final class AttendanceValidator {
  /// يتحقق من أن نقطة تسجيل الحضور ([pointLat]/[pointLng]) تقع ضمن
  /// دائرة الجيوفنسينغ حول مركز المشروع ([centerLat]/[centerLng])
  /// بنصف قطر [radiusMeters]. يُستخدم من `CheckInUsecase` قبل بناء
  /// [AttendanceRecord.geofenceValid]/[AttendanceRecord.distanceMeters].
  static GeofenceCheckResult checkGeofence({
    required double pointLat,
    required double pointLng,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) {
    final double distance = GpsHelper.distanceMeters(
      startLat: pointLat,
      startLng: pointLng,
      endLat: centerLat,
      endLng: centerLng,
    );
    return GeofenceCheckResult(
      isValid: distance <= radiusMeters,
      distanceMeters: distance,
    );
  }

  /// يتحقق من صلاحية توقيت تسجيل الحضور: يجب ألا يكون في المستقبل،
  /// وألا يسبق وقت الانصراف (عند تسجيله لاحقاً) إن وُجد.
  static ResultOf<void> validateCheckTimes({
    required DateTime checkInAt,
    DateTime? checkOutAt,
    DateTime? now,
  }) {
    final DateTime effectiveNow = now ?? DateTime.now();

    if (checkInAt.isAfter(effectiveNow)) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'لا يمكن تسجيل حضور بتوقيت مستقبلي.',
          code: 'attendance.check_in_in_future',
        ),
      );
    }

    if (checkOutAt != null && checkOutAt.isBefore(checkInAt)) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'وقت الانصراف لا يمكن أن يسبق وقت الحضور.',
          code: 'attendance.check_out_before_check_in',
        ),
      );
    }

    return const Right<Failure, void>(null);
  }

  /// يتحقق من توفر إحداثيات صالحة عند تسجيل حضور بطريقة GPS. طريقة
  /// QR لا تتطلب بالضرورة إحداثيات دقيقة (انظر [QrCheckInUsecase]).
  static ResultOf<void> requireCoordinates({
    required double? latitude,
    required double? longitude,
  }) {
    if (latitude == null || longitude == null) {
      return const Left<Failure, void>(
        ValidationFailure(
          message: 'إحداثيات الموقع الجغرافي مطلوبة لتسجيل الحضور.',
          code: 'attendance.missing_coordinates',
        ),
      );
    }
    return const Right<Failure, void>(null);
  }
}
