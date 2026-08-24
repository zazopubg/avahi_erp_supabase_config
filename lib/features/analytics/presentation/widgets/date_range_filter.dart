import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// اختصار مدى زمني جاهز — أزرار "آخر 7 أيام"/"آخر 30 يوماً"/"آخر 90
/// يوماً" في [DateRangeFilter].
enum DateRangePreset {
  last7Days(7, 'آخر 7 أيام'),
  last30Days(30, 'آخر 30 يوماً'),
  last90Days(90, 'آخر 90 يوماً');

  const DateRangePreset(this.days, this.label);

  final int days;
  final String label;
}

/// شريط تصفية زمني مرن أعلى `analytics_dashboard.dart`/
/// `attendance_analytics.dart`/`project_analytics.dart` — أزرار مدى
/// جاهزة ([DateRangePreset]) بجانب زر مدى مخصَّص (`showDateRangePicker`
/// الجاهز من Flutter، بخلاف `DateRangePickerField` الخاص بميزة
/// `leave_requests/` القائم على حقلين منفصلين — هنا حوار مدى واحد
/// أنسب لأن كلا الطرفين يُختاران معاً دائماً ولا حاجة لتعطيل أحدهما
/// بشرط منفصل كما في حالة الإجازات).
///
/// مكوّن عرض بحت — لا يستدعي `AnalyticsCubit.setDateRange` مباشرة؛
/// يُبلّغ فقط عبر [onRangeSelected] ويترك الاستدعاء الفعلي للشاشة
/// المستهلِكة.
class DateRangeFilter extends StatelessWidget {
  const DateRangeFilter({
    required this.rangeFrom,
    required this.rangeTo,
    required this.onRangeSelected,
    super.key,
    this.isRefreshing = false,
  });

  final DateTime rangeFrom;
  final DateTime rangeTo;
  final ValueChanged<(DateTime, DateTime)> onRangeSelected;
  final bool isRefreshing;

  DateRangePreset? get _activePreset {
    final int days = rangeTo.difference(rangeFrom).inDays + 1;
    for (final DateRangePreset preset in DateRangePreset.values) {
      if (preset.days == days) return preset;
    }
    return null;
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
      initialDateRange: DateTimeRange(start: rangeFrom, end: rangeTo),
      helpText: 'اختر مدى التاريخ',
      saveText: 'تأكيد',
    );
    if (picked != null) {
      onRangeSelected((picked.start, picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final DateRangePreset? activePreset = _activePreset;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AvahiSpacing.xs,
      runSpacing: AvahiSpacing.xs,
      children: <Widget>[
        for (final DateRangePreset preset in DateRangePreset.values)
          _PresetChip(
            label: preset.label,
            selected: activePreset == preset,
            onTap: isRefreshing
                ? null
                : () {
                    final DateTime now = DateTime.now();
                    final DateTime to = DateTime(now.year, now.month, now.day);
                    final DateTime from =
                        to.subtract(Duration(days: preset.days - 1));
                    onRangeSelected((from, to));
                  },
          ),
        _PresetChip(
          label: activePreset == null
              ? '${DateFormatter.shortDate(rangeFrom)} — '
                  '${DateFormatter.shortDate(rangeTo)}'
              : 'مدى مخصّص',
          icon: Icons.date_range_outlined,
          selected: activePreset == null,
          onTap: isRefreshing ? null : () => _pickCustomRange(context),
        ),
        if (isRefreshing)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.brand),
            ),
          ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AvahiRadius.radiusFull,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AvahiSpacing.sm,
          vertical: AvahiSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.brandContainer : colors.surface,
          borderRadius: AvahiRadius.radiusFull,
          border: Border.all(
            color: selected ? colors.brand : colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(
                icon,
                size: 14,
                color: selected ? colors.onBrandContainer : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AvahiSpacing.xxs),
            ],
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: selected ? colors.onBrandContainer : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
