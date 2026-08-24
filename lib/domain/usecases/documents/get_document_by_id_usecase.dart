import '../../../core/errors/failure.dart';
import '../../entities/document.dart';
import '../../repositories/i_document_repository.dart';

/// 🆕 (Prompt 21) UseCase جلب مستند واحد عبر معرّفه — تُستخدم عند
/// الدخول المباشر (Deep Link) لمسار `/documents/:id`
/// (`document_viewer.dart`) دون المرور أولاً بقائمة المستندات
/// المُحمَّلة مسبقاً في `DocumentsCubit`.
class GetDocumentByIdUsecase {
  const GetDocumentByIdUsecase(this._repository);

  final IDocumentRepository _repository;

  Future<ResultOf<Document>> call(String documentId) {
    return _repository.getDocumentById(documentId);
  }
}
