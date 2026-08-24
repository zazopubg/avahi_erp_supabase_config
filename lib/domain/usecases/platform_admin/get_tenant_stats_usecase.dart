import '../../../core/errors/failure.dart';
import '../../entities/tenant_stats.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase جلب إحصائيات شركة واحدة مجمَّعة — يغذّي `tenant_details.dart`.
/// 🆕 (Prompt 28)
class GetTenantStatsUsecase {
  const GetTenantStatsUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<TenantStats>> call(String companyId) {
    return _repository.getTenantStats(companyId);
  }
}
