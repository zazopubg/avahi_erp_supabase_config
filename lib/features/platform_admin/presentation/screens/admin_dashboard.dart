import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/company.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/error_view.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../ui/widgets/common/status_badge.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../state/platform_admin_cubit.dart';
import '../state/platform_admin_state.dart';
import '../widgets/platform_kpi_card.dart';
import '../widgets/section_card.dart';
import 'audit/audit_logs_viewer.dart';
import 'monitoring/error_logs.dart';
import 'monitoring/usage_monitor.dart';
import 'subscriptions/billing_overview.dart';
import 'subscriptions/plans_management.dart';
import 'tenants/tenants_list.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.platformAdmin`
/// (`/platform-admin`) — بنفس نمط `AnalyticsDashboard`/`UsersListScreen`
/// تماماً: توفّر [PlatformAdminCubit] محلياً عبر
/// `sl<PlatformAdminCubit>()..loadInitial(user)` عند التحقق من مصادقة
/// المستخدم، ثم تبني الحاوية الرئيسية ذات الألسنة السبعة بمجرد اكتمال
/// التحميل. 🆕 (Prompt 28)
///
/// ⚠️ قرار تصميم (لا واجهة هاتف — الميزة سطح مكتب حصراً، ومحصورة
/// بـ`platformOwner` وحده): بنفس منطق `AnalyticsDashboard` تماماً —
/// `AppNavDestinations.platformAdmin` مُعلَّمة `isDesktopOnly: true`
/// **و** `requiredPermission: Permission.platformManageTenants`
/// (`admin` فأعلى غير كافٍ هنا، `platformOwner` فقط يملكها فعلياً حسب
/// `RolePermissions` في `core/constants/permissions.dart`) — [PlatformGuard]
/// و[RoleGuard] يتوليان المنع/التوجيه تلقائياً معاً قبل بناء هذا
/// الملف أصلاً، فلا حاجة لأي فرع عرض بديل أو تحقّق دور إضافي هنا.
///
/// ⚠️ قرار تصميم آخر (سبع ألسنة، بدل سبعة مسارات فرعية): بنفس فلسفة
/// `AnalyticsDashboard` (أربع شاشات، لسان واحد بدل أربعة مسارات) —
/// الشاشات الفرعية الثلاث التي تحتاج مساراً "أعمق" فعلياً
/// (`tenant_details.dart`/`tenant_create.dart`/`tenant_data_export.dart`)
/// تُفتح عبر `Navigator.push` من `tenants_list.dart` نفسها (بنفس قرار
/// `settings_screen.dart`، Prompt 27)، وليس كمسارات `go_router` منفصلة
/// — لا حاجة فعلية لرابط قابل للمشاركة/تنقّل عميق مباشر لأيّ منها.
class PlatformAdminDashboard extends StatelessWidget {
  const PlatformAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<PlatformAdminCubit>(
              create: (_) => sl<PlatformAdminCubit>()..loadInitial(user),
              child: const _PlatformAdminDashboardBody(),
            );
          },
        );
      },
    );
  }
}

class _PlatformAdminDashboardBody extends StatelessWidget {
  const _PlatformAdminDashboardBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
      builder: (BuildContext context, PlatformAdminState state) {
        return DefaultTabController(
          length: 7,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('لوحة إدارة المنصّة'),
              actions: <Widget>[
                if (state.dataOrNull != null)
                  IconButton(
                    tooltip: 'تحديث',
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        context.read<PlatformAdminCubit>().refresh(),
                  ),
                const SizedBox(width: AvahiSpacing.xs),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: <Widget>[
                  Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard_outlined)),
                  Tab(text: 'المستأجرون', icon: Icon(Icons.apartment_outlined)),
                  Tab(text: 'الخطط', icon: Icon(Icons.workspace_premium_outlined)),
                  Tab(text: 'الفوترة', icon: Icon(Icons.receipt_long_outlined)),
                  Tab(text: 'المراقبة', icon: Icon(Icons.monitor_heart_outlined)),
                  Tab(text: 'الأخطاء', icon: Icon(Icons.bug_report_outlined)),
                  Tab(text: 'سجل التدقيق', icon: Icon(Icons.history_outlined)),
                ],
              ),
            ),
            body: state.when<Widget>(
              loading: () => const LoadingIndicator(
                label: 'جارٍ تحميل لوحة إدارة المنصّة...',
              ),
              error: (Failure failure) => ErrorView(
                title: 'تعذّر تحميل لوحة إدارة المنصّة',
                message: failure.message,
                onRetry: () {
                  final AuthState authState = context.read<AuthCubit>().state;
                  authState.maybeWhen<void>(
                    orElse: () {},
                    authenticated: (AppUser user, _) =>
                        context.read<PlatformAdminCubit>().loadInitial(user),
                  );
                },
              ),
              loaded: (PlatformAdminData data) => TabBarView(
                children: <Widget>[
                  _OverviewTab(data: data),
                  const TenantsListScreen(),
                  const PlansManagementScreen(),
                  const BillingOverviewScreen(),
                  const UsageMonitorScreen(),
                  const ErrorLogsScreen(),
                  const AuditLogsViewerScreen(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data});

  final PlatformAdminData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AvahiSpacing.md,
            runSpacing: AvahiSpacing.md,
            children: <Widget>[
              SizedBox(
                width: 220,
                child: PlatformKpiCard(
                  label: 'إجمالي المستأجرين',
                  value: '${data.companies.length}',
                  icon: Icons.apartment_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: PlatformKpiCard(
                  label: 'المستأجرون النشطون',
                  value: '${data.activeTenantsCount}',
                  icon: Icons.check_circle_outline,
                  accent: AvahiStatus.success,
                ),
              ),
              SizedBox(
                width: 220,
                child: PlatformKpiCard(
                  label: 'المستأجرون المعطَّلون',
                  value: '${data.inactiveTenantsCount}',
                  icon: Icons.pause_circle_outlined,
                  accent: data.inactiveTenantsCount > 0
                      ? AvahiStatus.warning
                      : AvahiStatus.neutral,
                ),
              ),
              SizedBox(
                width: 220,
                child: PlatformKpiCard(
                  label: 'الإيراد الشهري المتكرر',
                  value: '\$${data.totalMrrUsd.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AvahiSpacing.lg),
          if (data.usageSnapshot != null)
            PlatformSectionCard(
              title: 'حالة استخدام المنصّة الآن',
              child: Wrap(
                spacing: AvahiSpacing.md,
                runSpacing: AvahiSpacing.md,
                children: <Widget>[
                  _MiniStat(
                    label: 'إجمالي المستخدمين',
                    value: '${data.usageSnapshot!.totalUsers}',
                  ),
                  _MiniStat(
                    label: 'نشطون اليوم',
                    value: '${data.usageSnapshot!.activeUsersToday}',
                  ),
                  _MiniStat(
                    label: 'إجمالي التخزين',
                    value:
                        '${data.usageSnapshot!.totalStorageGb.toStringAsFixed(1)} GB',
                  ),
                  _MiniStat(
                    label: 'معدّل الأخطاء',
                    value:
                        '${data.usageSnapshot!.errorRatePercent.toStringAsFixed(2)}%',
                  ),
                ],
              ),
            ),
          const SizedBox(height: AvahiSpacing.md),
          PlatformSectionCard(
            title: 'أحدث المستأجرين إضافة',
            child: Column(
              children: <Widget>[
                for (final Company company in data.companies.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(company.name),
                    subtitle: Text(company.nameAr ?? company.slug),
                    trailing: Text(company.isActive ? 'نشطة' : 'معطَّلة'),
                  ),
                if (data.companies.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AvahiSpacing.md),
                    child: Text('لا يوجد مستأجرون بعد.'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
