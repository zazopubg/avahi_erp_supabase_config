import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../domain/entities/attendance_record.dart';
import '../../../dto/attendance_dto.dart';
import 'realtime_manager.dart';

/// يبث تغييرات (تسجيل حضور جديد/اعتماد) جدول `public.attendance`
/// لحظياً ضمن مشروع محدد — يُستخدم للوحة حضور حيّة في
/// `features/attendance/` (Prompt 15)، مثال: عداد "الحاضرين الآن"
/// يتحدّث فوراً دون تحديث الصفحة يدوياً.
class AttendanceSubscription {
  AttendanceSubscription({RealtimeManager? realtimeManager})
      : _realtimeManager = realtimeManager ?? RealtimeManager();

  final RealtimeManager _realtimeManager;

  Stream<AttendanceRecord> watchProjectAttendance(String projectId) {
    final StreamController<AttendanceRecord> controller =
        StreamController<AttendanceRecord>.broadcast();
    controller.onCancel = controller.close;
    final String channelName = 'attendance:project_id=eq.$projectId';

    _realtimeManager.channelFor(channelName, (sb.RealtimeChannel channel) {
      return channel
          .onPostgresChanges(
            event: sb.PostgresChangeEvent.insert,
            schema: 'public',
            table: ApiConstants.tableAttendance,
            filter: sb.PostgresChangeFilter(
              type: sb.PostgresChangeFilterType.eq,
              column: 'project_id',
              value: projectId,
            ),
            callback: (sb.PostgresChangePayload payload) {
              controller.add(AttendanceDto.fromJson(payload.newRecord).toEntity());
            },
          )
          .onPostgresChanges(
            event: sb.PostgresChangeEvent.update,
            schema: 'public',
            table: ApiConstants.tableAttendance,
            filter: sb.PostgresChangeFilter(
              type: sb.PostgresChangeFilterType.eq,
              column: 'project_id',
              value: projectId,
            ),
            callback: (sb.PostgresChangePayload payload) {
              controller.add(AttendanceDto.fromJson(payload.newRecord).toEntity());
            },
          );
    });

    return controller.stream;
  }
}
