import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/company.dart';
import '../../../../navigation/role_labels.dart';
import '../../../../navigation/route_names.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';
import '../widgets/alerts_section.dart';
import '../widgets/quick_actions.dart';

/// الشاشة الرئيسية لأدوار [UserRole.projectManager]/[UserRole.admin]/
/// [UserRole.platformOwner] — "KPIs + رابط لوحة analytics": بطاقات
/// مؤشرات أداء مجمّعة على مستوى أعلى من ملخص يوم فردي (بخلاف
/// [WorkerHome]/[SupervisorHome])، مع بطاقة بارزة تفتح وجهة `analytics`
/// (🆕 Prompt 25: أصبحت الآن لوحة `features/analytics/` الفعلية
/// الكاملة — أربعة ألسنة: نظرة عامة/المشاريع/الحضور/التصدير — بدل
/// `ComingSoonScreen` المؤقتة).
class ManagerHome extends StatelessWidget {
  const ManagerHome({
    required this.user,
    required this.company,
    required this.summary,
    super.key,
  });

  final AppUser user;
  final Company company;
  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً ${user.fullName}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AvahiSpacing.sm),
            child: Text(
              '${user.role.displayLabel} — ${company.name}',
              style: context.textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeCubit>().refresh(user),
        child: ListView(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          children: <Widget>[
            QuickActions(role: user.role),
            const SizedBox(height: AvahiSpacing.md),
            _KpiGrid(summary: summary),
            const SizedBox(height: AvahiSpacing.md),
            _AnalyticsBanner(
              onTap: () => context.goNamed(RouteNames.analytics),
            ),
            const SizedBox(height: AvahiSpacing.lg),
            AlertsSection(notifications: summary.latestUnreadNotifications),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final List<_KpiCardData> cards = <_KpiCardData>[
      _KpiCardData(
        label: 'مهام مفتوحة',
        value: '${summary.pendingTasksCount}',
        icon: Icons.checklist_outlined,
      ),
      _KpiCardData(
        label: 'إجمالي المهام',
        value: '${summary.tasks.length}',
        icon: Icons.list_alt_outlined,
      ),
      _KpiCardData(
        label: 'إشعارات غير مقروءة',
        value: '${summary.unreadCount}',
        icon: Icons.notifications_outlined,
      ),
      _KpiCardData(
        label: 'حالة الحضور اليوم',
        value: summary.hasCheckedOutToday
            ? 'انصراف'
            : summary.hasCheckedInToday
                ? 'حاضر'
                : 'لم يُسجَّل',
        icon: Icons.fingerprint,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AvahiSpacing.sm,
      crossAxisSpacing: AvahiSpacing.sm,
      childAspectRatio: 1.6,
      children: cards.map((_KpiCardData data) => _KpiCard(data: data)).toList(
            growable: false,
          ),
    );
  }
}

class _KpiCardData {
  const _KpiCardData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(data.icon, color: context.colors.primary),
          Text(
            data.value,
            style: context.textTheme.headlineSmall,
          ),
          Text(
            data.label,
            style: context.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsBanner extends StatelessWidget {
  const _AnalyticsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.analytics_outlined, color: context.colors.onPrimaryContainer),
          const SizedBox(width: AvahiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'لوحة التحليلات',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
                Text(
                  'مؤشرات أداء تفصيلية على مستوى الشركة والمشاريع، مع تصدير PDF/صورة.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AvahiSpacing.sm),
          AvahiButton(
            label: 'فتح',
            variant: AvahiButtonVariant.secondary,
            size: AvahiButtonSize.small,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
