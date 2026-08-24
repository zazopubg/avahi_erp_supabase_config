import '../../../core/errors/failure.dart';
import '../../entities/error_log_entry.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase جلب أحدث سجلات الأخطاء التشغيلية — يغذّي `error_logs.dart`.
/// 🆕 (Prompt 28)
class GetRecentErrorLogsUsecase {
  const GetRecentErrorLogsUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<List<ErrorLogEntry>>> call({int limit = 50}) {
    return _repository.getRecentErrorLogs(limit: limit);
  }
}
