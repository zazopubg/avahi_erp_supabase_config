import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 🆕 (Prompt 27) يدير اللغة الفعّالة الحالية للتطبيق كاملاً —
/// [Locale] القياسي في Flutter، محصور بـ [AvahiApp.supportedLocales]
/// (`ar`/`en`) فقط.
///
/// ⚠️ نطاق متعمَّد (انظر توثيق القرار الكامل في
/// `features/settings/presentation/screens/language_settings.dart`):
/// هذا الـ Cubit يبدّل [Locale] الفعلي في `MaterialApp.router` +
/// [Directionality] عبر `AvahiDirectionalityProvider` بشكل حقيقي وكامل
/// (وليس شكلياً) — كل ما يعتمد على `Directionality.of(context)`/
/// `Localizations.localeOf(context)` (تخطيطات RTL/LTR، منتقيات
/// التاريخ/الوقت القياسية لـ Material) يستجيب فوراً. لكن نصوص واجهة
/// المستخدم *داخل* شاشات الميزات السابقة (Prompt 01–26) مكتوبة كسلاسل
/// عربية حرفية مباشرة (`Text('...')`) دون طبقة ترجمة (`AppLocalizations`)
/// من الأساس — تبديل هذا الـ Cubit وحده لن يُترجم تلك الشاشات تلقائياً؛
/// ذلك يتطلب استبدال كل سلسلة نصية حرفية عبر كامل التطبيق بمفتاح
/// ترجمة، وهو عمل يتجاوز نطاق ميزة `settings/` نفسها بمراحل (يحتاج
/// Prompt مستقل يمر على الأربعة والعشرين ميزة سابقة كلها). ميزة
/// `settings/` نفسها (كل شاشاتها الثماني) مبنية بترجمة داخلية كاملة
/// تستجيب لهذا الـ Cubit فعلياً كمرجع/نموذج لما ستبدو عليه بقية
/// التطبيق عند تعميم [AppLocalizations] لاحقاً.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({Locale initialLocale = const Locale('ar')})
      : super(initialLocale);

  void setLocale(Locale locale) => emit(locale);

  void setArabic() => emit(const Locale('ar'));

  void setEnglish() => emit(const Locale('en'));

  bool get isArabic => state.languageCode == 'ar';
}
