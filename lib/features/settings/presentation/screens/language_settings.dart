import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/local_settings_service.dart';
import '../../../../ui/modes/locale_provider.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../widgets/language_selector.dart';

/// شاشة اللغة — تتحكم فعلياً بـ [LocaleCubit] (Prompt 27): التبديل هنا
/// يُغيّر [Locale] الفعّال في `MaterialApp.router` بأكمله + اتجاه
/// الشاشة (RTL/LTR عبر `AvahiDirectionalityProvider`) فوراً، ليس فقط
/// شكلياً ضمن هذه الشاشة.
///
/// ⚠️ نطاق متعمَّد — اقرأ التوثيق الكامل في `ui/modes/locale_provider.dart`
/// قبل تعديل هذا الملف: تبديل [Locale] الفعلي لا يُترجم تلقائياً نصوص
/// الشاشات الأخرى (24 ميزة سابقة) المكتوبة بسلاسل عربية حرفية مباشرة؛
/// هذه الشاشة نفسها مكتوبة بترجمة داخلية (`_LanguageText`) كنموذج حي
/// لما ستبدو عليه ميزة مترجمة بالكامل لاحقاً.
class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  static const List<LanguageOption> _options = <LanguageOption>[
    LanguageOption(
      languageCode: 'ar',
      nativeName: 'العربية',
      englishName: 'Arabic',
      flagEmoji: '🇮🇶',
    ),
    LanguageOption(
      languageCode: 'en',
      nativeName: 'English',
      englishName: 'English',
      flagEmoji: '🇬🇧',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final Locale locale = context.watch<LocaleCubit>().state;
    final bool isArabic = locale.languageCode == 'ar';
    final _LanguageText text = isArabic ? _LanguageText.ar : _LanguageText.en;

    return Directionality(
      // ⚠️ هذه الشاشة تُطبِّق اتجاهها الخاص محلياً فوراً (بدل انتظار
      // إعادة بناء `MaterialApp.router` كاملة من `app.dart`) لتفادي
      // "وميض" اتجاه خاطئ للحظة بين الضغط وإعادة البناء العلوي —
      // `AppBar`/`Scaffold` هنا يستجيبان بصرياً على الفور، بينما بقية
      // شجرة التطبيق تتبع خلال نفس الإطار (Frame) عبر `app.dart`.
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(text.title)),
        body: ListView(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          children: <Widget>[
            Text(
              text.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AvahiSpacing.lg),
            LanguageSelector(
              options: _options,
              selectedLanguageCode: locale.languageCode,
              onSelected: (String code) => _onSelected(context, code),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSelected(BuildContext context, String languageCode) async {
    final LocaleCubit cubit = context.read<LocaleCubit>();
    if (languageCode == 'ar') {
      cubit.setArabic();
    } else {
      cubit.setEnglish();
    }
    await sl<LocalSettingsService>().saveLanguageCode(languageCode);
  }
}

/// نصوص هذه الشاشة تحديداً بلغتين — مثال حي مصغّر لِما ستكون عليه
/// طبقة `AppLocalizations` عند تعميمها لاحقاً على كامل التطبيق (انظر
/// توثيق القرار في `LocaleCubit`).
class _LanguageText {
  const _LanguageText({required this.title, required this.description});

  final String title;
  final String description;

  static const _LanguageText ar = _LanguageText(
    title: 'اللغة',
    description: 'اختر اللغة التي تفضّل عرض التطبيق بها. سيتغيّر اتجاه '
        'الشاشة تلقائياً (من اليمين لليسار للعربية، ومن اليسار لليمين '
        'للإنجليزية).',
  );

  static const _LanguageText en = _LanguageText(
    title: 'Language',
    description: 'Choose the language you prefer for the app. The screen '
        'direction will switch automatically (right-to-left for Arabic, '
        'left-to-right for English).',
  );
}
