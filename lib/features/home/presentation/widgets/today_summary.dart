import 'package:flutter/material.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/project.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/status_badge.dart';
import '../state/home_state.dart';

/// بطاقة ملخص اليوم — اسم المشروع الحالي، شارة حالة الحضور (لم يُسجَّل/
/// حاضر الآن/تم الانصراف)، وعدد المهام المفتوحة. تُستخدم في
/// `worker_home.dart` و`supervisor_home.dart` (وليس `manager_home.dart`
/// التي تعرض مؤشرات أداء على مستوى أعلى بدل ملخص فردي ليوم واحد).
///
/// مكوّن عرض بحت — يستقبل [HomeSummary] جاهزاً من الشاشة الأب بدل
/// الاشتراك بـ `HomeCubit` مباشرة.
class TodaySummary extends StatelessWidget {
  const TodaySummary({required this.summary, super.key});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final Project? project = summary.currentProject;

    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.apartment_outlined, color: context.colors.primary),
              const SizedBox(width: AvahiSpacing.xs),
              Expanded(
                child: Text(
                  project?.name ?? 'لا يوجد مشروع نشط حالياً',
                  style: context.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AvahiSpacing.sm),
          Wrap(
            spacing: AvahiSpacing.xs,
            runSpacing: AvahiSpacing.xs,
            children: <Widget>[
              _attendanceBadge(),
              StatusBadge(
                label: '${summary.pendingTasksCount} مهمة مفتوحة',
                icon: Icons.checklist_outlined,
                status: summary.pendingTasksCount > 0
                    ? AvahiStatus.warning
                    : AvahiStatus.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceBadge() {
    if (summary.hasCheckedOutToday) {
      return const StatusBadge(
        label: 'تم تسجيل الانصراف',
        icon: Icons.logout_outlined,
        status: AvahiStatus.neutral,
      );
    }
    if (summary.hasCheckedInToday) {
      return const StatusBadge(
        label: 'حاضر الآن',
        icon: Icons.check_circle_outline,
        status: AvahiStatus.success,
      );
    }
    return const StatusBadge(
      label: 'لم يُسجَّل حضور بعد',
      icon: Icons.fingerprint,
      status: AvahiStatus.danger,
    );
  }
}
