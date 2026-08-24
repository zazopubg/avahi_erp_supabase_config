import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../state/platform_admin_cubit.dart';
import '../../state/platform_admin_state.dart';

/// شاشة تصدير كامل بيانات مستأجر — تُفتح عبر `Navigator.push` من
/// `tenant_details.dart`. تستدعي [PlatformAdminCubit.exportTenantData]،
/// والتي بدورها تستدعي Edge Function جديدة `export-tenant-data` 🆕
/// (Prompt 28) وتُعيد رابطاً موقّتاً موقَّعاً صالحاً لمدة ساعة واحدة.
/// 🆕 (Prompt 28)
class TenantDataExportScreen extends StatelessWidget {
  const TenantDataExportScreen({
    required this.companyId,
    required this.companyName,
    super.key,
  });

  final String companyId;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تصدير بيانات المستأجر')),
      body: BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
        builder: (BuildContext context, PlatformAdminState state) {
          final PlatformAdminData? data = state.dataOrNull;
          final bool isExporting = data?.exportingCompanyId == companyId;
          final bool hasFreshExport =
              data?.lastExportCompanyId == companyId &&
                  data?.lastExportUrl != null;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AvahiSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Icon(
                      Icons.archive_outlined,
                      size: 56,
                    ),
                    const SizedBox(height: AvahiSpacing.md),
                    Text(
                      'تصدير كامل بيانات "$companyName"',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AvahiSpacing.xs),
                    Text(
                      'يُنشئ أرشيفاً واحداً (JSON) يضم كل بيانات هذا '
                      'المستأجر (الأعضاء/المشاريع/المهام/التقارير/المستندات '
                      'وغيرها) لأغراض الأرشفة أو الامتثال، ويوفّر رابط '
                      'تنزيل صالحاً لمدة ساعة واحدة فقط.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AvahiSpacing.lg),
                    if (hasFreshExport) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(AvahiSpacing.md),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'الأرشيف جاهز.',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AvahiSpacing.xs),
                            Text(
                              'الرابط صالح لمدة ساعة واحدة من الآن فقط — '
                              'حمّل الملف الآن إن احتجته لاحقاً.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AvahiSpacing.md),
                      AvahiButton(
                        label: 'فتح رابط التنزيل',
                        icon: Icons.download_outlined,
                        isFullWidth: true,
                        onPressed: () => launchUrl(
                          Uri.parse(data!.lastExportUrl!),
                          webOnlyWindowName: '_blank',
                        ),
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                    ],
                    AvahiButton(
                      label: hasFreshExport
                          ? 'توليد رابط جديد'
                          : 'بدء التصدير',
                      icon: Icons.ios_share_outlined,
                      variant: hasFreshExport
                          ? AvahiButtonVariant.secondary
                          : AvahiButtonVariant.primary,
                      isFullWidth: true,
                      isLoading: isExporting,
                      onPressed: isExporting
                          ? null
                          : () => context
                              .read<PlatformAdminCubit>()
                              .exportTenantData(companyId),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
