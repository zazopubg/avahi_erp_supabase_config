import '../../../core/errors/failure.dart';
import '../../entities/tenant_subscription.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase تعديل خطة اشتراك مستأجر واحد (تعديل مبسّط) — يغذّي
/// `billing_overview.dart`/`plans_management.dart`. 🆕 (Prompt 28)
class UpdateTenantPlanUsecase {
  const UpdateTenantPlanUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<TenantSubscription>> call({
    required String companyId,
    required String newPlanId,
  }) {
    return _repository.updateTenantPlan(
      companyId: companyId,
      newPlanId: newPlanId,
    );
  }
}
