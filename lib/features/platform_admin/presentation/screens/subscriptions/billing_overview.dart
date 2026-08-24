import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../domain/entities/company.dart';
import '../../../../../domain/entities/subscription_plan.dart';
import '../../../../../domain/entities/tenant_subscription.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/status_badge.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/platform_admin_cubit.dart';
import '../../state/platform_admin_state.dart';
import '../../widgets/platform_kpi_card.dart';

/// لسان "الفوترة" ضمن `admin_dashboard.dart` — نظرة عامة على اشتراك
/// كل مستأجر (خطة/حالة/إيراد شهري متكرر)، مبنية فوق [TenantSubscription]
/// (بيانات مولَّدة حالياً — انظر توثيق القرار الكامل في `TenantSubscription`).
/// 🆕 (Prompt 28)
class BillingOverviewScreen extends StatelessWidget {
  const BillingOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
      builder: (BuildContext context, PlatformAdminState state) {
        final PlatformAdminData? data = state.dataOrNull;
        if (data == null) return const SizedBox.shrink();

        final Map<String, Company> companiesById = <String, Company>{
          for (final Company c in data.companies) c.id: c,
        };
        final Map<String, SubscriptionPlan> plansById = <String, SubscriptionPlan>{
          for (final SubscriptionPlan p in data.plans) p.id: p,
        };

        final int activeCount = data.subscriptions
            .where((TenantSubscription s) => s.status.isActive)
            .length;
        final int pastDueCount = data.subscriptions
            .where((TenantSubscription s) => s.status.isPastDue)
            .length;
        final int trialCount = data.subscriptions
            .where((TenantSubscription s) => s.status.isTrial)
            .length;

        return Padding(
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
                      label: 'الإيراد الشهري المتكرر',
                      value: '\$${data.totalMrrUsd.toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                      accent: AvahiStatus.success,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: PlatformKpiCard(
                      label: 'اشتراكات نشطة',
                      value: '$activeCount',
                      icon: Icons.check_circle_outline,
                      accent: AvahiStatus.success,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: PlatformKpiCard(
                      label: 'دفعات متأخرة',
                      value: '$pastDueCount',
                      icon: Icons.warning_amber_outlined,
                      accent: pastDueCount > 0
                          ? AvahiStatus.danger
                          : AvahiStatus.neutral,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: PlatformKpiCard(
                      label: 'فترات تجريبية',
                      value: '$trialCount',
                      icon: Icons.hourglass_top_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AvahiSpacing.md),
              Expanded(
                child: DataGridRtl<TenantSubscription>(
                  rows: data.subscriptions,
                  emptyTitle: 'لا توجد اشتراكات بعد',
                  emptyIcon: Icons.receipt_long_outlined,
                  rowKeyOf: (TenantSubscription s) => s.companyId,
                  columns: <DataGridColumn<TenantSubscription>>[
                    DataGridColumn<TenantSubscription>(
                      label: 'المستأجر',
                      flex: 3,
                      cellBuilder:
                          (BuildContext context, TenantSubscription s) {
                        final Company? company = companiesById[s.companyId];
                        return Text(
                          company == null
                              ? s.companyId
                              : (company.nameAr?.isNotEmpty == true
                                  ? company.nameAr!
                                  : company.name),
                        );
                      },
                    ),
                    DataGridColumn<TenantSubscription>(
                      label: 'الخطة',
                      flex: 2,
                      cellBuilder:
                          (BuildContext context, TenantSubscription s) =>
                              Text(plansById[s.planId]?.nameAr ?? s.planId),
                    ),
                    DataGridColumn<TenantSubscription>(
                      label: 'الحالة',
                      flex: 2,
                      cellBuilder:
                          (BuildContext context, TenantSubscription s) =>
                              _statusBadge(s.status),
                    ),
                    DataGridColumn<TenantSubscription>(
                      label: 'الإيراد الشهري',
                      flex: 2,
                      cellBuilder:
                          (BuildContext context, TenantSubscription s) =>
                              Text('\$${s.mrrUsd.toStringAsFixed(0)}'),
                    ),
                    DataGridColumn<TenantSubscription>(
                      label: 'نهاية الفترة الحالية',
                      flex: 2,
                      cellBuilder:
                          (BuildContext context, TenantSubscription s) => Text(
                        DateFormatter.shortDate(s.currentPeriodEndsAt),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(TenantSubscriptionStatus status) {
    return switch (status) {
      TenantSubscriptionStatus.active => const StatusBadge(
          label: 'نشط',
          status: AvahiStatus.success,
          dense: true,
        ),
      TenantSubscriptionStatus.trial => const StatusBadge(
          label: 'تجريبي',
          status: AvahiStatus.info,
          dense: true,
        ),
      TenantSubscriptionStatus.pastDue => const StatusBadge(
          label: 'دفعة متأخرة',
          status: AvahiStatus.danger,
          dense: true,
        ),
      TenantSubscriptionStatus.cancelled => const StatusBadge(
          label: 'مُلغى',
          status: AvahiStatus.neutral,
          dense: true,
        ),
    };
  }
}
