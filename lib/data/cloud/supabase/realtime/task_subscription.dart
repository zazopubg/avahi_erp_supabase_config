import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../domain/entities/task.dart';
import '../../../dto/task_dto.dart';
import 'realtime_manager.dart';

/// يبث تغييرات (إنشاء/تحديث/نقل بين أعمدة) جدول `public.tasks` لحظياً
/// ضمن مشروع محدد — يُستخدم لتزامن لوحة Kanban بين عدة مستخدمين في
/// `features/tasks/` (Prompt 16) دون تعارض عرض.
class TaskSubscription {
  TaskSubscription({RealtimeManager? realtimeManager})
      : _realtimeManager = realtimeManager ?? RealtimeManager();

  final RealtimeManager _realtimeManager;

  Stream<Task> watchProjectTasks(String projectId) {
    final StreamController<Task> controller = StreamController<Task>.broadcast();
    controller.onCancel = controller.close;
    final String channelName = 'tasks:project_id=eq.$projectId';

    _realtimeManager.channelFor(channelName, (sb.RealtimeChannel channel) {
      return channel
          .onPostgresChanges(
            event: sb.PostgresChangeEvent.insert,
            schema: 'public',
            table: ApiConstants.tableTasks,
            filter: sb.PostgresChangeFilter(
              type: sb.PostgresChangeFilterType.eq,
              column: 'project_id',
              value: projectId,
            ),
            callback: (sb.PostgresChangePayload payload) {
              controller.add(TaskDto.fromJson(payload.newRecord).toEntity());
            },
          )
          .onPostgresChanges(
            event: sb.PostgresChangeEvent.update,
            schema: 'public',
            table: ApiConstants.tableTasks,
            filter: sb.PostgresChangeFilter(
              type: sb.PostgresChangeFilterType.eq,
              column: 'project_id',
              value: projectId,
            ),
            callback: (sb.PostgresChangePayload payload) {
              controller.add(TaskDto.fromJson(payload.newRecord).toEntity());
            },
          );
    });

    return controller.stream;
  }
}
