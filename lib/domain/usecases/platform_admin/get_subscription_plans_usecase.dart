import '../../../core/errors/failure.dart';
import '../../entities/subscription_plan.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase جلب كل خطط الاشتراك المتاحة — يغذّي `plans_management.dart`.
/// 🆕 (Prompt 28)
class GetSubscriptionPlansUsecase {
  const GetSubscriptionPlansUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<List<SubscriptionPlan>>> call() {
    return _repository.getSubscriptionPlans();
  }
}
