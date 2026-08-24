import '../../../../domain/enums/task_priority.dart';
import '../../../../ui/widgets/common/avahi_dropdown.dart';

/// عناصر [AvahiDropdown] الجاهزة لاختيار [TaskPriority] — تسميات
/// عربية موحّدة، بنفس القيم النصية المستخدمة في
/// `task_filter_bar.dart` (`features/tasks/presentation/widgets/`)
/// تماماً، لكن مُستخرَجة هنا كقائمة قابلة لإعادة الاستخدام مباشرة عبر
/// `punch_item_create.dart` (لا يوجد نموذج إنشاء مكافئ في `tasks/`
/// يفرض إخراج مماثل هناك بعد).
String punchPriorityLabelAr(TaskPriority priority) => switch (priority) {
      TaskPriority.low => 'منخفضة',
      TaskPriority.medium => 'متوسطة',
      TaskPriority.high => 'عالية',
      TaskPriority.urgent => 'عاجلة',
    };

final List<AvahiDropdownItem<TaskPriority>> kTaskPriorityDropdownItems =
    TaskPriority.values
        .map(
          (TaskPriority p) => AvahiDropdownItem<TaskPriority>(
            value: p,
            label: punchPriorityLabelAr(p),
          ),
        )
        .toList(growable: false);
