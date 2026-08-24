import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/attendance_record.dart';
import '../../../../domain/repositories/i_attendance_repository.dart';
import '../../../dto/attendance_dto.dart';
import '../realtime/attendance_subscription.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IAttendanceRepository] فوق Edge Function `attendance-guard`
/// (وليس عبر إدراج/تحديث مباشر على `public.attendance`).
///
/// ⚠️ قرار معماري مهم: طلب هذه الخطوة نصّ على "استخدم upsert بـ
/// on-conflict-do-nothing على client_mutation_id لضمان idempotency"،
/// لكن هذا المنطق (upsert + onConflict: client_mutation_id +
/// ignoreDuplicates) **مُطبَّق فعلياً داخل** `attendance-guard`
/// (انظر `backend/supabase/functions/attendance-guard/index.ts`،
/// Prompt 04) لأنه يحتاج أيضاً حساب الجيوفنسينغ (Haversine) ومنع
/// الطوابع الزمنية المستقبلية، وهو منطق خادمي لا يمكن (ولا يجب) تكراره
/// بأمان على العميل. لذا `checkIn`/`checkOut` هنا يستدعيان الدالة
/// مباشرة، محقّقين idempotency الفعلي دون تكرار منطق upsert جزئياً
/// وبشكل غير آمن على العميل.
class AttendanceRepositoryImpl implements IAttendanceRepository {
  AttendanceRepositoryImpl({
    sb.SupabaseClient? client,
    AttendanceSubscription? subscription,
  })  : _client = client ?? SupabaseClientProvider.client,
        _subscription = subscription ?? AttendanceSubscription();

  final sb.SupabaseClient _client;
  final AttendanceSubscription _subscription;

  @override
  Future<ResultOf<AttendanceRecord>> checkIn(AttendanceRecord record) async {
    try {
      final sb.FunctionResponse response = await _client.functions.invoke(
        ApiConstants.fnAttendanceGuard,
        body: <String, dynamic>{
          'action': 'check_in',
          'project_id': record.projectId,
          'client_mutation_id': record.clientMutationId,
          'latitude': record.checkInLatitude,
          'longitude': record.checkInLongitude,
          'check_method': record.checkMethod.dbValue,
          if (record.qrCodeId != null) 'qr_code_id': record.qrCodeId,
          'occurred_at': record.checkInAt.toIso8601String(),
        },
      );
      return _parseAttendanceEnvelope(response);
    } catch (error, stackTrace) {
      return Left<Failure, AttendanceRecord>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<AttendanceRecord>> checkOut({
    required String attendanceId,
    required DateTime checkOutAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
  }) async {
    try {
      final sb.FunctionResponse response = await _client.functions.invoke(
        ApiConstants.fnAttendanceGuard,
        body: <String, dynamic>{
          'action': 'check_out',
          'attendance_id': attendanceId,
          'latitude': checkOutLatitude,
          'longitude': checkOutLongitude,
          'occurred_at': checkOutAt.toIso8601String(),
        },
      );
      return _parseAttendanceEnvelope(response);
    } catch (error, stackTrace) {
      return Left<Failure, AttendanceRecord>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<AttendanceRecord?>> getTodayAttendance({
    required String userId,
    required String projectId,
  }) async {
    try {
      final DateTime now = DateTime.now().toUtc();
      final DateTime startOfDay = DateTime.utc(now.year, now.month, now.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      final Map<String, dynamic>? row = await _client
          .from(ApiConstants.tableAttendance)
          .select()
          .eq('user_id', userId)
          .eq('project_id', projectId)
          .gte('check_in_at', startOfDay.toIso8601String())
          .lt('check_in_at', endOfDay.toIso8601String())
          .order('check_in_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return const Right<Failure, AttendanceRecord?>(null);
      return Right<Failure, AttendanceRecord?>(AttendanceDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, AttendanceRecord?>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<String>> resolveProjectFromQrCode(String qrCodeId) async {
    try {
      // ⚠️ لا يوجد بعد جدول مخصّص لأكواد QR الثابتة في المخطط الحالي
      // (`backend/supabase/migrations/`، Prompt 03/04)؛ الاصطلاح
      // المعتمد هنا هو ترميز معرّف المشروع مباشرة داخل رمز الـQR
      // بالصيغة `avahi:project:<project_id>` عند توليده (لوحة الموقع
      // الثابتة، Prompt 15)، فيُستخرج معرّف المشروع محلياً ثم يُتحقّق
      // من وجوده الفعلي في قاعدة البيانات قبل قبوله.
      const String prefix = 'avahi:project:';
      if (!qrCodeId.startsWith(prefix)) {
        return const Left<Failure, String>(
          NetworkFailure(
            message: 'رمز QR غير صالح أو لا يخص Avahi.',
            code: 'attendance.invalid_qr_code',
          ),
        );
      }

      final String projectId = qrCodeId.substring(prefix.length);
      final Map<String, dynamic>? project = await _client
          .from(ApiConstants.tableProjects)
          .select('id')
          .eq('id', projectId)
          .maybeSingle();

      if (project == null) {
        return const Left<Failure, String>(
          NetworkFailure(
            message: 'المشروع المرتبط برمز QR هذا غير موجود.',
            code: 'attendance.qr_project_not_found',
          ),
        );
      }

      return Right<Failure, String>(project['id'] as String);
    } catch (error, stackTrace) {
      return Left<Failure, String>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<AttendanceRecord>> reviewAttendance({
    required String attendanceId,
    required bool approve,
    required String reviewerId,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableAttendance)
          .update(<String, dynamic>{
            'status': approve ? 'approved' : 'rejected',
            'approved_by': reviewerId,
            'approved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', attendanceId)
          .select()
          .single();
      return Right<Failure, AttendanceRecord>(AttendanceDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, AttendanceRecord>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<AttendanceRecord>>> getMyHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableAttendance)
          .select()
          .eq('user_id', userId)
          .gte('check_in_at', from.toUtc().toIso8601String())
          .lte('check_in_at', to.toUtc().toIso8601String())
          .order('check_in_at', ascending: false);

      return Right<Failure, List<AttendanceRecord>>(
        rows.map((Map<String, dynamic> row) => AttendanceDto.fromJson(row).toEntity()).toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<AttendanceRecord>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<AttendanceRecord>>> getProjectAttendance({
    required String projectId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableAttendance)
          .select()
          .eq('project_id', projectId)
          .gte('check_in_at', from.toUtc().toIso8601String())
          .lte('check_in_at', to.toUtc().toIso8601String())
          .order('check_in_at', ascending: false);

      return Right<Failure, List<AttendanceRecord>>(
        rows.map((Map<String, dynamic> row) => AttendanceDto.fromJson(row).toEntity()).toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<AttendanceRecord>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Stream<AttendanceRecord> watchProjectAttendance(String projectId) {
    return _subscription.watchProjectAttendance(projectId);
  }

  /// يفكّ استجابة `attendance-guard` الموحّدة
  /// (`{success, data: {attendance, idempotent_replay}}`) إلى
  /// [AttendanceRecord]، أو [Failure] عند `success: false` (حالة
  /// نادرة إن لم يرمِ `functions.invoke` استثناءً تلقائياً).
  ResultOf<AttendanceRecord> _parseAttendanceEnvelope(sb.FunctionResponse response) {
    final Object? data = response.data;
    if (data is! Map) {
      return const Left<Failure, AttendanceRecord>(
        NetworkFailure(
          message: 'استجابة غير متوقعة من دالة تسجيل الحضور.',
          code: 'attendance.invalid_response',
        ),
      );
    }
    final Map<String, dynamic> envelope = data.cast<String, dynamic>();

    if (envelope['success'] != true) {
      final Map<String, dynamic>? error =
          (envelope['error'] as Map?)?.cast<String, dynamic>();
      return Left<Failure, AttendanceRecord>(
        NetworkFailure(
          message: error?['message']?.toString() ?? 'فشل تسجيل الحضور.',
          code: 'attendance.${error?['code'] ?? 'unknown'}',
        ),
      );
    }

    final Map<String, dynamic> payload =
        (envelope['data'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> attendanceJson =
        (payload['attendance'] as Map).cast<String, dynamic>();
    return Right<Failure, AttendanceRecord>(
      AttendanceDto.fromJson(attendanceJson).toEntity(),
    );
  }
}
