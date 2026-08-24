import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../state/upload_queue_state.dart';

/// شريط حالة طابور الرفع — يُعرض أعلى `my_photos_screen.dart`/
/// `photo_gallery.dart` عندما يحتوي [UploadQueueState] عناصر معلّقة أو
/// فاشلة، مع زر "إعادة المحاولة الآن" لكل الفاشلة دفعة واحدة. يختفي
/// تلقائياً (`SizedBox.shrink`) عندما يكون الطابور فارغاً تماماً —
/// عرض بحت بلا أي منطق قرار "متى تُعاد المحاولة فعلياً" (ذلك بالكامل
/// مسؤولية `PhotoUploadProcessor`/`RetryPolicy`، هذا الشريط زناد يدوي
/// فقط).
class UploadProgressIndicator extends StatelessWidget {
  const UploadProgressIndicator({
    required this.queue,
    super.key,
    this.onRetryAllFailed,
  });

  final UploadQueueState queue;

  /// `null` يخفي زر "إعادة المحاولة" (مثال: أثناء عدم توفر اتصال أصلاً
  /// — لا فائدة من محاولة يدوية ستفشل فوراً بنفس السبب).
  final VoidCallback? onRetryAllFailed;

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) return const SizedBox.shrink();

    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final bool hasFailed = queue.failedCount > 0;

    final Color accent = hasFailed ? colors.danger : colors.warning;
    final Color background = hasFailed ? colors.dangerContainer : colors.warningContainer;
    final Color onBackground = hasFailed ? colors.onDangerContainer : colors.onWarningContainer;

    final String message = hasFailed
        ? '${queue.failedCount} صورة فشل رفعها — سيُعاد المحاولة تلقائياً، أو الآن يدوياً.'
        : '${queue.pendingCount} صورة بانتظار الرفع...';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AvahiSpacing.md,
        vertical: AvahiSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AvahiSpacing.md,
        vertical: AvahiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AvahiRadius.radiusMd,
      ),
      child: Row(
        children: <Widget>[
          if (!hasFailed)
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          else
            Icon(Icons.error_outline, size: 18, color: accent),
          const SizedBox(width: AvahiSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onBackground),
            ),
          ),
          if (hasFailed && onRetryAllFailed != null)
            TextButton(
              onPressed: onRetryAllFailed,
              child: Text('إعادة المحاولة', style: TextStyle(color: accent)),
            ),
        ],
      ),
    );
  }
}
