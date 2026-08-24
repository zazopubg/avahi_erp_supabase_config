import 'package:flutter/material.dart';

/// مثال ودجة خاصة بميزة `__feature_name__` — عنصر بطاقة واحد لقائمة
/// العناصر، بنفس نمط `documents/presentation/widgets/document_card.dart`
/// أو `equipment/presentation/widgets/equipment_card.dart` (إن وُجدت).
///
/// TODO: أعد تسمية هذا الملف/الصنف واستبدل المحتوى بعنصر عرض ميزتك
/// الفعلي — استخدم دوماً `AvahiColors`/`AvahiSpacing`/`AvahiRadius`
/// (لا ألوان/مسافات حرّة) والخصائص المنطقية الاتجاهية لـ RTL (لا
/// `EdgeInsets.only(left:/right:)` مباشرة) — انظر
/// docs/ui_guidelines/color_system.md و docs/ui_guidelines/rtl_rules.md.
class __FeatureName__Card extends StatelessWidget {
  const __FeatureName__Card({required this.title, super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
      ),
    );
  }
}
