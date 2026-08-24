import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/entities/company.dart';
import '../../../../../domain/entities/subscription_plan.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_radius.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dialog.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/status_badge.dart';
import '../../state/platform_admin_cubit.dart';
import '../../state/platform_admin_state.dart';

/// لسان "الخطط" ضمن `admin_dashboard.dart` — يعرض خطط الاشتراك
/// الثلاث المتاحة على مستوى المنصّة (بيانات ثابتة حالياً، انظر توثيق
/// القرار الكامل في `SubscriptionPlan`)، مع إمكانية تعيين خطة لمستأجر
/// محدَّد مباشرة (تعديل مبسّط عبر [PlatformAdminCubit.updateTenantPlan])
/// — بلا أي تكامل بوابة دفع فعلية بعد. 🆕 (Prompt 28)
class PlansManagementScreen extends StatelessWidget {
  const PlansManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
      builder: (BuildContext context, PlatformAdminState state) {
        final PlatformAdminData? data = state.dataOrNull;
        if (data == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Wrap(
            spacing: AvahiSpacing.md,
            runSpacing: AvahiSpacing.md,
            children: <Widget>[
              for (final SubscriptionPlan plan in data.plans)
                SizedBox(
                  width: 300,
                  child: _PlanCard(plan: plan, companies: data.companies),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.companies});

  final SubscriptionPlan plan;
  final List<Company> companies;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AvahiRadius.radiusMd,
        border: Border.all(
          color: plan.isPopular ? colors.brand : colors.outlineVariant,
          width: plan.isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (plan.isPopular)
            const Padding(
              padding: EdgeInsets.only(bottom: AvahiSpacing.xs),
              child: StatusBadge(
                label: 'الأكثر شيوعاً',
                status: AvahiStatus.success,
                dense: true,
              ),
            ),
          Text(plan.nameAr, style: textTheme.titleLarge),
          const SizedBox(height: AvahiSpacing.xxs),
          Text(
            '\$${plan.monthlyPriceUsd.toStringAsFixed(0)} / شهرياً',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.brand,
            ),
          ),
          const SizedBox(height: AvahiSpacing.sm),
          Text(
            plan.hasUnlimitedUsers
                ? 'مستخدمون غير محدودين'
                : 'حتى ${plan.maxUsers} مستخدماً',
          ),
          Text(
            plan.hasUnlimitedProjects
                ? 'مشاريع غير محدودة'
                : 'حتى ${plan.maxProjects} مشروعاً',
          ),
          Text(
            plan.hasUnlimitedStorage
                ? 'تخزين غير محدود'
                : 'حتى ${plan.maxStorageGb} GB تخزين',
          ),
          const SizedBox(height: AvahiSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AvahiSpacing.sm),
          for (final String feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: AvahiSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.check, size: 16, color: colors.success),
                  const SizedBox(width: AvahiSpacing.xs),
                  Expanded(child: Text(feature, style: textTheme.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: AvahiSpacing.sm),
          AvahiButton(
            label: 'تعيين لمستأجر',
            variant: AvahiButtonVariant.secondary,
            isFullWidth: true,
            onPressed: () => _showAssignDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    final PlatformAdminCubit cubit = context.read<PlatformAdminCubit>();
    String? selectedCompanyId;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AvahiDialog(
            title: 'تعيين خطة "${plan.nameAr}"',
            content: AvahiDropdown<String>(
              label: 'المستأجر',
              value: selectedCompanyId,
              items: <AvahiDropdownItem<String>>[
                for (final Company company in companies)
                  AvahiDropdownItem<String>(
                    value: company.id,
                    label:
                        company.nameAr?.isNotEmpty == true
                            ? company.nameAr!
                            : company.name,
                  ),
              ],
              onChanged: (String? id) => setState(() => selectedCompanyId = id),
            ),
            confirmLabel: 'تعيين',
            cancelLabel: 'إلغاء',
            onConfirm: selectedCompanyId == null
                ? null
                : () async {
                    Navigator.of(dialogContext).pop();
                    await cubit.updateTenantPlan(
                      companyId: selectedCompanyId!,
                      newPlanId: plan.id,
                    );
                  },
          );
        },
      ),
    );
  }
}
