import '../../core/errors/failure.dart';
import '../entities/audit_log.dart';
import '../entities/company.dart';
import '../entities/error_log_entry.dart';
import '../entities/platform_usage_snapshot.dart';
import '../entities/subscription_plan.dart';
import '../entities/tenant_stats.dart';
import '../entities/tenant_subscription.dart';

/// عقد الوصول إلى بيانات إدارة المنصّة (Platform Admin) — عابر لكل
/// المستأجرين، محصور بدور [UserRole.platformOwner] وحده (تُفرَض هذه
/// القاعدة فعلياً عبر RLS في Supabase + `RoleGuard`/`AppNavDestinations.platformAdmin`،
/// وليس هنا). 🆕 (Prompt 28)
///
/// ⚠️ قرار تصميم (عقد واحد مجمَّع لكل شاشات `platform_admin/`، بخلاف
/// `ICompanyRepository`/`IUserRepository` المنفصلين): كل الشاشات
/// الثمانية ضمن هذه الميزة (`admin_dashboard`/`tenants_*`/
/// `plans_management`/`billing_overview`/`usage_monitor`/`error_logs`/
/// `audit_logs_viewer`) تخدم مستخدماً واحداً بدور واحد (`platformOwner`)
/// ولوحة إدارية واحدة مترابطة — تجزئتها لعقود منفصلة (كما لكل ميزة
/// عادية أخرى) كانت ستُضيف تعقيداً بلا فائدة فعلية هنا؛ نفس القرار
/// المتّخذ فعلياً في `AnalyticsCubit`/`AnalyticsData` (Prompt 25) لأربع
/// شاشات محلّية معاً.
abstract interface class IPlatformAdminRepository {
  /// يجلب كل الشركات المسجَّلة في المنصّة (بلا أي فلترة `company_id`
  /// — عابر للمستأجرين، بخلاف `ICompanyRepository.getCurrentCompany`).
  Future<ResultOf<List<Company>>> getAllCompanies();

  /// يجلب إحصائيات مجمَّعة حقيقية لشركة واحدة (أعضاء/مشاريع/تخزين).
  Future<ResultOf<TenantStats>> getTenantStats(String companyId);

  /// ينشئ شركة (مستأجر) جديدة عبر Edge Function `create-company`
  /// (`service_role`)، مع إسناد أول مدير اختياري.
  Future<ResultOf<Company>> createTenant({
    required String name,
    required String slug,
    String? nameAr,
    String? timezone,
    String? address,
    String? phone,
    String? logoUrl,
    String? initialAdminUserId,
    String? initialAdminFullName,
  });

  /// يعطّل مستأجراً منطقياً (Soft Delete) عبر Edge Function
  /// `soft-delete-tenant` — يُعطّل الشركة وكل عضوياتها دون حذف أي صف.
  Future<ResultOf<Company>> softDeleteTenant({
    required String companyId,
    String? reason,
  });

  /// يطلب تصدير كامل بيانات شركة عبر Edge Function
  /// `export-tenant-data`، ويُعيد رابطاً موقّتاً موقَّعاً (Signed URL)
  /// لملف الأرشيف الناتج (JSON) في Supabase Storage.
  Future<ResultOf<String>> exportTenantData(String companyId);

  /// يجلب سجل تدقيق عابراً لكل الشركات (بخلاف أي سجل تدقيق مستقبلي
  /// مقتصر على شركة واحدة)، قابل للفلترة اختيارياً حسب
  /// [companyId]/[action]/[tableName]، ومحدود بعدد [limit] (الأحدث
  /// أولاً).
  Future<ResultOf<List<AuditLog>>> getAllAuditLogs({
    String? companyId,
    String? action,
    String? tableName,
    int limit = 200,
  });

  /// يجلب كل خطط الاشتراك المتاحة على مستوى المنصّة.
  Future<ResultOf<List<SubscriptionPlan>>> getSubscriptionPlans();

  /// يجلب حالة اشتراك كل المستأجرين الحاليين (شركة ↔ خطة ↔ حالة فوترة).
  Future<ResultOf<List<TenantSubscription>>> getTenantSubscriptions();

  /// يُحدّث الخطة المرتبطة بمستأجر واحد (تعديل مبسّط، بلا تكامل بوابة
  /// دفع فعلية بعد).
  Future<ResultOf<TenantSubscription>> updateTenantPlan({
    required String companyId,
    required String newPlanId,
  });

  /// يجلب لقطة حالة استخدام المنصّة الحالية (لوحة `usage_monitor.dart`).
  Future<ResultOf<PlatformUsageSnapshot>> getPlatformUsageSnapshot();

  /// يجلب أحدث سجلات الأخطاء التشغيلية على مستوى المنصّة.
  Future<ResultOf<List<ErrorLogEntry>>> getRecentErrorLogs({int limit = 50});
}
