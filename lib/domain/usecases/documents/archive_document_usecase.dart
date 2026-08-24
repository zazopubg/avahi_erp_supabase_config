import '../../../core/errors/failure.dart';
import '../../repositories/i_document_repository.dart';

/// 🆕 (Prompt 21) UseCase أرشفة مستند (`isArchived = true`) دون حذف
/// ملفه الفعلي من التخزين — انظر توثيق [IDocumentRepository.archiveDocument].
class ArchiveDocumentUsecase {
  const ArchiveDocumentUsecase(this._repository);

  final IDocumentRepository _repository;

  Future<ResultOf<void>> call(String documentId) {
    return _repository.archiveDocument(documentId);
  }
}
