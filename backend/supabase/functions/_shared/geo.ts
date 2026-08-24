// ============================================================
// _shared/geo.ts
// دوال جغرافية مساعدة — أهمها معادلة Haversine لحساب المسافة
// بين نقطتين (خط عرض/طول) بالأمتار، تُستخدم في attendance-guard
// للتحقق من أن نقطة تسجيل الحضور ضمن نطاق الجيوفنسينغ للمشروع.
// ============================================================

const EARTH_RADIUS_METERS = 6_371_000;

function toRadians(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

/** يحسب المسافة بالأمتار بين نقطتين جغرافيتين باستخدام معادلة Haversine. */
export function haversineDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return EARTH_RADIUS_METERS * c;
}

/** نتيجة التحقق من الجيوفنسينغ لنقطة معينة نسبة لمركز مشروع. */
export interface GeofenceCheckResult {
  distanceMeters: number;
  isValid: boolean;
}

export function checkGeofence(
  pointLat: number,
  pointLon: number,
  centerLat: number,
  centerLon: number,
  radiusMeters: number,
): GeofenceCheckResult {
  const distanceMeters = haversineDistanceMeters(pointLat, pointLon, centerLat, centerLon);
  return {
    distanceMeters: Math.round(distanceMeters * 100) / 100,
    isValid: distanceMeters <= radiusMeters,
  };
}
