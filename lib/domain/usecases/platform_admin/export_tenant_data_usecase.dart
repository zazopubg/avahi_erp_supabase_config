import '../../../core/errors/failure.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase تصدير كامل بيانات مستأجر — يغذّي `tenant_data_export.dart`
/// عبر Edge Function جديدة `export-tenant-data` 🆕 (Prompt 28)، ويُعيد
/// رابطاً موقّتاً موقَّعاً لملف الأرشيف الناتج.
class ExportTenantDataUsecase {
  const ExportTenantDataUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<String>> call(String companyId) {
    return _repository.exportTenantData(companyId);
  }
}
