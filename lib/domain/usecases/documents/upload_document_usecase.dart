import '../../../core/errors/failure.dart';
import '../../entities/document.dart';
import '../../repositories/i_document_repository.dart';

/// 🆕 (Prompt 21) UseCase رفع مستند جديد، أو إصدار جديد لمستند قائم
/// عبر [Document.previousVersionId] — بناء صف `Document` النهائي
/// (رفع بايتات الملف نفسه أولاً عبر `DocumentStorageService`، ثم
/// تحديد [Document.version]/[Document.previousVersionId] عند ترقية
/// إصدار) مسؤولية `DocumentsCubit.uploadNewDocument`/`uploadNewVersion`
/// (`features/documents/`)؛ هذه الطبقة تتحقق فقط من صحة الحد الأدنى
/// من الحقول قبل تمرير الصف جاهزاً لـ [IDocumentRepository.uploadDocument].
class UploadDocumentUsecase {
  const UploadDocumentUsecase(this._repository);

  final IDocumentRepository _repository;

  Future<ResultOf<Document>> call(Document document) async {
    if (document.title.trim().isEmpty) {
      return const Left<Failure, Document>(
        ValidationFailure(
          message: 'عنوان المستند مطلوب.',
          code: 'documents.title_required',
        ),
      );
    }
    if (document.storagePath.trim().isEmpty) {
      return const Left<Failure, Document>(
        ValidationFailure(
          message: 'لم يكتمل رفع الملف إلى التخزين بعد.',
          code: 'documents.storage_path_missing',
        ),
      );
    }
    return _repository.uploadDocument(document);
  }
}
