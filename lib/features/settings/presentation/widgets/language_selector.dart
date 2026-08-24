import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// خيار لغة واحد يعرضه [LanguageSelector].
class LanguageOption {
  const LanguageOption({
    required this.languageCode,
    required this.nativeName,
    required this.englishName,
    required this.flagEmoji,
  });

  final String languageCode;

  /// اسم اللغة بلغتها نفسها (مثال: "العربية").
  final String nativeName;

  /// اسم اللغة بالإنجليزية (مثال: "Arabic") — يُعرض كنص ثانوي صغير
  /// بغض النظر عن اللغة الحالية، ليبقى مفهوماً لمن يبحث عن خيار لغة
  /// لا يقرأ لغتها الحالية أصلاً (سيناريو تبديل اللغة تحديداً).
  final String englishName;

  final String flagEmoji;
}

/// منتقي لغة بصري (بطاقتان جنباً إلى جنب) — يُستخدم في
/// `language_settings.dart` فقط، بديل عن [AvahiDropdown] العام لأن
/// خيارين ثابتين فقط (عربي/إنجليزي) يستحقان عرضاً بصرياً أوضح
/// (علم + اسم أصلي + اسم إنجليزي) بدل قائمة منسدلة نصية عادية.
///
/// مكوّن عرض بحت — [onSelected] هو من يقرر فعلياً استدعاء
/// `LocaleCubit.setLocale` من طبقة الاستدعاء.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    required this.options,
    required this.selectedLanguageCode,
    required this.onSelected,
    super.key,
  });

  final List<LanguageOption> options;
  final String selectedLanguageCode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final LanguageOption option in options) ...<Widget>[
          Expanded(
            child: _LanguageCard(
              option: option,
              isSelected: option.languageCode == selectedLanguageCode,
              onTap: () => onSelected(option.languageCode),
            ),
          ),
          if (option != options.last) const SizedBox(width: AvahiSpacing.sm),
        ],
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final LanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AvahiRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: AvahiSpacing.lg,
          horizontal: AvahiSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AvahiRadius.md),
          color: isSelected ? colors.brandContainer : colors.surface,
          border: Border.all(
            color: isSelected ? colors.brand : colors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(option.flagEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: AvahiSpacing.xs),
            Text(
              option.nativeName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.onBrandContainer : colors.onSurface,
                  ),
            ),
            const SizedBox(height: AvahiSpacing.xxs),
            Text(
              option.englishName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? colors.onBrandContainer.withValues(alpha: 0.8)
                        : colors.onSurfaceVariant,
                  ),
            ),
            if (isSelected) ...<Widget>[
              const SizedBox(height: AvahiSpacing.xs),
              Icon(Icons.check_circle, color: colors.brand, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
