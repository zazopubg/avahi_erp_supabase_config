import '../../../core/errors/failure.dart';
import '../../entities/platform_usage_snapshot.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase جلب لقطة استخدام المنصّة الحالية — يغذّي `usage_monitor.dart`.
/// 🆕 (Prompt 28)
class GetPlatformUsageSnapshotUsecase {
  const GetPlatformUsageSnapshotUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<PlatformUsageSnapshot>> call() {
    return _repository.getPlatformUsageSnapshot();
  }
}
