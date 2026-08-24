import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// حقل اختيار مدى تاريخ زمني (بداية/نهاية) لطلب إجازة —
/// `create_leave_request_screen.dart`. حقلان منفصلان جنباً إلى جنب
/// (`_DatePickerBox` لكل منهما)، بنفس نمط `_DateRangeBoxes` الضمني في
/// `report_export_screen.dart` (`features/field_reports/presentation/screens/desktop/`,
/// Prompt 17): [InkWell] + [InputDecorator] بدل [showDateRangePicker]
/// الجاهز من Flutter — يتيح تعطيل كل حقل بشرط منفصل (بداية لا يمكن أن
/// تسبق اليوم، نهاية لا يمكن أن تسبق البداية المُختارة) بوضوح أكبر من
/// حوار مدى واحد جاهز. 🆕
///
/// مكوّن عرض بحت — لا يحمل أي منطق تحقّق تداخل فعلي (`LeaveValidator`
/// يبقى في `domain/`)؛ يعرض فقط رسالة [errorText] اختيارية يمررها
/// المستدعي (تحقّق ترتيب بسيط: النهاية يجب ألا تسبق البداية).
class DateRangePickerField extends StatelessWidget {
  const DateRangePickerField({
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    super.key,
    this.enabled = true,
    this.errorText,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final bool enabled;
  final String? errorText;

  Future<void> _pickStart(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) onStartDateChanged(picked);
  }

  Future<void> _pickEnd(BuildContext context) async {
    final DateTime minDate = startDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate != null && endDate!.isAfter(minDate) ? endDate! : minDate,
      firstDate: minDate,
      lastDate: minDate.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) onEndDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _DatePickerBox(
                label: 'من تاريخ',
                date: startDate,
                enabled: enabled,
                onTap: () => _pickStart(context),
              ),
            ),
            const SizedBox(width: AvahiSpacing.sm),
            Expanded(
              child: _DatePickerBox(
                label: 'إلى تاريخ',
                date: endDate,
                enabled: enabled && startDate != null,
                onTap: () => _pickEnd(context),
              ),
            ),
          ],
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: AvahiSpacing.xxs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.xs),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
        if (startDate != null && endDate != null && !endDate!.isBefore(startDate!)) ...<Widget>[
          const SizedBox(height: AvahiSpacing.xxs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.xs),
            child: Text(
              'عدد الأيام: ${endDate!.difference(startDate!).inDays + 1}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ],
    );
  }
}

class _DatePickerBox extends StatelessWidget {
  const _DatePickerBox({
    required this.label,
    required this.date,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(date == null ? 'اختر تاريخاً' : DateFormatter.shortDate(date!)),
      ),
    );
  }
}
