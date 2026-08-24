import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/company.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/enums/task_status.dart';
import '../../../../navigation/route_names.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../../../../ui/widgets/common/empty_state.dart';
import '../../../../ui/widgets/common/status_badge.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';
import '../widgets/alerts_section.dart';
import '../widgets/today_summary.dart';

/// الشاشة الرئيسية لدور [UserRole.worker] — الأولوية القصوى لزر تسجيل
/// حضور/انصراف بارز أعلى الشاشة (أكثر إجراء يومي تكراراً لهذا الدور)،
/// تليه "مهامي" فقط (بلا أي مؤشرات فريق أو مشروع إضافية لا تعني عاملاً
/// ميدانياً فردياً)، ثم آخر الإشعارات.
class WorkerHome extends StatelessWidget {
  const WorkerHome({
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
      appBar: AppBar(title: Text('مرحباً ${user.fullName}')),
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeCubit>().refresh(user),
        child: ListView(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          children: <Widget>[
            AvahiButton(
              label: summary.hasCheckedOutToday
                  ? 'تم تسجيل الانصراف اليوم'
                  : summary.hasCheckedInToday
                      ? 'تسجيل الانصراف'
                      : 'تسجيل الحضور الآن',
              icon: Icons.fingerprint,
              size: AvahiButtonSize.large,
              isFullWidth: true,
              onPressed: summary.hasCheckedOutToday
                  ? null
                  : () => context.goNamed(RouteNames.attendance),
            ),
            const SizedBox(height: AvahiSpacing.md),
            TodaySummary(summary: summary),
            const SizedBox(height: AvahiSpacing.lg),
            Text('مهامي', style: context.textTheme.titleSmall),
            const SizedBox(height: AvahiSpacing.sm),
            if (summary.tasks.isEmpty)
              const EmptyState(
                title: 'لا توجد مهام مُسندة إليك حالياً',
                icon: Icons.checklist_outlined,
              )
            else
              ...summary.tasks.map((Task task) => _TaskTile(task: task)),
            const SizedBox(height: AvahiSpacing.lg),
            AlertsSection(notifications: summary.latestUnreadNotifications),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final Task task;

  AvahiStatus get _status => switch (task.status) {
        TaskStatus.done => AvahiStatus.success,
        TaskStatus.blocked => AvahiStatus.danger,
        TaskStatus.review => AvahiStatus.info,
        TaskStatus.inProgress => AvahiStatus.warning,
        TaskStatus.todo => AvahiStatus.neutral,
      };

  String get _statusLabel => switch (task.status) {
        TaskStatus.todo => 'قائمة الانتظار',
        TaskStatus.inProgress => 'قيد التنفيذ',
        TaskStatus.review => 'قيد المراجعة',
        TaskStatus.done => 'مكتملة',
        TaskStatus.blocked => 'معلّقة',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AvahiSpacing.xs),
      child: ListTile(
        title: Text(task.title),
        trailing: StatusBadge(
          label: _statusLabel,
          status: _status,
          dense: true,
        ),
        onTap: () => context.goNamed(RouteNames.tasks),
      ),
    );
  }
}
