import '../../core/errors/failure.dart';
import '../entities/document.dart';

/// عقد الوصول إلى المستندات الرسمية (`public.documents`).
abstract interface class IDocumentRepository {
  /// يجلب مستنداً واحداً عبر معرّفه.
  Future<ResultOf<Document>> getDocumentById(String documentId);

  /// يجلب مستندات مشروع محدد (أو مستندات الشركة العامة إن `projectId == null`).
  Future<ResultOf<List<Document>>> getDocuments({String? projectId});

  /// يرفع مستنداً جديداً، أو إصداراً جديداً لمستند قائم عبر
  /// [Document.previousVersionId].
  Future<ResultOf<Document>> uploadDocument(Document document);

  /// يؤرشف مستنداً (`isArchived = true`) دون حذفه فعلياً.
  Future<ResultOf<void>> archiveDocument(String documentId);
}
