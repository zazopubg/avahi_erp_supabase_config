import '../../../core/errors/failure.dart';
import '../../entities/company.dart';
import '../../repositories/i_platform_admin_repository.dart';

/// UseCase إنشاء مستأجر (شركة) جديد — يغذّي `tenant_create.dart` عبر
/// Edge Function `create-company`. 🆕 (Prompt 28)
class CreateTenantUsecase {
  const CreateTenantUsecase(this._repository);

  final IPlatformAdminRepository _repository;

  Future<ResultOf<Company>> call({
    required String name,
    required String slug,
    String? nameAr,
    String? timezone,
    String? address,
    String? phone,
    String? logoUrl,
    String? initialAdminUserId,
    String? initialAdminFullName,
  }) {
    return _repository.createTenant(
      name: name,
      slug: slug,
      nameAr: nameAr,
      timezone: timezone,
      address: address,
      phone: phone,
      logoUrl: logoUrl,
      initialAdminUserId: initialAdminUserId,
      initialAdminFullName: initialAdminFullName,
    );
  }
}
