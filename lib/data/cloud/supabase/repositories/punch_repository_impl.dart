import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/punch_item.dart';
import '../../../../domain/repositories/i_punch_repository.dart';
import '../../../dto/punch_item_dto.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IPunchRepository] فوق جدول `public.punch_items` عبر
/// Supabase.
class PunchRepositoryImpl implements IPunchRepository {
  PunchRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  @override
  Future<ResultOf<PunchItem>> getPunchItemById(String punchItemId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tablePunchItems)
          .select()
          .eq('id', punchItemId)
          .single();
      return Right<Failure, PunchItem>(PunchItemDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, PunchItem>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<PunchItem>>> getProjectPunchItems(String projectId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tablePunchItems)
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return Right<Failure, List<PunchItem>>(
        rows.map((Map<String, dynamic> row) => PunchItemDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<PunchItem>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<PunchItem>> createPunchItem(PunchItem item) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tablePunchItems)
          .insert(PunchItemDto.fromEntity(item).toInsertJson())
          .select()
          .single();
      return Right<Failure, PunchItem>(PunchItemDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, PunchItem>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<PunchItem>> closePunchItem({
    required String punchItemId,
    required String closedBy,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tablePunchItems)
          .update(<String, dynamic>{
            'status': 'closed',
            'closed_by': closedBy,
            'closed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', punchItemId)
          .select()
          .single();
      return Right<Failure, PunchItem>(PunchItemDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, PunchItem>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
