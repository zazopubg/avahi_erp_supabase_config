import '../../../core/errors/failure.dart';
import '../../../core/utils/id_generator.dart';
import '../../entities/attendance_record.dart';
import '../../enums/attendance_type.dart';
import '../../enums/check_method.dart';
import '../../repositories/i_attendance_repository.dart';
import '../../validators/attendance_validator.dart';

/// UseCase تسجيل حضور عبر مسح رمز QR ثابت في الموقع. 🆕
///
/// نفس منطق [CheckInUsecase] لكن مع `checkMethod = CheckMethod.qr`:
/// يتحقق أولاً من صلاحية رمز QR عبر
/// [IAttendanceRepository.resolveProjectFromQrCode] (يعيد معرّف
/// المشروع المرتبط بالرمز، أو [Left] عند رمز غير صالح/منتهي)، ثم
/// يحسب الجيوفنسينغ كإجراء تحقق إضافي إن توفرت إحداثيات الجهاز
/// (اختيارية هنا، بخلاف GPS check-in حيث الإحداثيات إلزامية).
class QrCheckInUsecase {
  const QrCheckInUsecase(this._repository);

  final IAttendanceRepository _repository;

  Future<ResultOf<AttendanceRecord>> call({
    required String companyId,
    required String userId,
    required String qrCodeId,
    double? deviceLatitude,
    double? deviceLongitude,
    double? projectCenterLatitude,
    double? projectCenterLongitude,
    double? geofenceRadiusMeters,
    String? notes,
    DateTime? checkInAt,
  }) async {
    final ResultOf<String> projectResult =
        await _repository.resolveProjectFromQrCode(qrCodeId);

    return projectResult.fold(
      (Failure f) async => Left<Failure, AttendanceRecord>(f),
      (String projectId) async {
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

        bool geofenceValid = true;
        double? distanceMeters;
        final bool canCheckGeofence = deviceLatitude != null &&
            deviceLongitude != null &&
            projectCenterLatitude != null &&
            projectCenterLongitude != null &&
            geofenceRadiusMeters != null;

        if (canCheckGeofence) {
          final GeofenceCheckResult geofence = AttendanceValidator.checkGeofence(
            pointLat: deviceLatitude,
            pointLng: deviceLongitude,
            centerLat: projectCenterLatitude,
            centerLng: projectCenterLongitude,
            radiusMeters: geofenceRadiusMeters,
          );
          geofenceValid = geofence.isValid;
          distanceMeters = geofence.distanceMeters;
        }

        final String clientMutationId = IdGenerator.v4();
        final DateTime now = DateTime.now();

        final AttendanceRecord record = AttendanceRecord(
          id: clientMutationId,
          companyId: companyId,
          projectId: projectId,
          userId: userId,
          clientMutationId: clientMutationId,
          checkInAt: effectiveCheckInAt,
          checkInLatitude: deviceLatitude,
          checkInLongitude: deviceLongitude,
          geofenceValid: geofenceValid,
          distanceMeters: distanceMeters,
          checkMethod: CheckMethod.qr,
          qrCodeId: qrCodeId,
          status: AttendanceType.pending,
          notes: notes,
          createdAt: now,
          updatedAt: now,
        );

        return _repository.checkIn(record);
      },
    );
  }
}
