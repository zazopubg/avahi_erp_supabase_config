import '../../../core/errors/failure.dart';
import '../../entities/audit_log.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase جلب سجل تدقيق عابر لكل الشركات — يغذّي
/// `audit_logs_viewer.dart`. 🆕 (Prompt 28)
class GetAllAuditLogsUsecase {
  const GetAllAuditLogsUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<List<AuditLog>>> call({
    String? companyId,
    String? action,
    String? tableName,
    int limit = 200,
  }) {
    return _repository.getAllAuditLogs(
      companyId: companyId,
      action: action,
      tableName: tableName,
      limit: limit,
    );
  }
}
