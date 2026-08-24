import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/document.dart';
import '../../../../domain/repositories/i_document_repository.dart';
import '../../../dto/document_dto.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IDocumentRepository] فوق جدول `public.documents` عبر
/// Supabase. رفع بايتات الملف نفسه مسؤولية
/// `data/storage/document_storage_service.dart`؛ هذا المستودع يتعامل
/// مع صف البيانات الوصفية فقط (بما يشمل [uploadDocument] التي تُنشئ
/// صفاً جديداً بعد اكتمال الرفع الفعلي من طرف المستدعي).
class DocumentRepositoryImpl implements IDocumentRepository {
  DocumentRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  @override
  Future<ResultOf<Document>> getDocumentById(String documentId) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableDocuments)
          .select()
          .eq('id', documentId)
          .single();
      return Right<Failure, Document>(DocumentDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Document>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<Document>>> getDocuments({String? projectId}) async {
    try {
      sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
          _client.from(ApiConstants.tableDocuments).select();

      query = projectId == null
          ? query.filter('project_id', 'is', null)
          : query.eq('project_id', projectId);

      final List<Map<String, dynamic>> rows =
          await query.order('created_at', ascending: false);

      return Right<Failure, List<Document>>(
        rows.map((Map<String, dynamic> row) => DocumentDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<Document>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Document>> uploadDocument(Document document) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(ApiConstants.tableDocuments)
          .insert(DocumentDto.fromEntity(document).toInsertJson())
          .select()
          .single();
      return Right<Failure, Document>(DocumentDto.fromJson(row).toEntity());
    } catch (error, stackTrace) {
      return Left<Failure, Document>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<void>> archiveDocument(String documentId) async {
    try {
      await _client
          .from(ApiConstants.tableDocuments)
          .update(<String, dynamic>{'is_archived': true})
          .eq('id', documentId);
      return const Right<Failure, void>(null);
    } catch (error, stackTrace) {
      return Left<Failure, void>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }
}
