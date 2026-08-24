import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/audit_log.dart';
import '../../../../domain/entities/company.dart';
import '../../../../domain/entities/error_log_entry.dart';
import '../../../../domain/entities/platform_usage_snapshot.dart';
import '../../../../domain/entities/subscription_plan.dart';
import '../../../../domain/entities/tenant_stats.dart';
import '../../../../domain/entities/tenant_subscription.dart';

/// حالة `PlatformAdminCubit` الكاملة — Union Type مكتوب يدوياً (بلا
/// `freezed`)، بنفس نمط `UsersState`/`AnalyticsState` تماماً: ثلاث
/// حالات فقط (`PlatformAdminLoading` / `PlatformAdminLoaded` /
/// `PlatformAdminError`). 🆕 (Prompt 28)
sealed class PlatformAdminState {
  const PlatformAdminState();

  T when<T>({
    required T Function() loading,
    required T Function(PlatformAdminData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final PlatformAdminState state = this;
    return switch (state) {
      PlatformAdminLoading() => loading(),
      PlatformAdminLoaded(:final data) => loaded(data),
      PlatformAdminError(:final failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(PlatformAdminData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  PlatformAdminData? get dataOrNull => maybeWhen<PlatformAdminData?>(
        orElse: () => null,
        loaded: (PlatformAdminData d) => d,
      );
}

/// جارٍ التحميل الأولي (الشركات + الخطط + الاشتراكات + لقطة الاستخدام
/// + الأخطاء + أول صفحة من سجل التدقيق، معاً عبر `Future.wait`).
final class PlatformAdminLoading extends PlatformAdminState {
  const PlatformAdminLoading();
}

/// جاهزة لعرض كل شاشات `platform_admin/` الثمانية معاً.
final class PlatformAdminLoaded extends PlatformAdminState {
  const PlatformAdminLoaded(this.data);

  final PlatformAdminData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً (مثال: المستخدم الحالي ليس
/// `platformOwner` فعلياً وسياسات RLS رفضت الاستعلام الأول).
final class PlatformAdminError extends PlatformAdminState {
  const PlatformAdminError(this.failure);

  final Failure failure;
}

/// حزمة بيانات لوحة إدارة المنصّة المجمّعة — يحملها [PlatformAdminLoaded]
/// وحدها.
class PlatformAdminData {
  const PlatformAdminData({
    required this.currentUser,
    this.companies = const <Company>[],
    this.tenantStats = const <String, TenantStats>{},
    this.plans = const <SubscriptionPlan>[],
    this.subscriptions = const <TenantSubscription>[],
    this.usageSnapshot,
    this.errorLogs = const <ErrorLogEntry>[],
    this.auditLogs = const <AuditLog>[],
    this.auditLogCompanyFilter,
    this.auditLogActionFilter,
    this.auditLogTableFilter,
    this.selectedCompanyId,
    this.isRefreshing = false,
    this.isLoadingTenantStats = false,
    this.isCreatingTenant = false,
    this.createTenantErrorMessage,
    this.exportingCompanyId,
    this.lastExportUrl,
    this.lastExportCompanyId,
    this.deactivatingCompanyId,
    this.isLoadingAuditLogs = false,
    this.isSavingPlan = false,
  });

  final AppUser currentUser;

  /// كل شركات المنصّة (بلا فلترة) — `admin_dashboard.dart`/
  /// `tenants_list.dart`.
  final List<Company> companies;

  /// إحصائيات مجمَّعة لكل شركة فُتحت تفاصيلها مرة واحدة على الأقل
  /// (تحميل كسول عند فتح `tenant_details.dart`، وليس دفعة واحدة لكل
  /// الشركات عند التحميل الأولي — قد تكون المنصّة تضم مئات المستأجرين).
  final Map<String, TenantStats> tenantStats;

  final List<SubscriptionPlan> plans;
  final List<TenantSubscription> subscriptions;

  /// `null` فقط أثناء [PlatformAdminLoading]؛ دائماً غير فارغة ضمن
  /// [PlatformAdminLoaded].
  final PlatformUsageSnapshot? usageSnapshot;

  final List<ErrorLogEntry> errorLogs;

  /// سجل التدقيق الحالي المعروض في `audit_logs_viewer.dart` بعد تطبيق
  /// [auditLogCompanyFilter]/[auditLogActionFilter]/[auditLogTableFilter].
  final List<AuditLog> auditLogs;
  final String? auditLogCompanyFilter;
  final String? auditLogActionFilter;
  final String? auditLogTableFilter;

  /// الشركة المختارة حالياً لعرض تفاصيلها — `tenant_details.dart`.
  final String? selectedCompanyId;

  final bool isRefreshing;
  final bool isLoadingTenantStats;

  final bool isCreatingTenant;
  final String? createTenantErrorMessage;

  /// معرّف الشركة الجارٍ تصدير بياناتها حالياً، أو `null` — يسمح لأكثر
  /// من عملية مستقبلية بالتمييز بصرياً بين شركة قيد التصدير وأخرى.
  final String? exportingCompanyId;
  final String? lastExportUrl;
  final String? lastExportCompanyId;

  /// معرّف الشركة الجارٍ تعطيلها حالياً، أو `null`.
  final String? deactivatingCompanyId;

  final bool isLoadingAuditLogs;
  final bool isSavingPlan;

  /// الشركة المختارة حالياً (تُشتق من [companies] عبر [selectedCompanyId]
  /// — بنفس منطق `UsersData.selectedMember`)، أو `null`.
  Company? get selectedCompany {
    if (selectedCompanyId == null) return null;
    for (final Company c in companies) {
      if (c.id == selectedCompanyId) return c;
    }
    return null;
  }

  /// إحصائيات [selectedCompany] إن كانت محمَّلة مسبقاً، أو `null`.
  TenantStats? get selectedCompanyStats =>
      selectedCompanyId == null ? null : tenantStats[selectedCompanyId];

  int get activeTenantsCount =>
      companies.where((Company c) => c.isActive).length;
  int get inactiveTenantsCount => companies.length - activeTenantsCount;

  /// إجمالي الإيراد الشهري المتكرر (MRR) عبر كل المستأجرين معاً —
  /// `billing_overview.dart`.
  double get totalMrrUsd =>
      subscriptions.fold<double>(0, (double sum, TenantSubscription s) => sum + s.mrrUsd);

  PlatformAdminData copyWith({
    AppUser? currentUser,
    List<Company>? companies,
    Map<String, TenantStats>? tenantStats,
    List<SubscriptionPlan>? plans,
    List<TenantSubscription>? subscriptions,
    PlatformUsageSnapshot? usageSnapshot,
    List<ErrorLogEntry>? errorLogs,
    List<AuditLog>? auditLogs,
    String? auditLogCompanyFilter,
    bool clearAuditLogCompanyFilter = false,
    String? auditLogActionFilter,
    bool clearAuditLogActionFilter = false,
    String? auditLogTableFilter,
    bool clearAuditLogTableFilter = false,
    String? selectedCompanyId,
    bool clearSelectedCompany = false,
    bool? isRefreshing,
    bool? isLoadingTenantStats,
    bool? isCreatingTenant,
    String? createTenantErrorMessage,
    bool clearCreateTenantErrorMessage = false,
    String? exportingCompanyId,
    bool clearExportingCompanyId = false,
    String? lastExportUrl,
    String? lastExportCompanyId,
    String? deactivatingCompanyId,
    bool clearDeactivatingCompanyId = false,
    bool? isLoadingAuditLogs,
    bool? isSavingPlan,
  }) {
    return PlatformAdminData(
      currentUser: currentUser ?? this.currentUser,
      companies: companies ?? this.companies,
      tenantStats: tenantStats ?? this.tenantStats,
      plans: plans ?? this.plans,
      subscriptions: subscriptions ?? this.subscriptions,
      usageSnapshot: usageSnapshot ?? this.usageSnapshot,
      errorLogs: errorLogs ?? this.errorLogs,
      auditLogs: auditLogs ?? this.auditLogs,
      auditLogCompanyFilter: clearAuditLogCompanyFilter
          ? null
          : (auditLogCompanyFilter ?? this.auditLogCompanyFilter),
      auditLogActionFilter: clearAuditLogActionFilter
          ? null
          : (auditLogActionFilter ?? this.auditLogActionFilter),
      auditLogTableFilter: clearAuditLogTableFilter
          ? null
          : (auditLogTableFilter ?? this.auditLogTableFilter),
      selectedCompanyId: clearSelectedCompany
          ? null
          : (selectedCompanyId ?? this.selectedCompanyId),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingTenantStats: isLoadingTenantStats ?? this.isLoadingTenantStats,
      isCreatingTenant: isCreatingTenant ?? this.isCreatingTenant,
      createTenantErrorMessage: clearCreateTenantErrorMessage
          ? null
          : (createTenantErrorMessage ?? this.createTenantErrorMessage),
      exportingCompanyId: clearExportingCompanyId
          ? null
          : (exportingCompanyId ?? this.exportingCompanyId),
      lastExportUrl: lastExportUrl ?? this.lastExportUrl,
      lastExportCompanyId: lastExportCompanyId ?? this.lastExportCompanyId,
      deactivatingCompanyId: clearDeactivatingCompanyId
          ? null
          : (deactivatingCompanyId ?? this.deactivatingCompanyId),
      isLoadingAuditLogs: isLoadingAuditLogs ?? this.isLoadingAuditLogs,
      isSavingPlan: isSavingPlan ?? this.isSavingPlan,
    );
  }
}
