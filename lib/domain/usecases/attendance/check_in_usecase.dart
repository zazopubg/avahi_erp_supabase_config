import '../../../core/errors/failure.dart';
import '../../../core/utils/id_generator.dart';
import '../../entities/attendance_record.dart';
import '../../enums/attendance_type.dart';
import '../../enums/check_method.dart';
import '../../repositories/i_attendance_repository.dart';
import '../../validators/attendance_validator.dart';

/// UseCase تسجيل حضور جديد (Check-in) عبر GPS. يولّد
/// [AttendanceRecord.clientMutationId] محلياً (Offline-first)، يتحقق
/// من الإحداثيات وصلاحية التوقيت، ويحسب نتيجة الجيوفنسينغ (Haversine)
/// عبر [AttendanceValidator] قبل تمرير السجل إلى [IAttendanceRepository.checkIn].
class CheckInUsecase {
  const CheckInUsecase(this._repository);

  final IAttendanceRepository _repository;

  Future<ResultOf<AttendanceRecord>> call({
    required String companyId,
    required String projectId,
    required String userId,
    required double checkInLatitude,
    required double checkInLongitude,
    required double projectCenterLatitude,
    required double projectCenterLongitude,
    required double geofenceRadiusMeters,
    String? notes,
    DateTime? checkInAt,
  }) async {
    final ResultOf<void> coordinatesCheck = AttendanceValidator.requireCoordinates(
      latitude: checkInLatitude,
      longitude: checkInLongitude,
    );
    if (coordinatesCheck.isLeft) {
      return coordinatesCheck.fold(
        (Failure f) => Left<Failure, AttendanceRecord>(f),
        (_) => throw StateError('unreachable'),
      );
    }

    final DateTime effectiveCheckInAt = checkInAt ?? DateTime.now();

    final ResultOf<void> timesCheck = AttendanceValidator.validateCheckTimes(
      checkInAt: effectiveCheckInAt,
    );
    if (timesCheck.isLeft) {
      return timesCheck.fold(
        (Failure f) => Left<Failure, AttendanceRecord>(f),
        (_) => throw StateError('unreachable'),
      );
    }

    final GeofenceCheckResult geofence = AttendanceValidator.checkGeofence(
      pointLat: checkInLatitude,
      pointLng: checkInLongitude,
      centerLat: projectCenterLatitude,
      centerLng: projectCenterLongitude,
      radiusMeters: geofenceRadiusMeters,
    );

    final String clientMutationId = IdGenerator.v4();
    final DateTime now = DateTime.now();

    final AttendanceRecord record = AttendanceRecord(
      id: clientMutationId,
      companyId: companyId,
      projectId: projectId,
      userId: userId,
      clientMutationId: clientMutationId,
      checkInAt: effectiveCheckInAt,
      checkInLatitude: checkInLatitude,
      checkInLongitude: checkInLongitude,
      geofenceValid: geofence.isValid,
      distanceMeters: geofence.distanceMeters,
      checkMethod: CheckMethod.gps,
      status: AttendanceType.pending,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.checkIn(record);
  }
}
