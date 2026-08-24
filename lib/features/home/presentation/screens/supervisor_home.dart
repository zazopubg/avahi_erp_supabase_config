import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/company.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/enums/task_status.dart';
import '../../../../navigation/role_labels.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/status_badge.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';
import '../widgets/alerts_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/today_summary.dart';

/// الشاشة الرئيسية لأدوار [UserRole.foreman]/[UserRole.engineer] —
/// "مؤشرات ميدانية": نفس بطاقة ملخص اليوم (مشروع/حضور/مهام مفتوحة)
/// التي يراها [WorkerHome]، لكن مع إضافة شبكة إجراءات سريعة موسّعة
/// (اعتماد حضور، إسناد مهام...) وتوزيع مهام الفريق حسب الحالة — بدل
/// قائمة "مهامي" الفردية البسيطة لدور [UserRole.worker].
class SupervisorHome extends StatelessWidget {
  const SupervisorHome({
    required this.user,
    required this.company,
    required this.summary,
    super.key,
  });

  final AppUser user;
  final Company company;
  final HomeSummary summary;

  Map<TaskStatus, int> get _tasksByStatus {
    final Map<TaskStatus, int> counts = <TaskStatus, int>{
      for (final TaskStatus status in TaskStatus.values) status: 0,
    };
    for (final Task task in summary.tasks) {
      counts[task.status] = (counts[task.status] ?? 0) + 1;
    }
    return counts;
  }

  String _statusLabel(TaskStatus status) => switch (status) {
        TaskStatus.todo => 'قائمة الانتظار',
        TaskStatus.inProgress => 'قيد التنفيذ',
        TaskStatus.review => 'قيد المراجعة',
        TaskStatus.done => 'مكتملة',
        TaskStatus.blocked => 'معلّقة',
      };

  AvahiStatus _statusColor(TaskStatus status) => switch (status) {
        TaskStatus.done => AvahiStatus.success,
        TaskStatus.blocked => AvahiStatus.danger,
        TaskStatus.review => AvahiStatus.info,
        TaskStatus.inProgress => AvahiStatus.warning,
        TaskStatus.todo => AvahiStatus.neutral,
      };

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
            TodaySummary(summary: summary),
            const SizedBox(height: AvahiSpacing.lg),
            Text('مهام الفريق حسب الحالة', style: context.textTheme.titleSmall),
            const SizedBox(height: AvahiSpacing.sm),
            Wrap(
              spacing: AvahiSpacing.xs,
              runSpacing: AvahiSpacing.xs,
              children: _tasksByStatus.entries
                  .map(
                    (MapEntry<TaskStatus, int> entry) => StatusBadge(
                      label: '${_statusLabel(entry.key)}: ${entry.value}',
                      status: _statusColor(entry.key),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: AvahiSpacing.lg),
            AlertsSection(notifications: summary.latestUnreadNotifications),
          ],
        ),
      ),
    );
  }
}
