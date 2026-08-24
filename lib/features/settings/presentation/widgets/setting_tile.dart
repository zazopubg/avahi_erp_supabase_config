import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// صف إعداد موحّد — الوحدة البصرية الأساسية المكرَّرة عبر كل شاشات
/// `features/settings/` (`settings_screen.dart` كقائمة تنقّل رئيسية،
/// وبقية الشاشات الفرعية كصفوف تبديل/اختيار فردية)، بنفس فلسفة
/// `RoleBadge`/`StatusBadge`: مكوّن عرض بحت واحد بدل تكرار
/// `ListTile` مُخصَّص يدوياً في كل شاشة.
///
/// ثلاثة أنماط عبر [trailing] الاختياري:
/// 1. لا شيء (`trailing: null`) + [onTap] محدَّد → صف تنقّل عادي
///    (سهم `>` تلقائي إن كان [showChevron] `true`، الافتراضي).
/// 2. [trailing] مخصص (مثال: [Switch]/[SyncIndicator]) → يُعرض كما هو
///    دون سهم تنقّل تلقائي (يُفترض أن يكون الصف بلا `onTap` عندها،
///    أو `onTap` منفصل عن فعل التبديل — القرار يبقى لطبقة الاستدعاء).
class SettingTile extends StatelessWidget {
  const SettingTile({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.isDestructive = false,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// عند `true` (الافتراضي) ولا [trailing] مخصص ولا [onTap] فارغة،
  /// يُعرض سهم `chevron_forward_ios`/`chevron_left` (مُعكوس تلقائياً
  /// اتجاهياً عبر `Icons.arrow_forward_ios` + `Directionality`
  /// القياسي في Flutter، دون حاجة لتبديل يدوي حسب اللغة).
  final bool showChevron;

  /// عند `true`، يُلوَّن العنوان/الأيقونة بلون خطر (مثال: صف "تسجيل
  /// الخروج" أو "حذف الحساب" مستقبلاً) — بنفس دلالة
  /// `AvahiButtonVariant.danger`.
  final bool isDestructive;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final Color contentColor = !enabled
        ? colors.onSurfaceVariant
        : (isDestructive ? colors.danger : colors.onSurface);

    final Widget? effectiveTrailing = trailing ??
        (onTap != null && showChevron
            ? Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurfaceVariant)
            : null);

    return ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: icon != null
          ? Icon(icon, color: contentColor)
          : null,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: contentColor,
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: AvahiSpacing.xxs),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            )
          : null,
      trailing: effectiveTrailing,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AvahiSpacing.md,
        vertical: AvahiSpacing.xxs,
      ),
    );
  }
}

/// عنوان قسم بسيط يفصل مجموعات [SettingTile] ضمن نفس الشاشة (مثال:
/// "العرض" / "النظام" في `settings_screen.dart`).
class SettingSectionHeader extends StatelessWidget {
  const SettingSectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AvahiSpacing.md,
        AvahiSpacing.lg,
        AvahiSpacing.md,
        AvahiSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.brand,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
