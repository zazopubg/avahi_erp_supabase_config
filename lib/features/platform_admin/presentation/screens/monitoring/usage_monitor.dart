import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../domain/entities/platform_usage_snapshot.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../../ui/widgets/common/status_badge.dart';
import '../../state/platform_admin_cubit.dart';
import '../../state/platform_admin_state.dart';
import '../../widgets/platform_kpi_card.dart';
import '../../widgets/platform_usage_trend_chart.dart';
import '../../widgets/section_card.dart';

/// لسان "المراقبة" ضمن `admin_dashboard.dart` — لقطة حالة استخدام
/// المنصّة الحالية عبر [PlatformUsageSnapshot] (بيانات تجريبية مولَّدة
/// حتمياً — مُقرَّة صراحة ضمن سياق Prompt 28؛ انظر توثيق القرار الكامل
/// في `PlatformUsageSnapshot`). 🆕 (Prompt 28)
class UsageMonitorScreen extends StatelessWidget {
  const UsageMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
      builder: (BuildContext context, PlatformAdminState state) {
        final PlatformAdminData? data = state.dataOrNull;
        final PlatformUsageSnapshot? snapshot = data?.usageSnapshot;

        if (data == null) return const SizedBox.shrink();
        if (snapshot == null) {
          return const LoadingIndicator(
            label: 'جارٍ تحميل بيانات المراقبة...',
          );
        }

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
                    width: 200,
                    child: PlatformKpiCard(
                      label: 'إجمالي المستخدمين',
                      value: '${snapshot.totalUsers}',
                      icon: Icons.people_outline,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: PlatformKpiCard(
                      label: 'نشطون اليوم',
                      value: '${snapshot.activeUsersToday}',
                      icon: Icons.person_outline,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: PlatformKpiCard(
                      label: 'إجمالي التخزين',
                      value:
                          '${snapshot.totalStorageGb.toStringAsFixed(1)} GB',
                      icon: Icons.storage_outlined,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: PlatformKpiCard(
                      label: 'طلبات API اليوم',
                      value: '${snapshot.apiRequestsToday}',
                      icon: Icons.api_outlined,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: PlatformKpiCard(
                      label: 'متوسط زمن الاستجابة',
                      value: '${snapshot.avgResponseTimeMs} ms',
                      icon: Icons.speed_outlined,
                      accent: snapshot.avgResponseTimeMs > 500
                          ? AvahiStatus.warning
                          : AvahiStatus.success,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: PlatformKpiCard(
                      label: 'معدّل الأخطاء',
                      value:
                          '${snapshot.errorRatePercent.toStringAsFixed(2)}%',
                      icon: Icons.error_outline,
                      accent: snapshot.errorRatePercent > 2
                          ? AvahiStatus.danger
                          : AvahiStatus.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AvahiSpacing.lg),
              PlatformSectionCard(
                title: 'اتجاه المستأجرين النشطين (آخر 14 يوماً)',
                trailing: Text(
                  'محدَّثة: ${DateFormatter.time12h(snapshot.capturedAt)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                child: PlatformUsageTrendChart(
                  points: snapshot.dailyActiveTenantsTrend,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
