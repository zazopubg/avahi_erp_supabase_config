import 'dart:async' show unawaited;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/audit_log.dart';
import '../../../../domain/entities/company.dart';
import '../../../../domain/entities/error_log_entry.dart';
import '../../../../domain/entities/platform_usage_snapshot.dart';
import '../../../../domain/entities/subscription_plan.dart';
import '../../../../domain/entities/tenant_stats.dart';
import '../../../../domain/entities/tenant_subscription.dart';
import '../../../../domain/usecases/platform_admin/create_tenant_usecase.dart';
import '../../../../domain/usecases/platform_admin/export_tenant_data_usecase.dart';
import '../../../../domain/usecases/platform_admin/get_all_audit_logs_usecase.dart';
import '../../../../domain/usecases/platform_admin/get_all_companies_usecase.dart';
import '../../../../domain/usecases/platform_admin/get_platform_usage_snapshot_usecase.dart';
import '../../../../domain/usecases/platform_admin/get_recent_error_logs_usecase.dart';
import '../../../../domain/usecases/platform_admin/get_subscription_plans_usecase.dart';
import '../../../../domain/usecases/platform_admin/get_tenant_stats_usecase.dart';
import '../../../../domain/usecases/platform_admin/get_tenant_subscriptions_usecase.dart';
import '../../../../domain/usecases/platform_admin/soft_delete_tenant_usecase.dart';
import '../../../../domain/usecases/platform_admin/update_tenant_plan_usecase.dart';
import 'platform_admin_state.dart';

/// `Cubit` ميزة `features/platform_admin/` كاملة — يقود شاشة
/// `admin_dashboard.dart` الوحيدة وكل ألسنتها الست (نظرة عامة/
/// المستأجرون/الاشتراكات/الفوترة/المراقبة/الأخطاء/سجل التدقيق) عبر
/// [PlatformAdminData] واحدة مجمّعة، بنفس فلسفة `AnalyticsCubit`
/// (Prompt 25) تماماً. 🆕 (Prompt 28)
class PlatformAdminCubit extends Cubit<PlatformAdminState> {
  PlatformAdminCubit({
    required GetAllCompaniesUsecase getAllCompaniesUsecase,
    required GetTenantStatsUsecase getTenantStatsUsecase,
    required CreateTenantUsecase createTenantUsecase,
    required SoftDeleteTenantUsecase softDeleteTenantUsecase,
    required ExportTenantDataUsecase exportTenantDataUsecase,
    required GetAllAuditLogsUsecase getAllAuditLogsUsecase,
    required GetSubscriptionPlansUsecase getSubscriptionPlansUsecase,
    required GetTenantSubscriptionsUsecase getTenantSubscriptionsUsecase,
    required UpdateTenantPlanUsecase updateTenantPlanUsecase,
    required GetPlatformUsageSnapshotUsecase getPlatformUsageSnapshotUsecase,
    required GetRecentErrorLogsUsecase getRecentErrorLogsUsecase,
  })  : _getAllCompaniesUsecase = getAllCompaniesUsecase,
        _getTenantStatsUsecase = getTenantStatsUsecase,
        _createTenantUsecase = createTenantUsecase,
        _softDeleteTenantUsecase = softDeleteTenantUsecase,
        _exportTenantDataUsecase = exportTenantDataUsecase,
        _getAllAuditLogsUsecase = getAllAuditLogsUsecase,
        _getSubscriptionPlansUsecase = getSubscriptionPlansUsecase,
        _getTenantSubscriptionsUsecase = getTenantSubscriptionsUsecase,
        _updateTenantPlanUsecase = updateTenantPlanUsecase,
        _getPlatformUsageSnapshotUsecase = getPlatformUsageSnapshotUsecase,
        _getRecentErrorLogsUsecase = getRecentErrorLogsUsecase,
        super(const PlatformAdminLoading());

  final GetAllCompaniesUsecase _getAllCompaniesUsecase;
  final GetTenantStatsUsecase _getTenantStatsUsecase;
  final CreateTenantUsecase _createTenantUsecase;
  final SoftDeleteTenantUsecase _softDeleteTenantUsecase;
  final ExportTenantDataUsecase _exportTenantDataUsecase;
  final GetAllAuditLogsUsecase _getAllAuditLogsUsecase;
  final GetSubscriptionPlansUsecase _getSubscriptionPlansUsecase;
  final GetTenantSubscriptionsUsecase _getTenantSubscriptionsUsecase;
  final UpdateTenantPlanUsecase _updateTenantPlanUsecase;
  final GetPlatformUsageSnapshotUsecase _getPlatformUsageSnapshotUsecase;
  final GetRecentErrorLogsUsecase _getRecentErrorLogsUsecase;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى عند دخول `admin_dashboard.dart` (نقطة الدخول الوحيدة
  /// لمسار `RouteNames.platformAdmin`) — يجلب كل شيء دفعة واحدة عبر
  /// `Future.wait` (بنفس نمط تحميل `AnalyticsCubit.loadInitial`)
  /// باستثناء إحصائيات المستأجر الواحد ([TenantStats]، تحميل كسول عبر
  /// [loadTenantStats] فقط عند فتح `tenant_details.dart` فعلياً).
  Future<void> loadInitial(AppUser user) async {
    emit(const PlatformAdminLoading());

    // ⚠️ الاستدعاءات الستة أدناه تُطلَق متزامنة عمداً (Futures تبدأ
    // تنفيذها فوراً عند إنشائها في Dart، لا عند `await`ها)، ثم تُنتظَر
    // بأنواعها الصريحة كلٌّ على حدة — بدل `Future.wait<Object>` بأنواع
    // مختلطة تتطلب `as` غير آمن لاحقاً، بنفس القرار الموثَّق فعلياً في
    // `AnalyticsCubit._loadProjectAggregates` تماماً.
    final Future<ResultOf<List<Company>>> companiesFuture =
        _getAllCompaniesUsecase();
    final Future<ResultOf<List<SubscriptionPlan>>> plansFuture =
        _getSubscriptionPlansUsecase();
    final Future<ResultOf<List<TenantSubscription>>> subscriptionsFuture =
        _getTenantSubscriptionsUsecase();
    final Future<ResultOf<PlatformUsageSnapshot>> usageFuture =
        _getPlatformUsageSnapshotUsecase();
    final Future<ResultOf<List<ErrorLogEntry>>> errorLogsFuture =
        _getRecentErrorLogsUsecase();
    final Future<ResultOf<List<AuditLog>>> auditLogsFuture =
        _getAllAuditLogsUsecase();

    final ResultOf<List<Company>> companiesResult = await companiesFuture;
    final ResultOf<List<SubscriptionPlan>> plansResult = await plansFuture;
    final ResultOf<List<TenantSubscription>> subscriptionsResult =
        await subscriptionsFuture;
    final ResultOf<PlatformUsageSnapshot> usageResult = await usageFuture;
    final ResultOf<List<ErrorLogEntry>> errorLogsResult =
        await errorLogsFuture;
    final ResultOf<List<AuditLog>> auditLogsResult = await auditLogsFuture;

    // ⚠️ قرار تصميم (الشركات وحدها حاسمة، البقية اختيارية): فشل جلب
    // [companiesResult] وحده يُظهر `PlatformAdminError` كاملة (لا معنى
    // لعرض لوحة بلا قائمة مستأجرين أصلاً — كل الألسنة الأخرى تعتمد
    // عليها)، بينما فشل أي من الأربعة الأخرى (مثال: مصدر تجريبي معطَّل
    // مستقبلاً) يُستبدَل بقائمة/لقطة فارغة بدل حجب اللوحة كاملة —
    // بنفس فلسفة "تحميل جزئي أفضل من لا شيء" غير المطبَّقة صراحة في
    // ميزات سابقة أبسط (`UsersCubit`) لكنها مناسبة هنا لعدد مصادر
    // البيانات الخمسة المستقلة.
    companiesResult.fold(
      (Failure failure) => emit(PlatformAdminError(failure)),
      (List<Company> companies) {
        emit(
          PlatformAdminLoaded(
            PlatformAdminData(
              currentUser: user,
              companies: companies,
              plans: plansResult.fold(
                (Failure _) => const <SubscriptionPlan>[],
                (List<SubscriptionPlan> p) => p,
              ),
              subscriptions: subscriptionsResult.fold(
                (Failure _) => const <TenantSubscription>[],
                (List<TenantSubscription> s) => s,
              ),
              usageSnapshot: usageResult.fold(
                (Failure _) => null,
                (PlatformUsageSnapshot u) => u,
              ),
              errorLogs: errorLogsResult.fold(
                (Failure _) => const <ErrorLogEntry>[],
                (List<ErrorLogEntry> e) => e,
              ),
              auditLogs: auditLogsResult.fold(
                (Failure _) => const <AuditLog>[],
                (List<AuditLog> a) => a,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> refresh() async {
    final PlatformAdminData? current = state.dataOrNull;
    if (current == null) return;
    emit(PlatformAdminLoaded(current.copyWith(isRefreshing: true)));
    await loadInitial(current.currentUser);
  }

  // ── المستأجرون (`tenants_list.dart`/`tenant_details.dart`) ─────────

  void selectCompany(Company? company) {
    final PlatformAdminData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      PlatformAdminLoaded(
        company == null
            ? current.copyWith(clearSelectedCompany: true)
            : current.copyWith(selectedCompanyId: company.id),
      ),
    );
    if (company != null && !current.tenantStats.containsKey(company.id)) {
      unawaited(loadTenantStats(company.id));
    }
  }

  /// يجلب [TenantStats] لشركة واحدة عند فتح `tenant_details.dart` أول
  /// مرة، ويُخزّنها ضمن [PlatformAdminData.tenantStats] لتفادي إعادة
  /// الجلب عند كل فتح لاحق لنفس الشركة خلال نفس الجلسة.
  Future<void> loadTenantStats(String companyId) async {
    final PlatformAdminData? current = state.dataOrNull;
    if (current == null) return;

    emit(PlatformAdminLoaded(current.copyWith(isLoadingTenantStats: true)));

    final ResultOf<TenantStats> result = await _getTenantStatsUsecase(companyId);

    final PlatformAdminData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) => emit(
        PlatformAdminLoaded(latest.copyWith(isLoadingTenantStats: false)),
      ),
      (TenantStats stats) => emit(
        PlatformAdminLoaded(
          latest.copyWith(
            tenantStats: <String, TenantStats>{
              ...latest.tenantStats,
              companyId: stats,
            },
            isLoadingTenantStats: false,
          ),
        ),
      ),
    );
  }

  /// ينشئ مستأجراً جديداً — `tenant_create.dart`.
  Future<Company?> createTenant({
    required String name,
    required String slug,
    String? nameAr,
    String? timezone,
    String? address,
    String? phone,
    String? initialAdminUserId,
    String? initialAdminFullName,
  }) async {
    final PlatformAdminData? current = state.dataOrNull;
    if (current == null) return null;

    emit(
      PlatformAdminLoaded(
        current.copyWith(
          isCreatingTenant: true,
          clearCreateTenantErrorMessage: true,
        ),
      ),
    );

    final ResultOf<Company> result = await _createTenantUsecase(
      name: name,
      slug: slug,
      nameAr: nameAr,
      timezone: timezone,
      address: address,
      phone: phone,
      initialAdminUserId: initialAdminUserId,
      initialAdminFullName: initialAdminFullName,
    );

    final PlatformAdminData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure failure) {
        emit(
          PlatformAdminLoaded(
            latest.copyWith(
              isCreatingTenant: false,
              createTenantErrorMessage: failure.message,
            ),
          ),
        );
        return null;
      },
      (Company created) {
        emit(
          PlatformAdminLoaded(
            latest.copyWith(
              companies: <Company>[created, ...latest.companies],
              isCreatingTenant: false,
              clearCreateTenantErrorMessage: true,
            ),
          ),
        );
        return created;
      },
    );
  }

  /// يعطّل مستأجراً منطقياً (Soft Delete) — زر في `tenant_details.dart`.
  Future<bool> softDeleteTenant({
    required String companyId,
    String? reason,
  }) async {
    final PlatformAdminData? current = state.dataOrNull;
    if (current == null) return false;

    emit(
      PlatformAdminLoaded(current.copyWith(deactivatingCompanyId: companyId)),
    );

    final ResultOf<Company> result = await _softDeleteTenantUsecase(
      companyId: companyId,
      reason: reason,
    );

    final PlatformAdminData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(
          PlatformAdminLoaded(
            latest.copyWith(clearDeactivatingCompanyId: true),
          ),
        );
        return false;
      },
      (Company updated) {
        emit(
          PlatformAdminLoaded(
            latest.copyWith(
              companies: <Company>[
                for (final Company c in latest.companies)
                  if (c.id == updated.id) updated else c,
              ],
              clearDeactivatingCompanyId: true,
            ),
          ),
        );
        return true;
      },
    );
  }

  /// يطلب تصدير كامل بيانات مستأجر — `tenant_data_export.dart`. يُعيد
  /// رابط التنزيل الموقّع مباشرة (بالإضافة لتخزينه ضمن الحالة) كي
  /// تستطيع الشاشة فتحه فوراً دون انتظار إعادة بناء إضافية.
  Future<String?> exportTenantData(String companyId) async {
    final PlatformAdminData? current = state.dataOrNull;
    if (current == null) return null;

    emit(
      PlatformAdminLoaded(current.copyWith(exportingCompanyId: companyId)),
    );

    final ResultOf<String> result = await _exportTenantDataUsecase(companyId);

    final PlatformAdminData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(
          PlatformAdminLoaded(latest.copyWith(clearExportingCompanyId: true)),
        );
        return null;
      },
      (String url) {
        emit(
          PlatformAdminLoaded(
            latest.copyWith(
              clearExportingCompanyId: true,
              lastExportUrl: url,
              lastExportCompanyId: companyId,
            ),
          ),
        );
        return url;
      },
    );
  }

  // ── الاشتراكات/الفوترة (`plans_management.dart`/`billing_overview.dart`) ──

  Future<bool> updateTenantPlan({
    required String companyId,
    required String newPlanId,
  }) async {
    final PlatformAdminData? current = state.dataOrNull;
    if (current == null) return false;

    emit(PlatformAdminLoaded(current.copyWith(isSavingPlan: true)));

    final ResultOf<TenantSubscription> result = await _updateTenantPlanUsecase(
      companyId: companyId,
      newPlanId: newPlanId,
    );

    final PlatformAdminData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(PlatformAdminLoaded(latest.copyWith(isSavingPlan: false)));
        return false;
      },
      (TenantSubscription updated) {
        final bool exists = latest.subscriptions
            .any((TenantSubscription s) => s.companyId == companyId);
        emit(
          PlatformAdminLoaded(
            latest.copyWith(
              subscriptions: <TenantSubscription>[
                for (final TenantSubscription s in latest.subscriptions)
                  if (s.companyId == companyId) updated else s,
                if (!exists) updated,
              ],
              isSavingPlan: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── سجل التدقيق (`audit_logs_viewer.dart`) ──────────────────────────

  Future<void> setAuditLogFilters({
    String? companyId,
    bool clearCompanyId = false,
    String? action,
    bool clearAction = false,
    String? tableName,
    bool clearTableName = false,
  }) async {
    final PlatformAdminData? current = state.dataOrNull;
    if (current == null) return;

    final PlatformAdminData withFilters = current.copyWith(
      auditLogCompanyFilter: companyId,
      clearAuditLogCompanyFilter: clearCompanyId,
      auditLogActionFilter: action,
      clearAuditLogActionFilter: clearAction,
      auditLogTableFilter: tableName,
      clearAuditLogTableFilter: clearTableName,
      isLoadingAuditLogs: true,
    );
    emit(PlatformAdminLoaded(withFilters));

    final ResultOf<List<AuditLog>> result = await _getAllAuditLogsUsecase(
      companyId: withFilters.auditLogCompanyFilter,
      action: withFilters.auditLogActionFilter,
      tableName: withFilters.auditLogTableFilter,
    );

    final PlatformAdminData latest = state.dataOrNull ?? withFilters;
    result.fold(
      (Failure _) => emit(
        PlatformAdminLoaded(latest.copyWith(isLoadingAuditLogs: false)),
      ),
      (List<AuditLog> logs) => emit(
        PlatformAdminLoaded(
          latest.copyWith(auditLogs: logs, isLoadingAuditLogs: false),
        ),
      ),
    );
  }

  Future<void> clearAuditLogFilters() => setAuditLogFilters(
        clearCompanyId: true,
        clearAction: true,
        clearTableName: true,
      );
}
