import '../../../core/errors/failure.dart';
import '../../entities/document.dart';
import '../../repositories/i_document_repository.dart';

/// 🆕 (Prompt 21) UseCase جلب مستندات مشروع محدد، أو مستندات الشركة
/// العامة إن تُرك [projectId] فارغاً — انظر توثيق
/// [IDocumentRepository.getDocuments].
class GetDocumentsUsecase {
  const GetDocumentsUsecase(this._repository);

  final IDocumentRepository _repository;

  Future<ResultOf<List<Document>>> call({String? projectId}) {
    return _repository.getDocuments(projectId: projectId);
  }
}
