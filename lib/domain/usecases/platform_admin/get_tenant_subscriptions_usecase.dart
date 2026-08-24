import '../../../core/errors/failure.dart';
import '../../entities/tenant_subscription.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase جلب اشتراكات كل المستأجرين — يغذّي `billing_overview.dart`.
/// 🆕 (Prompt 28)
class GetTenantSubscriptionsUsecase {
  const GetTenantSubscriptionsUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<List<TenantSubscription>>> call() {
    return _repository.getTenantSubscriptions();
  }
}
