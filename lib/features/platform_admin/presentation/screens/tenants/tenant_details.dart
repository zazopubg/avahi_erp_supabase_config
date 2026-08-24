import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/number_formatter.dart';
import '../../../../../domain/entities/company.dart';
import '../../../../../domain/entities/tenant_stats.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dialog.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../../ui/widgets/common/status_badge.dart';
import '../../state/platform_admin_cubit.dart';
import '../../state/platform_admin_state.dart';
import '../../widgets/section_card.dart';
import 'tenant_data_export.dart';

/// شاشة تفاصيل مستأجر واحد — تُفتح عبر `Navigator.push` من
/// `tenants_list.dart` (بنفس قرار `settings_screen.dart`، لا مسار
/// `go_router` مستقل). تعرض بيانات الشركة + [TenantStats] (تحميل
/// كسول عند أول فتح عبر [PlatformAdminCubit.loadTenantStats]) + إجراءات
/// إدارية (تصدير بيانات/تعطيل). 🆕 (Prompt 28)
class TenantDetailsScreen extends StatefulWidget {
  const TenantDetailsScreen({required this.companyId, super.key});

  final String companyId;

  @override
  State<TenantDetailsScreen> createState() => _TenantDetailsScreenState();
}

class _TenantDetailsScreenState extends State<TenantDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final PlatformAdminData? data =
        context.read<PlatformAdminCubit>().state.dataOrNull;
    if (data != null && !data.tenantStats.containsKey(widget.companyId)) {
      context.read<PlatformAdminCubit>().loadTenantStats(widget.companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
      builder: (BuildContext context, PlatformAdminState state) {
        final PlatformAdminData? data = state.dataOrNull;
        if (data == null) {
          return const Scaffold(body: LoadingIndicator());
        }

        Company? company;
        for (final Company c in data.companies) {
          if (c.id == widget.companyId) {
            company = c;
            break;
          }
        }

        if (company == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المستأجر')),
            body: const Center(child: Text('تعذّر العثور على هذا المستأجر.')),
          );
        }

        final TenantStats? stats = data.tenantStats[widget.companyId];
        final bool isDeactivating = data.deactivatingCompanyId == company.id;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              company.nameAr?.isNotEmpty == true
                  ? company.nameAr!
                  : company.name,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PlatformSectionCard(
                  title: 'بيانات الشركة',
                  trailing: StatusBadge(
                    label: company.isActive ? 'نشطة' : 'معطَّلة',
                    status: company.isActive
                        ? AvahiStatus.success
                        : AvahiStatus.neutral,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _InfoRow(label: 'الـ Slug', value: company.slug),
                      _InfoRow(
                        label: 'المنطقة الزمنية',
                        value: company.timezone,
                      ),
                      if (company.phone != null)
                        _InfoRow(label: 'الهاتف', value: company.phone!),
                      if (company.address != null)
                        _InfoRow(label: 'العنوان', value: company.address!),
                      _InfoRow(
                        label: 'تاريخ الإنشاء',
                        value: DateFormatter.longDate(company.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AvahiSpacing.md),
                PlatformSectionCard(
                  title: 'إحصائيات مجمَّعة',
                  child: data.isLoadingTenantStats && stats == null
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AvahiSpacing.lg,
                          ),
                          child: LoadingIndicator(),
                        )
                      : stats == null
                          ? const Text('تعذّر تحميل الإحصائيات.')
                          : Wrap(
                              spacing: AvahiSpacing.xl,
                              runSpacing: AvahiSpacing.md,
                              children: <Widget>[
                                _InfoRow(
                                  label: 'الأعضاء',
                                  value:
                                      '${stats.activeMembersCount} / ${stats.membersCount}',
                                ),
                                _InfoRow(
                                  label: 'المشاريع',
                                  value:
                                      '${stats.activeProjectsCount} / ${stats.projectsCount}',
                                ),
                                _InfoRow(
                                  label: 'التخزين المستخدَم',
                                  value: NumberFormatter.fileSize(
                                    stats.storageUsedBytes,
                                  ),
                                ),
                                if (stats.lastActivityAt != null)
                                  _InfoRow(
                                    label: 'آخر نشاط',
                                    value: DateFormatter.relative(
                                      stats.lastActivityAt!,
                                    ),
                                  ),
                              ],
                            ),
                ),
                const SizedBox(height: AvahiSpacing.md),
                PlatformSectionCard(
                  title: 'إجراءات إدارية',
                  child: Wrap(
                    spacing: AvahiSpacing.sm,
                    runSpacing: AvahiSpacing.sm,
                    children: <Widget>[
                      AvahiButton(
                        label: 'تصدير بيانات المستأجر',
                        icon: Icons.ios_share_outlined,
                        variant: AvahiButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                BlocProvider<PlatformAdminCubit>.value(
                              value: context.read<PlatformAdminCubit>(),
                              child: TenantDataExportScreen(
                                companyId: company!.id,
                                companyName: company.nameAr?.isNotEmpty == true
                                    ? company.nameAr!
                                    : company.name,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (company.isActive)
                        AvahiButton(
                          label: 'تعطيل المستأجر',
                          icon: Icons.block_outlined,
                          variant: AvahiButtonVariant.danger,
                          isLoading: isDeactivating,
                          onPressed: isDeactivating
                              ? null
                              : () => _confirmDeactivate(context, company!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeactivate(BuildContext context, Company company) {
    final TextEditingController reasonController = TextEditingController();
    final PlatformAdminCubit cubit = context.read<PlatformAdminCubit>();

    AvahiDialog.show(
      context,
      title: 'تعطيل ${company.name}؟',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'سيتم تعطيل هذا المستأجر وكل عضوياته. يمكن التراجع عن هذا '
            'لاحقاً يدوياً عبر قاعدة البيانات، ولا يُحذَف أي صف نهائياً.',
          ),
          const SizedBox(height: AvahiSpacing.sm),
          AvahiTextField(
            controller: reasonController,
            label: 'سبب التعطيل (اختياري)',
            maxLines: 2,
          ),
        ],
      ),
      confirmLabel: 'تعطيل',
      cancelLabel: 'إلغاء',
      isDestructive: true,
      onConfirm: () async {
        Navigator.of(context).pop();
        await cubit.softDeleteTenant(
          companyId: company.id,
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AvahiSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
