import 'package:flutter/material.dart';

import '../../theme/avahi_spacing.dart';
import 'avahi_button.dart';

/// عرض حالة فارغة موحّد (لا توجد بيانات بعد) — أيقونة/رسمة، عنوان، وصف،
/// وزر إجراء اختياري (مثال: "إضافة مهمة جديدة").
///
/// مكوّن عرض بحت — لا يحمل أي منطق تحديد "متى تكون القائمة فارغة"؛ يُستدعى
/// من طبقة العرض (Presentation) عند الحاجة.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    super.key,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.illustration,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;

  /// أيقونة افتراضية تُستخدم عند عدم توفر [illustration] مخصصة.
  final IconData icon;

  /// عنصر رسم/صورة مخصص (مثلاً من `assets/images/empty_states/`) يحل
  /// محل الأيقونة الافتراضية إن تم تمريره.
  final Widget? illustration;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AvahiSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            illustration ??
                Icon(icon, size: 64, color: scheme.onSurfaceVariant),
            const SizedBox(height: AvahiSpacing.md),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AvahiSpacing.xs),
              Text(
                message!,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AvahiSpacing.lg),
              AvahiButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
