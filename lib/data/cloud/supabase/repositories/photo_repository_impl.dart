import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/site_photo.dart';
import '../../../../domain/enums/related_entity_type.dart';
import '../../../../domain/repositories/i_photo_repository.dart';
import '../../../dto/site_photo_dto.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IPhotoRepository] فوق جدول `public.photos` عبر Supabase.
///
/// ⚠️ رفع بايتات الملف الفعلي (اختيار/ضغط/تحديد المسار) هو مسؤولية
/// `data/storage/photo_storage_service.dart`؛ هذا المستودع يتعامل فقط
/// مع صف البيانات الوصفية بعد اكتمال الرفع، باستثناء [deletePhoto]
/// التي تحتاج حذف الملف الفعلي من `Storage Bucket` أيضاً حسب نص عقد
/// [IPhotoRepository.deletePhoto] صراحة ("يحذف الملف من التخزين
/// والسجل معاً")، لذا تصل هذه الدالة وحدها إلى `client.storage`
/// مباشرة.
class PhotoRepositoryImpl implements IPhotoRepository {
  PhotoRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  @override
  Future<ResultOf<SitePhoto>> uploadPhoto(SitePhoto photo) async {
    try {
      // ⚠️ (Prompt 18) `upsert` بدل `insert` الأصلية — يجعل الإدراج
      // *Idempotent* بحسب `id` (المُضمَّن الآن صراحة عبر
      // `SitePhotoDto.toInsertJson`، انظر توثيق القرار هناك): إعادة
      // محاولة رفع نفس الصف بعد فشل شبكي عابر (`PhotoUploadProcessor`،
      // `data/sync/outbox/`) لن تُنشئ صفاً مكرراً، بل تُحدِّث نفس الصف
      // إن كان قد نجح فعلياً في محاولة سابقة لم تصل استجابتها للجهاز.
      // لا يغيّر هذا أي سلوك ملحوظ لمسار `features/field_reports/`
      // القائم (كل استدعاء لديه `id` فريد أصلاً، فـ `upsert` يتصرف
      // كـ `insert` عادي تماماً هناك).
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tablePhotos)
          .upsert(SitePhotoDto.fromEntity(photo).toInsertJson())
          .select()
          .single();
      return Right<Failure, SitePhoto>(SitePhotoDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, SitePhoto>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<SitePhoto>>> getPhotosForEntity({
    required RelatedEntityType relatedEntityType,
    required String relatedEntityId,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tablePhotos)
          .select()
          .eq('related_entity_type', relatedEntityType.dbValue)
          .eq('related_entity_id', relatedEntityId)
          .order('taken_at', ascending: false);

      return Right<Failure, List<SitePhoto>>(
        rows.map((Map<String, dynamic> row) => SitePhotoDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<SitePhoto>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<SitePhoto>>> getPhotosForProject({
    required String projectId,
    RelatedEntityType? relatedEntityType,
    String? uploadedBy,
    int limit = 200,
  }) async {
    try {
      // نفس نمط الفلترة الاختيارية المعتمد أصلاً في `task_repository_impl.dart`/
      // `equipment_repository_impl.dart`/`document_repository_impl.dart`:
      // إعادة إسناد `query` تدريجياً فقط عند وجود كل فلتر اختياري،
      // بدل بناء شرط `PostgREST` نصي خام يدوياً.
      sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _client
          .from(ApiConstants.tablePhotos)
          .select()
          .eq('project_id', projectId);

      if (relatedEntityType != null) {
        query = query.eq('related_entity_type', relatedEntityType.dbValue);
      }
      if (uploadedBy != null) {
        query = query.eq('uploaded_by', uploadedBy);
      }

      final List<Map<String, dynamic>> rows = await query
          .order('taken_at', ascending: false)
          .limit(limit);

      return Right<Failure, List<SitePhoto>>(
        rows.map((Map<String, dynamic> row) => SitePhotoDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<SitePhoto>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<void>> deletePhoto(String photoId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tablePhotos)
          .select('storage_path, thumbnail_path')
          .eq('id', photoId)
          .single();

      final List<String> pathsToRemove = <String>[
        row['storage_path'] as String,
        if (row['thumbnail_path'] != null) row['thumbnail_path'] as String,
      ];

      await _client.storage.from(ApiConstants.bucketPhotos).remove(pathsToRemove);
      await _client.from(ApiConstants.tablePhotos).delete().eq('id', photoId);

      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      return Left<Failure, void>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
