import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/analytics_cubit.dart';
import '../../state/analytics_state.dart';
import '../../widgets/attendance_trend_chart.dart';
import '../../widgets/date_range_filter.dart';
import '../../widgets/kpi_summary_row.dart';
import '../../widgets/project_progress_chart.dart';
import '../../widgets/task_distribution_chart.dart';
import 'attendance_analytics.dart';
import 'export_analytics_screen.dart';
import 'project_analytics.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.analytics` (`/analytics`) —
/// بنفس نمط `MyEquipmentScreen`/`DocumentsListScreen` تماماً: توفّر
/// [AnalyticsCubit] محلياً عبر `sl<AnalyticsCubit>()..loadInitial(user)`
/// عند التحقق من مصادقة المستخدم، ثم تبني الحاوية الرئيسية ذات
/// الألسنة الأربعة (نظرة عامة/المشاريع/الحضور/التصدير) بمجرد اكتمال
/// التحميل.
///
/// ⚠️ قرار تصميم مهم (لا واجهة هاتف — الميزة سطح مكتب حصراً): بخلاف كل
/// ميزة سابقة (`equipment`/`documents`...) التي توفّر واجهتي هاتف
/// وسطح مكتب معاً عبر `context.shellMode`، هذه الميزة مُعلَّمة
/// `isDesktopOnly: true` ضمن `AppNavDestinations.analytics`
/// (`navigation/nav_destinations.dart`) — [PlatformGuard]
/// (`navigation/guards/platform_guard.dart`) يمنع الوصول لهذا المسار
/// بالكامل عندما يكون عرض النافذة ضمن `ShellMode.mobile` ويُعيد
/// التوجيه لـ `RoutePaths.home` تلقائياً، لذا لا حاجة لأي فرع عرض بديل
/// هنا (بخلاف `_EquipmentDispatcher` مثلاً) — هذا الملف يُبنى **فقط**
/// ضمن نافذة عريضة أصلاً بحكم الحارس نفسه.
///
/// ⚠️ قرار تصميم آخر (أربع شاشات، ألسنة واحدة بدل أربعة مسارات فرعية):
/// بخلاف `RouteNames.tasksBoard`/`equipmentLogUsage` (مسارات فرعية
/// منفصلة كاملة)، شاشات `project_analytics.dart`/`attendance_analytics.dart`/
/// `export_analytics_screen.dart` الثلاث ليست مسارات URL منفصلة —
/// جميعها تستهلك [AnalyticsCubit]/[AnalyticsData] **نفسيهما** بلا أي
/// حالة تحميل إضافية خاصة بها، فتبديلها عبر [TabBar] داخل نفس الشاشد
/// (بنفس فلسفة `_ViewMode` في `equipment_registry.dart`، لكن بأربع
/// قيم بدل قيمتين) أبسط وأسرع من مستخدم اللوحة من فتح مسارات كاملة
/// منفصلة لعرض بيانات محمَّلة مسبقاً أصلاً.
class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<AnalyticsCubit>(
              create: (_) => sl<AnalyticsCubit>()..loadInitial(user),
              child: const _AnalyticsDashboardBody(),
            );
          },
        );
      },
    );
  }
}

class _AnalyticsDashboardBody extends StatelessWidget {
  const _AnalyticsDashboardBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (BuildContext context, AnalyticsState state) {
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('التحليلات التنفيذية'),
              actions: <Widget>[
                if (state.dataOrNull != null)
                  IconButton(
                    tooltip: 'تحديث',
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        context.read<AnalyticsCubit>().refresh(),
                  ),
                const SizedBox(width: AvahiSpacing.xs),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: <Widget>[
                  Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard_outlined)),
                  Tab(text: 'المشاريع', icon: Icon(Icons.folder_outlined)),
                  Tab(
                    text: 'الحضور',
                    icon: Icon(Icons.how_to_reg_outlined),
                  ),
                  Tab(
                    text: 'التصدير',
                    icon: Icon(Icons.ios_share_outlined),
                  ),
                ],
              ),
            ),
            body: state.when<Widget>(
              initial: () => const LoadingIndicator(
                label: 'جارٍ تحميل لوحة التحليلات...',
              ),
              loading: () => const LoadingIndicator(
                label: 'جارٍ تحميل لوحة التحليلات...',
              ),
              error: (Failure failure) => ErrorView(
                title: 'تعذّر تحميل لوحة التحليلات',
                message: failure.message,
                onRetry: () {
                  final AuthState authState = context.read<AuthCubit>().state;
                  authState.maybeWhen<void>(
                    orElse: () {},
                    authenticated: (AppUser user, _) =>
                        context.read<AnalyticsCubit>().loadInitial(user),
                  );
                },
              ),
              loaded: (AnalyticsData data) =>
                  _AnalyticsTabs(data: data, isExporting: false),
              exporting: (AnalyticsData data, AnalyticsExportKind kind) =>
                  _AnalyticsTabs(data: data, isExporting: true),
            ),
          ),
        );
      },
    );
  }
}

class _AnalyticsTabs extends StatelessWidget {
  const _AnalyticsTabs({required this.data, required this.isExporting});

  final AnalyticsData data;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: <Widget>[
        _OverviewTab(data: data),
        ProjectAnalytics(data: data),
        AttendanceAnalytics(data: data),
        ExportAnalyticsScreen(data: data, isExporting: isExporting),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final AnalyticsCubit cubit = context.read<AnalyticsCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DateRangeFilter(
            rangeFrom: data.rangeFrom,
            rangeTo: data.rangeTo,
            isRefreshing: data.isRefreshingRange,
            onRangeSelected: (record) => cubit.setDateRange(
              from: record.$1,
              to: record.$2,
            ),
          ),
          const SizedBox(height: AvahiSpacing.md),
          KpiSummaryRow(data: data),
          const SizedBox(height: AvahiSpacing.lg),
          SectionCard(
            title: 'تقدّم المشاريع',
            child: ProjectProgressChart(projects: data.projectProgressList),
          ),
          const SizedBox(height: AvahiSpacing.md),
          SectionCard(
            title: 'توزيع حالات المهام',
            child: TaskDistributionChart(
              distribution: data.taskStatusDistribution,
            ),
          ),
          const SizedBox(height: AvahiSpacing.md),
          SectionCard(
            title: 'اتجاه الحضور اليومي',
            child: AttendanceTrendChart(points: data.attendanceTrend),
          ),
        ],
      ),
    );
  }
}

/// بطاقة قسم موحّدة تُستخدم عبر كل ألسنة `analytics_dashboard.dart`
/// (وأيضاً `project_analytics.dart`/`attendance_analytics.dart`) —
/// عنوان + محتوى ضمن حدود بطاقة متسقة بصرياً. مُصدَّرة (Public) عمداً
/// كي تستهلكها الشاشات الثلاث الأخرى مباشرة بدل تكرار نفس التغليف في
/// كل ملف.
class SectionCard extends StatelessWidget {
  const SectionCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AvahiSpacing.sm),
          child,
        ],
      ),
    );
  }
}
