import 'package:flutter/material.dart';

import '../../theme/avahi_colors.dart';
import '../../theme/avahi_spacing.dart';

/// شريط تنبيه ثابت أعلى الشاشة يظهر عند فقدان الاتصال بالإنترنت — أساسي
/// في تطبيق ميداني يعمل غالباً Offline-first.
///
/// مكوّن عرض بحت — يستقبل [isOffline] من طبقة أعلى (مثلاً Cubit مرتبط
/// بـ connectivity_plus لاحقاً) ولا يحمل أي منطق فحص اتصال فعلي بنفسه.
///
/// يُستخدم عادة كأعلى عنصر في `Scaffold.body` عبر `AnimatedSize` أو
/// مباشرة كشريط ثابت:
///
/// ```dart
/// Column(
///   children: [
///     OfflineBanner(isOffline: state.isOffline),
///     Expanded(child: content),
///   ],
/// )
/// ```
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.isOffline,
    super.key,
    this.message,
  });

  final bool isOffline;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: !isOffline
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              color: colors.warningContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: AvahiSpacing.md,
                vertical: AvahiSpacing.xs,
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.wifi_off,
                      size: 16,
                      color: colors.onWarningContainer,
                    ),
                    const SizedBox(width: AvahiSpacing.xs),
                    Flexible(
                      child: Text(
                        message ?? 'لا يوجد اتصال بالإنترنت — سيتم '
                            'حفظ التغييرات محلياً ومزامنتها لاحقاً.',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.onWarningContainer),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
