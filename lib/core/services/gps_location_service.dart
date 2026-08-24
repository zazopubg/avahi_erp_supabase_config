import 'package:geolocator/geolocator.dart';

import '../errors/failure.dart';
import '../errors/permission_exception.dart';
import '../utils/gps_helper.dart';
import 'location_service.dart';

/// تنفيذ [LocationService] فوق [GpsHelper] (`core/utils/gps_helper.dart`،
/// المبني على حزمة `geolocator`) — أول تنفيذ فعلي لهذا العقد، مبني عند
/// أول حاجة فعلية له من `features/attendance/` (Prompt 15، Geofencing).
///
/// يترجم كل استثناء GPS خام (`geolocator`) أو حالة إذن مرفوضة إلى
/// [Failure] موحّد عبر [Failure.fromException]، بنفس نمط بقية
/// `data/`/`domain/` في المشروع — لا تتسرب أي تفاصيل من `geolocator`
/// (أنواع `Position`/`LocationPermission`) إلى الطبقات الأعلى من
/// [GeoPoint]/[GpsPermissionStatus] (المعرَّفتين مسبقاً في
/// `location_service.dart`/`gps_helper.dart`، Prompt 02).
class GpsLocationService implements LocationService {
  const GpsLocationService();

  @override
  Future<ResultOf<GpsPermissionStatus>> ensurePermission() async {
    try {
      final GpsPermissionStatus status = await GpsHelper.ensurePermission();
      return Right<Failure, GpsPermissionStatus>(status);
    } catch (error, stackTrace) {
      return Left<Failure, GpsPermissionStatus>(
        Failure.fromException(
          PermissionException.denied(cause: error, st: stackTrace),
        ),
      );
    }
  }

  @override
  Future<ResultOf<GeoPoint>> currentLocation() async {
    try {
      final GpsPermissionStatus permission = await GpsHelper.ensurePermission();
      if (permission != GpsPermissionStatus.granted) {
        return Left<Failure, GeoPoint>(
          PermissionFailure(
            message: _messageFor(permission),
            code: 'location.${permission.name}',
          ),
        );
      }

      final Position position = await GpsHelper.currentPosition();
      return Right<Failure, GeoPoint>(
        GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
          capturedAt: position.timestamp,
        ),
      );
    } catch (error, stackTrace) {
      return Left<Failure, GeoPoint>(
        Failure.fromException(
          PermissionException.denied(cause: error, st: stackTrace),
        ),
      );
    }
  }

  @override
  bool isWithinGeofence({
    required GeoPoint point,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) {
    return GpsHelper.isWithinGeofence(
      pointLat: point.latitude,
      pointLng: point.longitude,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusMeters: radiusMeters,
    );
  }

  String _messageFor(GpsPermissionStatus status) {
    return switch (status) {
      GpsPermissionStatus.granted => 'تم منح إذن الموقع.',
      GpsPermissionStatus.deniedOnce => 'تم رفض إذن الموقع الجغرافي.',
      GpsPermissionStatus.deniedForever =>
        'تم رفض إذن الموقع الجغرافي نهائياً — يجب تفعيله من إعدادات الجهاز.',
      GpsPermissionStatus.serviceDisabled =>
        'خدمة الموقع الجغرافي معطّلة على هذا الجهاز.',
    };
  }
}
