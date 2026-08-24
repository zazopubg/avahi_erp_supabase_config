import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failure.dart';
import '../cloud/supabase/supabase_client_provider.dart';
import '../cloud/supabase/supabase_error_mapper.dart';
import 'storage_path_builder.dart';

/// خدمة رفع/توليد روابط التوقيعات الرقمية (`bucketSignatures`) في
/// Supabase Storage. 🆕 تُنتج فقط مسار/رابط التوقيع؛ ربط الرابط
/// بحقلَي `field_reports.supervisor_signature_url`/
/// `client_signature_url` يتم عبر
/// `ReportRepositoryImpl.attachSignature` (`features/field_reports/`،
/// Prompt 17).
class SignatureStorageService {
  SignatureStorageService({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  sb.StorageFileApi get _bucket => _client.storage.from(ApiConstants.bucketSignatures);

  /// يرفع صورة توقيع رقمي (عادةً PNG بخلفية شفافة صادرة من لوحة رسم
  /// التوقيع في الواجهة) ويُعيد `storage_path` النهائي عند النجاح.
  Future<ResultOf<String>> uploadSignature({
    required Uint8List bytes,
    required String companyId,
    required String projectId,
    required String reportId,
    required String signerRole, // 'supervisor' أو 'client'
    String contentType = 'image/png',
  }) async {
    final String path = StoragePathBuilder.signaturePath(
      companyId: companyId,
      projectId: projectId,
      reportId: reportId,
      signerRole: signerRole,
    );

    try {
      await _bucket.uploadBinary(
        path,
        bytes,
        fileOptions: sb.FileOptions(contentType: contentType),
      );
      return Right<Failure, String>(path);
    } catch (error, stackTrace) {
      return Left<Failure, String>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  /// يولّد رابطاً موقّعاً مؤقتاً لعرض توقيع (يُستخدم عند طباعة/تصدير
  /// التقرير كـ PDF لاحقاً)، صالحاً لمدة [expiresInSeconds] ثانية.
  Future<ResultOf<String>> getSignedUrl(
    String storagePath, {
    int expiresInSeconds = 3600,
  }) async {
    try {
      final String url = await _bucket.createSignedUrl(storagePath, expiresInSeconds);
      return Right<Failure, String>(url);
    } catch (error, stackTrace) {
      return Left<Failure, String>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
