import 'package:avahi/ui/modes/glove_mode_provider.dart';
import 'package:avahi/ui/rtl/directionality_provider.dart';
import 'package:avahi/ui/theme/avahi_theme.dart';
import 'package:avahi/ui/theme/text_scale_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// امتداد مساعد على [WidgetTester] يبسّط تركيب شجرة اختبار واقعية لكل
/// ملفات `test/widget/` و`test/golden/` — يعيد إنتاج نفس تركيبة
/// `AvahiApp` الحقيقية (`lib/app.dart`) بالحد الأدنى الضروري فقط:
/// [MaterialApp] بثيم [AvahiTheme.light]، اتجاه RTL افتراضي عبر
/// [AvahiDirectionalityProvider] (نفس لغة `Locale('ar')` الافتراضية)،
/// و[GloveModeCubit] متاح دوماً (يستهلكه [AvahiButton] عبر
/// `context.watch` في كل مكان — بلا تزويده هنا يفشل أي اختبار يبني
/// زراً واحداً على الأقل).
extension PumpAppExtension on WidgetTester {
  Future<void> pumpAvahiApp(
    Widget widget, {
    List<BlocProvider<dynamic>> additionalProviders = const <BlocProvider<dynamic>>[],
    bool gloveModeEnabled = false,
    Locale locale = const Locale('ar'),
    double textScale = 1.0,
  }) async {
    await pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<GloveModeCubit>(
            create: (_) => GloveModeCubit(initialValue: gloveModeEnabled),
          ),
          ...additionalProviders,
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AvahiTheme.light,
          locale: locale,
          supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (BuildContext context, Widget? child) {
            final MediaQueryData mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              // نضبط textScaler هنا بمقياس النظام "الخام" (قبل الحصر)
              // ليمرّ لاحقاً عبر [TextScaleGuard] تماماً كما يحدث في
              // `app.dart` الحقيقي — وليس تجاوزاً مباشراً غير محكوم.
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: TextScaleGuard(
                child: AvahiDirectionalityProvider(
                  locale: locale,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          home: Scaffold(body: widget),
        ),
      ),
    );
  }
}
