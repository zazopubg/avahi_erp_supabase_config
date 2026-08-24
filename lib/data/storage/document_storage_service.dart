import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failure.dart';
import '../cloud/supabase/supabase_client_provider.dart';
import '../cloud/supabase/supabase_error_mapper.dart';
import 'storage_path_builder.dart';

/// خدمة رفع/حذف/توليد روابط المستندات الرسمية (`bucketDocuments`) في
/// Supabase Storage. تُنتج فقط مسار التخزين النهائي؛ إنشاء صف
/// `public.documents` الوصفي المطابق (بما يشمل ترقيم الإصدارات عبر
/// [Document.previousVersionId]) هو مسؤولية
/// `DocumentRepositoryImpl.uploadDocument` (`features/documents/`،
/// Prompt 21).
class DocumentStorageService {
  DocumentStorageService({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  sb.StorageFileApi get _bucket => _client.storage.from(ApiConstants.bucketDocuments);

  /// يرفع مستنداً ويُعيد `storage_path` النهائي عند النجاح. إصدار
  /// جديد لمستند قائم (Version Bump) يُرفَع بمسار جديد دائماً (لا
  /// `upsert`) بحيث تبقى كل الإصدارات السابقة قابلة للوصول عبر
  /// `Document.previousVersionId`.
  Future<ResultOf<String>> uploadDocument({
    required Uint8List bytes,
    required String companyId,
    required String originalFileName,
    String? projectId,
    String contentType = 'application/octet-stream',
  }) async {
    final String path = StoragePathBuilder.documentPath(
      companyId: companyId,
      projectId: projectId,
      originalFileName: originalFileName,
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

  /// يولّد رابطاً موقّعاً مؤقتاً لتنزيل/معاينة مستند خاص، صالحاً لمدة
  /// [expiresInSeconds] ثانية (ساعة واحدة افتراضياً).
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

  /// يحذف ملف مستند فعلياً من التخزين (يُستدعى عادة فقط لتصحيح خطأ
  /// رفع؛ الأرشفة العادية عبر `IDocumentRepository.archiveDocument`
  /// لا تحذف الملف الفعلي).
  Future<ResultOf<void>> delete(String storagePath) async {
    try {
      await _bucket.remove(<String>[storagePath]);
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      return Left<Failure, void>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
