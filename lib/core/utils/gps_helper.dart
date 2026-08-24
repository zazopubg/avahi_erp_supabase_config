import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/// حالات إذن الموقع الجغرافي، مُبسّطة عن `LocationPermission` الخاصة
/// بحزمة `geolocator` لتفادي تسريب تفاصيل الحزمة إلى طبقات أعلى.
enum GpsPermissionStatus {
  granted,
  deniedOnce,
  deniedForever,
  serviceDisabled,
}

/// مساعد التعامل مع الموقع الجغرافي (GPS)، مبني فوق حزمة `geolocator`
/// المتوافقة مع الويب. يُستخدم لاحقاً في `services/location_service.dart`
/// ووحدة `features/attendance/` (Geofencing، Prompt 15).
abstract final class GpsHelper {
  /// نصف قطر الأرض بالمتر، مستخدم في معادلة Haversine.
  static const double _earthRadiusMeters = 6371000;

  /// يتحقق من حالة إذن الموقع الحالية ويطلبه عند الحاجة.
  static Future<GpsPermissionStatus> ensurePermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return GpsPermissionStatus.serviceDisabled;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return GpsPermissionStatus.granted;
      case LocationPermission.deniedForever:
        return GpsPermissionStatus.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return GpsPermissionStatus.deniedOnce;
    }
  }

  /// يجلب الموقع الحالي بدقة متوسطة، مناسب لغالبية استخدامات التطبيق
  /// (تسجيل حضور، وسم صورة بموقعها).
  static Future<Position> currentPosition() {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// يحسب المسافة بالمتر بين نقطتين جغرافيتين عبر معادلة Haversine.
  static double distanceMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final double dLat = _degToRad(endLat - startLat);
    final double dLng = _degToRad(endLng - startLng);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(startLat)) *
            math.cos(_degToRad(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// يتحقق مما إذا كانت نقطة ضمن نطاق دائري (Geofence) حول نقطة مرجعية.
  static bool isWithinGeofence({
    required double pointLat,
    required double pointLng,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) {
    final double distance = distanceMeters(
      startLat: pointLat,
      startLng: pointLng,
      endLat: centerLat,
      endLng: centerLng,
    );
    return distance <= radiusMeters;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180);
}
