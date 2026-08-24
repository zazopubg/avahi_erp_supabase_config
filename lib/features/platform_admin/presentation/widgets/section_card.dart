import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_spacing.dart';

/// بطاقة قسم موحّدة تُستخدم عبر كل ألسنة `admin_dashboard.dart` —
/// عنوان + محتوى ضمن حدود بطاقة متسقة بصرياً، بنفس تصميم
/// `SectionCard` في `features/analytics/` تماماً (مُستنسخة محلياً هنا
/// بدل استيراد عابر للميزات — كل ميزة تبقى مستقلة بذاتها بنفس نمط بقية
/// `features/` في هذا المشروع). 🆕 (Prompt 28)
class PlatformSectionCard extends StatelessWidget {
  const PlatformSectionCard({
    required this.title,
    required this.child,
    super.key,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AvahiSpacing.sm),
          child,
        ],
      ),
    );
  }
}
