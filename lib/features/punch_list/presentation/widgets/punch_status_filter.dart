import 'package:flutter/material.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/enums/punch_status.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_text_field.dart';
import '../state/punch_state.dart';
import 'punch_item_card.dart';

/// شريط تصفية عناصر Punch List — حقل بحث بالعنوان/الوصف + رقاقات
/// (Chips) تصفية حسب [PunchStatus]، مستخدَم من `punch_list_screen.dart`
/// (الهاتف) و`punch_item_manage.dart` (سطح المكتب) معاً بنفس المكوّن
/// تماماً، بنفس نمط `task_filter_bar.dart` (`features/tasks/`).
///
/// مكوّن عرض بحت — لا يستدعي `PunchCubit` مباشرة؛ الشاشة الأب هي من
/// تمرّر القيم الحالية وتستقبل التغييرات عبر الاستدعاءات الخلفية
/// (`on...Changed`)، غالباً بربطها مباشرة بدوال `PunchCubit.set...Filter`.
class PunchStatusFilter extends StatelessWidget {
  const PunchStatusFilter({
    required this.data,
    super.key,
    this.onStatusChanged,
    this.onSearchChanged,
    this.onClearFilters,
  });

  final PunchData data;
  final ValueChanged<PunchStatus?>? onStatusChanged;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AvahiTextField(
          hint: 'ابحث بعنوان أو وصف الملاحظة...',
          prefixIcon: Icons.search,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: AvahiSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (final PunchStatus status in PunchStatus.values) ...<Widget>[
                _FilterChoiceChip(
                  selected: data.statusFilter == status,
                  onSelected: (bool selected) =>
                      onStatusChanged?.call(selected ? status : null),
                  child: PunchStatusBadge(status: status, dense: true),
                ),
                const SizedBox(width: AvahiSpacing.xs),
              ],
              if (data.hasActiveFilters)
                ActionChip(
                  avatar: const Icon(Icons.close, size: 16),
                  label: const Text('مسح الفلاتر'),
                  onPressed: onClearFilters,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// غلاف [FilterChip] موحّد يسمح بتمرير أي [child] (شارة حالة جاهزة أو
/// نص بسيط) بدل نص فقط، بنفس فكرة `_FilterChoiceChip` الخاصة بـ
/// `task_filter_bar.dart`.
class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.selected,
    required this.onSelected,
    required this.child,
  });

  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: child,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      side: BorderSide(
        color: selected
            ? context.colors.primary
            : context.colors.outlineVariant,
      ),
    );
  }
}
