import 'package:flutter/material.dart';

import 'avahi_colors.dart';

/// نظام الظلال (Elevation Shadows) الموحّد لتطبيق Avahi.
///
/// يوفّر مجموعات ظلال جاهزة بمستويات ارتفاع مختلفة، محسوبة بناءً على
/// لون الظل الدلالي في [AvahiColors.shadow] حسب النمط الحالي
/// (فاتح/داكن).
abstract class AvahiShadows {
  /// بدون ظل.
  static const List<BoxShadow> none = <BoxShadow>[];

  /// ظل خفيف جداً — لعناصر شبه مسطحة (شارات، حقول الإدخال).
  static List<BoxShadow> xs(AvahiColors colors) => <BoxShadow>[
        BoxShadow(
          color: colors.shadow.withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// ظل خفيف — للبطاقات (Cards) في حالتها الافتراضية.
  static List<BoxShadow> sm(AvahiColors colors) => <BoxShadow>[
        BoxShadow(
          color: colors.shadow.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// ظل متوسط — للعناصر العائمة (قوائم منسدلة، حوارات صغيرة).
  static List<BoxShadow> md(AvahiColors colors) => <BoxShadow>[
        BoxShadow(
          color: colors.shadow.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// ظل بارز — للحوارات الكبيرة واللوحات السفلية (Bottom Sheets).
  static List<BoxShadow> lg(AvahiColors colors) => <BoxShadow>[
        BoxShadow(
          color: colors.shadow.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// ظل قوي جداً — لعناصر بأعلى مستوى ارتفاع (Modals كبيرة).
  static List<BoxShadow> xl(AvahiColors colors) => <BoxShadow>[
        BoxShadow(
          color: colors.shadow.withValues(alpha: 0.16),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];
}
