import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/repositories/i_equipment_repository.dart';
import '../../../dto/equipment_dto.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IEquipmentRepository] فوق جدول `public.equipment` عبر
/// Supabase. 🆕 تنبيه استحقاق الصيانة (`equipment_maintenance_due`)
/// يُطلَق تلقائياً من طرف الخادم عبر Edge Function `equipment-alert`
/// (جدولة/webhook، Prompt 04) وليس من هذه الطبقة.
class EquipmentRepositoryImpl implements IEquipmentRepository {
  EquipmentRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  @override
  Future<ResultOf<Equipment>> getEquipmentById(String equipmentId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableEquipment)
          .select()
          .eq('id', equipmentId)
          .single();
      return Right<Failure, Equipment>(EquipmentDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Equipment>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<Equipment>>> getCompanyEquipment({String? projectId}) async {
    try {
      sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
          _client.from(ApiConstants.tableEquipment).select();

      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      final List<Map<String, dynamic>> rows =
          await query.order('created_at', ascending: false);

      return Right<Failure, List<Equipment>>(
        rows.map((Map<String, dynamic> row) => EquipmentDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<Equipment>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Equipment>> assignEquipment({
    required String equipmentId,
    String? assignedTo,
    String? projectId,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableEquipment)
          .update(<String, dynamic>{
            'assigned_to': assignedTo,
            'project_id': projectId,
            'status': assignedTo == null ? 'available' : 'in_use',
          })
          .eq('id', equipmentId)
          .select()
          .single();
      return Right<Failure, Equipment>(EquipmentDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Equipment>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Equipment>> updateUsageHours({
    required String equipmentId,
    required double newUsageHours,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableEquipment)
          .update(<String, dynamic>{'usage_hours': newUsageHours})
          .eq('id', equipmentId)
          .select()
          .single();
      return Right<Failure, Equipment>(EquipmentDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Equipment>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Equipment>> updateStatus({
    required String equipmentId,
    required String statusDbValue,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableEquipment)
          .update(<String, dynamic>{'status': statusDbValue})
          .eq('id', equipmentId)
          .select()
          .single();
      return Right<Failure, Equipment>(EquipmentDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Equipment>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
