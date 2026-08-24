import '../errors/failure.dart';
import '../utils/gps_helper.dart';

/// إحداثيات موقع مبسّطة، مستقلة عن نوع `Position` الخاص بحزمة
/// `geolocator` حتى لا تتسرب تفاصيل الحزمة إلى الطبقات الأعلى.
class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime? capturedAt;
}

/// واجهة خدمة الموقع الجغرافي، تُستخدم من `features/attendance/`
/// (Geofencing، Prompt 15) و`features/field_reports/` و
/// `features/photos/` (وسم الموقع الجغرافي للصور).
///
/// ⚠️ هذه الخطوة تُعرّف العقد فقط استناداً إلى [GpsHelper] (المبني على
/// `geolocator`)؛ التسجيل الفعلي كـ Singleton يتم لاحقاً عبر
/// `core/di/` (Prompt 11).
abstract class LocationService {
  Future<ResultOf<GpsPermissionStatus>> ensurePermission();

  Future<ResultOf<GeoPoint>> currentLocation();

  /// يتحقق مما إذا كانت [point] تقع ضمن نطاق دائري حول [centerLat]/
  /// [centerLng] بنصف قطر [radiusMeters] — يُستخدم مباشرة في منطق
  /// اعتماد تسجيل الحضور.
  bool isWithinGeofence({
    required GeoPoint point,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  });
}
