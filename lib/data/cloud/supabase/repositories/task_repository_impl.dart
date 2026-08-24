import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/enums/task_status.dart';
import '../../../../domain/repositories/i_task_repository.dart';
import '../../../dto/task_dto.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [ITaskRepository] فوق جدول `public.tasks` عبر Supabase.
class TaskRepositoryImpl implements ITaskRepository {
  TaskRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  @override
  Future<ResultOf<Task>> getTaskById(String taskId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableTasks)
          .select()
          .eq('id', taskId)
          .single();
      return Right<Failure, Task>(TaskDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Task>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<Task>>> getMyTasks({
    required String userId,
    String? projectId,
  }) async {
    try {
      sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _client
          .from(ApiConstants.tableTasks)
          .select()
          .eq('assigned_to', userId);

      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      final List<Map<String, dynamic>> rows =
          await query.order('kanban_order', ascending: true);

      return Right<Failure, List<Task>>(
        rows.map((Map<String, dynamic> row) => TaskDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<Task>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<Task>>> getProjectTasks(String projectId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableTasks)
          .select()
          .eq('project_id', projectId)
          .order('kanban_order', ascending: true);

      return Right<Failure, List<Task>>(
        rows.map((Map<String, dynamic> row) => TaskDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<Task>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Task>> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    int? kanbanOrder,
  }) async {
    try {
      final Map<String, dynamic> patch = <String, dynamic>{
        'status': status.dbValue,
        if (kanbanOrder != null) 'kanban_order': kanbanOrder,
        if (status.isDone) 'completed_at': DateTime.now().toUtc().toIso8601String(),
      };

      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableTasks)
          .update(patch)
          .eq('id', taskId)
          .select()
          .single();

      return Right<Failure, Task>(TaskDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Task>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Task>> assignTask({
    required String taskId,
    String? assigneeId,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableTasks)
          .update(<String, dynamic>{'assigned_to': assigneeId})
          .eq('id', taskId)
          .select()
          .single();
      return Right<Failure, Task>(TaskDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Task>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Task>> createTask(Task task) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableTasks)
          .insert(TaskDto.fromEntity(task).toInsertJson())
          .select()
          .single();
      return Right<Failure, Task>(TaskDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Task>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
