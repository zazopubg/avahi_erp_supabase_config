import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/leave_request.dart';
import '../../../../domain/repositories/i_leave_repository.dart';
import '../../../dto/leave_request_dto.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [ILeaveRepository] فوق جدول `public.leave_requests` عبر
/// Supabase. 🆕 إشعار تقديم/اعتماد الطلب يُطلَق تلقائياً من الخادم عبر
/// Edge Function `leave-request-notify` (Database Webhook، Prompt 04).
class LeaveRepositoryImpl implements ILeaveRepository {
  LeaveRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  @override
  Future<ResultOf<LeaveRequest>> getLeaveRequestById(String leaveRequestId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableLeaveRequests)
          .select()
          .eq('id', leaveRequestId)
          .single();
      return Right<Failure, LeaveRequest>(LeaveRequestDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, LeaveRequest>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<LeaveRequest>>> getUserLeaveRequests(String userId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableLeaveRequests)
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false);

      return Right<Failure, List<LeaveRequest>>(
        rows
            .map((Map<String, dynamic> row) => LeaveRequestDto.fromJson(row).toEntity())
            .toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<LeaveRequest>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<LeaveRequest>>> getOverlappingLeaveRequests({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // تداخل زمني كلاسيكي: existing.start <= newEnd AND existing.end >= newStart،
      // مع استثناء الطلبات المرفوضة/الملغاة من نتيجة التداخل صراحة
      // (كما ينص عقد [ILeaveRepository.getOverlappingLeaveRequests]).
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableLeaveRequests)
          .select()
          .eq('user_id', userId)
          .lte('start_date', endDate.toIso8601String().split('T').first)
          .gte('end_date', startDate.toIso8601String().split('T').first)
          .inFilter('status', <String>['pending', 'approved']);

      return Right<Failure, List<LeaveRequest>>(
        rows
            .map((Map<String, dynamic> row) => LeaveRequestDto.fromJson(row).toEntity())
            .toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<LeaveRequest>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<LeaveRequest>>> getCompanyLeaveRequests(
    String companyId,
  ) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableLeaveRequests)
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return Right<Failure, List<LeaveRequest>>(
        rows
            .map((Map<String, dynamic> row) => LeaveRequestDto.fromJson(row).toEntity())
            .toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<LeaveRequest>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<LeaveRequest>> requestLeave(LeaveRequest request) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableLeaveRequests)
          .insert(LeaveRequestDto.fromEntity(request).toInsertJson())
          .select()
          .single();
      return Right<Failure, LeaveRequest>(LeaveRequestDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, LeaveRequest>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<LeaveRequest>> reviewLeave({
    required String leaveRequestId,
    required bool approve,
    required String reviewerId,
    String? reviewNote,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableLeaveRequests)
          .update(<String, dynamic>{
            'status': approve ? 'approved' : 'rejected',
            'reviewed_by': reviewerId,
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
            'review_note': reviewNote,
          })
          .eq('id', leaveRequestId)
          .select()
          .single();
      return Right<Failure, LeaveRequest>(LeaveRequestDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, LeaveRequest>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
