import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failure.dart';
import '../cloud/supabase/supabase_client_provider.dart';
import '../cloud/supabase/supabase_error_mapper.dart';
import 'storage_path_builder.dart';

/// خدمة رفع/حذف/توليد روابط صور الموقع (`bucketPhotos`) في Supabase
/// Storage. تُنتج فقط مسار التخزين النهائي (`storage_path`)؛ إنشاء
/// صف `public.photos` الوصفي المطابق هو مسؤولية
/// `PhotoRepositoryImpl.uploadPhoto` (تُستدعى بعد نجاح هذا الرفع من
/// طبقة `presentation/features/photos/`، Prompt 18).
///
/// ⚠️ يُفترَض أن `bucketPhotos` مخزن **خاص** (Private) محميّ بسياسات
/// RLS على مستوى `storage.objects` (تُضاف لاحقاً عند تفعيلها فعلياً
/// في لوحة Supabase أو هجرة مخصصة)؛ لذا [getSignedUrl] تُستخدم لعرض
/// الصور بدل الاعتماد على رابط عام دائم.
class PhotoStorageService {
  PhotoStorageService({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  sb.StorageFileApi get _bucket => _client.storage.from(ApiConstants.bucketPhotos);

  /// يرفع صورة أصل ويُعيد `storage_path` النهائي عند النجاح.
  Future<ResultOf<String>> uploadPhoto({
    required Uint8List bytes,
    required String companyId,
    required String projectId,
    required String relatedEntityId,
    required String originalFileName,
    String contentType = 'image/jpeg',
  }) async {
    final String path = StoragePathBuilder.photoPath(
      companyId: companyId,
      projectId: projectId,
      relatedEntityId: relatedEntityId,
      originalFileName: originalFileName,
    );
    return _upload(path: path, bytes: bytes, contentType: contentType);
  }

  /// يرفع نسخة مصغّرة (Thumbnail) مطابقة لصورة أصل مرفوعة مسبقاً عبر
  /// [uploadPhoto] — يُمرَّر [originalStoragePath] الناتج منها لضمان
  /// وجود المصغّرة في نفس المجلد.
  Future<ResultOf<String>> uploadThumbnail({
    required Uint8List bytes,
    required String originalStoragePath,
    String contentType = 'image/jpeg',
  }) async {
    final String path = StoragePathBuilder.photoThumbnailPath(originalStoragePath);
    return _upload(path: path, bytes: bytes, contentType: contentType);
  }

  /// يولّد رابطاً موقّعاً (Signed URL) مؤقتاً لعرض صورة خاصة، صالحاً
  /// لمدة [expiresInSeconds] ثانية (ساعة واحدة افتراضياً).
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

  /// يحذف ملفاً واحداً أو أكثر (صورة أصل + مصغّرتها مثلاً) دفعة واحدة.
  Future<ResultOf<void>> deleteAll(List<String> storagePaths) async {
    try {
      await _bucket.remove(storagePaths);
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      return Left<Failure, void>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  Future<ResultOf<String>> _upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
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
}
