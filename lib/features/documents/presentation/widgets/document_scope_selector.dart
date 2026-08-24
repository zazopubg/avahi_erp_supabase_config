import 'package:flutter/material.dart';

import '../../../../domain/entities/project.dart';
import '../../../../ui/widgets/common/avahi_dropdown.dart';
import '../state/documents_state.dart';

/// قائمة منسدلة لاختيار نطاق المستندات المعروضة — `null` (الكل)،
/// [kDocumentScopeCompanyWide] (مستندات الشركة العامة فقط)، أو معرّف
/// مشروع محدد ضمن [DocumentsData.myProjects]. تُستخدم حصراً في
/// `documents_manager.dart` (سطح المكتب) — `documents_list.dart`
/// الهاتف يبقى دوماً على النطاق الافتراضي "الكل" بلا أي عنصر اختيار،
/// انظر توثيق القرار الكامل في `DocumentsCubit`.
///
/// مكوّن عرض بحت — [onChanged] يُربط مباشرة بـ
/// `DocumentsCubit.setScopeFilter`.
class DocumentScopeSelector extends StatelessWidget {
  const DocumentScopeSelector({
    required this.data,
    super.key,
    this.onChanged,
  });

  final DocumentsData data;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AvahiDropdown<String?>(
      label: 'النطاق',
      value: data.scopeFilter,
      items: <AvahiDropdownItem<String?>>[
        const AvahiDropdownItem<String?>(
          value: null,
          label: 'كل المستندات',
          icon: Icons.all_inbox_outlined,
        ),
        const AvahiDropdownItem<String?>(
          value: kDocumentScopeCompanyWide,
          label: 'مستندات الشركة العامة',
          icon: Icons.business_outlined,
        ),
        for (final Project project in data.myProjects)
          AvahiDropdownItem<String?>(
            value: project.id,
            label: project.name,
            icon: Icons.apartment_outlined,
          ),
      ],
      onChanged: onChanged,
    );
  }
}
