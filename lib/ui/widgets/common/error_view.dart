import 'package:flutter/material.dart';

import '../../theme/avahi_colors.dart';
import '../../theme/avahi_spacing.dart';
import 'avahi_button.dart';

/// عرض حالة خطأ موحّد — أيقونة تحذيرية، عنوان، وصف الخطأ، وزر "إعادة
/// المحاولة" اختياري.
///
/// مكوّن عرض بحت — لا يحمل أي منطق التقاط أخطاء فعلي؛ يُستدعى من طبقة
/// العرض عند استقبال حالة خطأ من الـ Cubit (لاحقاً).
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.title,
    super.key,
    this.message,
    this.icon = Icons.error_outline,
    this.retryLabel,
    this.onRetry,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AvahiSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: colors.danger),
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
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: AvahiSpacing.lg),
              AvahiButton(
                label: retryLabel ?? 'إعادة المحاولة',
                icon: Icons.refresh,
                variant: AvahiButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
