import 'package:flutter/material.dart';

import '../../../../core/utils/gps_helper.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// مؤشر حالة إذن/خدمة الموقع الجغرافي الحالية — يُعرض أعلى
/// `check_in_screen.dart` عند اختيار طريقة GPS، ويوجّه المستخدم بوضوح
/// عند رفض الإذن أو تعطيل الخدمة قبل محاولة تسجيل حضور ستفشل حتماً.
///
/// مكوّن عرض بحت — يستقبل [status] الحالي من `AttendanceCubit`
/// (`AttendanceData.gpsStatus`) ولا يستدعي `geolocator` مباشرة؛ [onRetry]
/// اختياري يُستدعى عند الضغط على زر "إعادة الفحص" (يُفوَّض لـ
/// `AttendanceCubit.refreshGpsStatus`).
class GpsStatusIndicator extends StatelessWidget {
  const GpsStatusIndicator({
    required this.status,
    super.key,
    this.onRetry,
  });

  final GpsPermissionStatus status;
  final VoidCallback? onRetry;

  _GpsVisual _visualFor(GpsPermissionStatus status, AvahiColors colors) {
    return switch (status) {
      GpsPermissionStatus.granted => _GpsVisual(
          icon: Icons.gps_fixed,
          color: colors.success,
          label: 'إذن الموقع الجغرافي مُفعَّل.',
        ),
      GpsPermissionStatus.deniedOnce => _GpsVisual(
          icon: Icons.gps_not_fixed,
          color: colors.warning,
          label: 'إذن الموقع الجغرافي مطلوب لتسجيل الحضور عبر GPS.',
        ),
      GpsPermissionStatus.deniedForever => _GpsVisual(
          icon: Icons.gps_off,
          color: colors.danger,
          label: 'تم رفض إذن الموقع نهائياً — فعّله من إعدادات الجهاز.',
        ),
      GpsPermissionStatus.serviceDisabled => _GpsVisual(
          icon: Icons.location_disabled,
          color: colors.danger,
          label: 'خدمة الموقع الجغرافي معطّلة على هذا الجهاز.',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final _GpsVisual visual = _visualFor(status, colors);
    final bool needsAction = status != GpsPermissionStatus.granted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AvahiSpacing.sm,
        vertical: AvahiSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: AvahiRadius.radiusSm,
      ),
      child: Row(
        children: <Widget>[
          Icon(visual.icon, size: 18, color: visual.color),
          const SizedBox(width: AvahiSpacing.xs),
          Expanded(
            child: Text(
              visual.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: visual.color,
                  ),
            ),
          ),
          if (needsAction && onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'إعادة فحص إذن الموقع',
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}

class _GpsVisual {
  const _GpsVisual({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;
}
