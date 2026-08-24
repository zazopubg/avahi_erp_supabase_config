import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/punch_item.dart';
import '../../../../domain/enums/punch_status.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/status_badge.dart';
import '../../../tasks/presentation/widgets/task_priority_indicator.dart';

/// شارة حالة عنصر Punch List — غلاف رفيع فوق [StatusBadge] العام
/// يترجم [PunchStatus] إلى تسمية عربية ولون دلالي ثابت، بنفس نمط
/// `TaskStatusChip` (`features/tasks/presentation/widgets/task_status_chip.dart`).
class PunchStatusBadge extends StatelessWidget {
  const PunchStatusBadge({required this.status, super.key, this.dense = false});

  final PunchStatus status;
  final bool dense;

  static (AvahiStatus, String, IconData) _visualsFor(PunchStatus status) {
    return switch (status) {
      PunchStatus.open => (
          AvahiStatus.danger,
          'مفتوح',
          Icons.report_problem_outlined,
        ),
      PunchStatus.inProgress => (
          AvahiStatus.warning,
          'قيد المعالجة',
          Icons.autorenew,
        ),
      PunchStatus.resolved => (
          AvahiStatus.info,
          'عولج',
          Icons.fact_check_outlined,
        ),
      PunchStatus.closed => (
          AvahiStatus.success,
          'مُغلق',
          Icons.check_circle,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (AvahiStatus visual, String label, IconData icon) = _visualsFor(
      status,
    );
    return StatusBadge(label: label, status: visual, icon: icon, dense: dense);
  }
}

/// بطاقة عنصر ملاحظات مضغوطة — العنصر البصري المشترك بين
/// `punch_list_screen.dart` (الهاتف) و`punch_dashboard.dart`
/// (سطح المكتب، لوحة المتابعة عبر كل المشاريع)، بنفس فلسفة `TaskCard`
/// (`features/tasks/presentation/widgets/task_card.dart`).
///
/// تعرض العنوان، مؤشر الأولوية، شارة الحالة، تاريخ الاستحقاق (بتمييز
/// لوني عند التأخر)، وموقع الملاحظة النصي (`locationNote`) إن وُجد.
/// [projectLabel] اختياري: يظهر فقط ضمن `punch_dashboard.dart` (عيوب
/// من عدة مشاريع معاً) وليس `punch_list_screen.dart` (مشروع واحد
/// معروف أصلاً من سياق الشاشة).
///
/// مكوّن عرض بحت — [onTap] اختياري لفتح تفاصيل العنصر.
class PunchItemCard extends StatelessWidget {
  const PunchItemCard({
    required this.item,
    super.key,
    this.onTap,
    this.projectLabel,
  });

  final PunchItem item;
  final VoidCallback? onTap;
  final String? projectLabel;

  bool get _isOverdue =>
      item.dueDate != null &&
      !item.status.isClosed &&
      item.dueDate!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Material(
      color: context.colors.surface,
      borderRadius: AvahiRadius.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AvahiRadius.radiusMd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AvahiSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AvahiRadius.radiusMd,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  TaskPriorityIndicator(priority: item.priority, showLabel: false),
                  const SizedBox(width: AvahiSpacing.xs),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AvahiSpacing.xs),
              Wrap(
                spacing: AvahiSpacing.xs,
                runSpacing: AvahiSpacing.xxs,
                children: <Widget>[
                  PunchStatusBadge(status: item.status, dense: true),
                  if (projectLabel != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        projectLabel!,
                        style: context.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
              if (item.locationNote != null &&
                  item.locationNote!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: AvahiSpacing.xxs),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AvahiSpacing.xxs),
                    Expanded(
                      child: Text(
                        item.locationNote!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AvahiSpacing.xs),
              Row(
                children: <Widget>[
                  if (item.dueDate != null) ...<Widget>[
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: _isOverdue ? colors.danger : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AvahiSpacing.xxs),
                    Text(
                      DateFormatter.shortDate(item.dueDate!),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: _isOverdue ? colors.danger : colors.onSurfaceVariant,
                        fontWeight: _isOverdue ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormatter.relative(item.createdAt),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
