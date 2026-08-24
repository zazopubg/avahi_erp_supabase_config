import '../../../core/errors/failure.dart';
import '../../entities/company.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase تعطيل مستأجر منطقياً (Soft Delete) — يغذّي زر التعطيل في
/// `tenant_details.dart` عبر Edge Function `soft-delete-tenant`
/// (موجودة منذ Prompt 04 لكن غير مربوطة بأي طبقة `data/`/`domain/`
/// قبل هذه الخطوة). 🆕 (Prompt 28)
class SoftDeleteTenantUsecase {
  const SoftDeleteTenantUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<Company>> call({
    required String companyId,
    String? reason,
  }) {
    return _repository.softDeleteTenant(companyId: companyId, reason: reason);
  }
}
