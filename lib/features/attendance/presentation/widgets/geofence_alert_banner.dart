import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// شريط تحذير الجيوفنسينغ — يظهر أعلى `check_in_screen.dart` عند
/// [AttendanceCheckInGeofenceWarning]: تسجيل الحضور **تم فعلاً** رغم
/// وقوع المستخدم خارج نطاق موقع المشروع المسموح به؛ هذا تحذير تفاعلي
/// إعلامي فقط، وليس رفضاً صريحاً للعملية (السجل محفوظ سلفاً بحالة
/// [AttendanceType.pending] بانتظار مراجعة يدوية من المشرف).
///
/// مكوّن عرض بحت، بنفس أسلوب `offline_banner.dart` (حاوية ملوّنة +
/// أيقونة + نص + إجراء اختياري)، بلون [AvahiColors.warning] بدل
/// [AvahiColors.info] المستخدم في حالة عدم الاتصال.
class GeofenceAlertBanner extends StatelessWidget {
  const GeofenceAlertBanner({
    required this.distanceMeters,
    super.key,
    this.onDismiss,
  });

  /// المسافة التقريبية بالأمتار خارج نطاق الجيوفنسينغ المسموح.
  final double? distanceMeters;

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final String distanceText = distanceMeters != null
        ? 'أنت على بُعد ${distanceMeters!.round()} متراً تقريباً من موقع المشروع المحدد.'
        : 'موقعك الحالي خارج نطاق موقع المشروع المحدد.';

    return Container(
      padding: const EdgeInsets.all(AvahiSpacing.sm),
      decoration: BoxDecoration(
        color: colors.warningContainer,
        borderRadius: AvahiRadius.radiusMd,
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: colors.onWarningContainer),
          const SizedBox(width: AvahiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'تم تسجيل حضورك خارج الموقع المحدد',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onWarningContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AvahiSpacing.xxs),
                Text(
                  '$distanceText سيبقى السجل محفوظاً وبانتظار مراجعة المشرف.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onWarningContainer,
                      ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: colors.onWarningContainer),
              tooltip: 'إغلاق',
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
