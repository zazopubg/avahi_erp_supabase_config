import 'package:flutter/material.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_text_field.dart';
import '../state/documents_state.dart';

/// شريط تصفية المستندات — حقل بحث بالعنوان/الوصف + رقاقات (Chips)
/// تصفية حسب [kDocumentCategories]، مستخدَم من `documents_list.dart`
/// (الهاتف) و`documents_manager.dart` (سطح المكتب) معاً، بنفس نمط
/// `PunchStatusFilter`.
///
/// مكوّن عرض بحت — لا يستدعي `DocumentsCubit` مباشرة؛ الشاشة الأب هي
/// من تمرّر القيم الحالية وتستقبل التغييرات عبر الاستدعاءات الخلفية،
/// غالباً بربطها مباشرة بدوال `DocumentsCubit.set...Filter`.
class DocumentFilterBar extends StatelessWidget {
  const DocumentFilterBar({
    required this.data,
    super.key,
    this.onCategoryChanged,
    this.onSearchChanged,
    this.onClearFilters,
    this.showArchivedToggle = false,
    this.onArchivedToggleChanged,
  });

  final DocumentsData data;
  final ValueChanged<String?>? onCategoryChanged;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearFilters;

  /// عند `true` يُعرض مفتاح تبديل "إظهار المؤرشف" — `documents_manager.dart`
  /// فقط (لا معنى له في عرض `documents_list.dart` الهاتف).
  final bool showArchivedToggle;
  final ValueChanged<bool>? onArchivedToggleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AvahiTextField(
          hint: 'ابحث بعنوان أو وصف المستند...',
          prefixIcon: Icons.search,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: AvahiSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (final String category in kDocumentCategories) ...<Widget>[
                _FilterChoiceChip(
                  label: category,
                  selected: data.categoryFilter == category,
                  onSelected: (bool selected) =>
                      onCategoryChanged?.call(selected ? category : null),
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
        if (showArchivedToggle) ...<Widget>[
          const SizedBox(height: AvahiSpacing.xs),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: data.includeArchived,
            onChanged: onArchivedToggleChanged,
            title: const Text('إظهار المستندات المؤرشفة'),
          ),
        ],
      ],
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
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
