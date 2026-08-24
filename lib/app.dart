import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection_container.dart';
import 'core/services/local_settings_service.dart';
import 'domain/repositories/repositories.dart';
import 'features/auth/presentation/state/auth_cubit.dart';
import 'navigation/app_router.dart';
import 'ui/modes/dark_mode_provider.dart';
import 'ui/modes/glove_mode_provider.dart';
import 'ui/modes/locale_provider.dart';
import 'ui/modes/text_scale_provider.dart';
import 'ui/rtl/directionality_provider.dart';
import 'ui/theme/avahi_theme.dart';
import 'ui/theme/text_scale_guard.dart';

/// نقطة الجذر لتطبيق Avahi.
///
/// ✅ Prompt 12: أصبح `AvahiApp` الآن `StatefulWidget` (بدل
/// `StatelessWidget` في Prompt 01) لسبب واحد ووحيد: يحتاج بناء
/// [AppRouter] (`navigation/app_router.dart`) **مرة واحدة فقط** عبر
/// `initState` والاحتفاظ به طوال عمر الودجة (وليس إعادة إنشائه عند كل
/// `build`، لأنه يحمل اشتراكاً فعلياً بـ `IAuthRepository.watchAuthState()`
/// عبر `refreshListenable` — إعادة إنشائه في كل `build` سيُنشئ اشتراكات
/// متسربة (Leaked Subscriptions) دون تحرير القديمة أبداً)، ثم تحريره
/// (`AppRouter.dispose()`) عبر `dispose` عند إزالة الودجة.
class AvahiApp extends StatefulWidget {
  const AvahiApp({super.key});

  /// اللغة الافتراضية للتطبيق: العربية (RTL).
  static const Locale defaultLocale = Locale('ar');

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  @override
  State<AvahiApp> createState() => _AvahiAppState();
}

class _AvahiAppState extends State<AvahiApp> {
  /// 🆕 (Prompt 27) القيم الابتدائية لكل Cubit تُقرأ **متزامناً** من
  /// [LocalSettingsService] هنا (وليس async لاحقاً بعد أول `build`)
  /// لتفادي "وميض" مرئي (Flash) بالقيم الافتراضية قبل تطبيق تفضيل
  /// المستخدم المحفوظ فعلياً — آمن لأن `bootstrap.dart` ينتظر
  /// `sl<LocalSettingsService>().init()` بالكامل **قبل** `runApp`
  /// (`main.dart`)، أي أن `AvahiApp` لا يُبنى إطلاقاً قبل اكتمال تلك
  /// التهيئة.
  final LocalSettingsService _settingsService = sl<LocalSettingsService>();

  /// يُبنى بحقن `IAuthRepository` من حاوية `sl` (مُهيَّأة بالفعل قبل
  /// `runApp` عبر `bootstrap()` — انظر `bootstrap.dart` و`main.dart`)،
  /// وليس عبر `sl<AppRouter>()`: [AppRouter] ليس مسجَّلاً في حاوية حقن
  /// التبعيات عمداً (`core/di/`) لأن عمره مرتبط تحديداً بعمر ودجة
  /// `AvahiApp` نفسها (`State` واحدة، وليس Singleton تطبيق كامل) —
  /// إعادة بنائه هنا بدل حقنه يُبقي هذا الربط صريحاً وواضحاً.
  late final AppRouter _appRouter = AppRouter(
    authRepository: sl<IAuthRepository>(),
  );

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<GloveModeCubit>(
          create: (_) => GloveModeCubit(
            initialValue: _settingsService.readGloveMode(),
          ),
        ),
        BlocProvider<DarkModeCubit>(
          create: (_) => DarkModeCubit(
            initialMode: _themeModeFromName(_settingsService.readThemeModeName()),
          ),
        ),
        // 🆕 (Prompt 27) — انظر توثيق نطاق القرار الكامل في
        // `ui/modes/locale_provider.dart`.
        BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit(
            initialLocale: Locale(_settingsService.readLanguageCode() ?? 'ar'),
          ),
        ),
        BlocProvider<TextScaleCubit>(
          create: (_) => TextScaleCubit(
            initialScale: _settingsService.readTextScale(),
          ),
        ),
        // مزوَّد مرة واحدة على مستوى التطبيق كاملاً (وليس داخل
        // `features/auth/` فقط): تحتاجه شاشات تدفّق الدخول
        // (`SplashScreen`/`LoginScreen`/`PinScreen`/`CompanySelectScreen`)
        // بقدر ما تحتاجه وجهات `AdaptiveShell` لاحقاً (زر تسجيل خروج،
        // عرض المستخدم/الشركة الحاليين في الشريط العلوي...) — نفس نمط
        // `GloveModeCubit`/`DarkModeCubit` أعلاه تماماً.
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
      ],
      child: BlocBuilder<DarkModeCubit, ThemeMode>(
        builder: (BuildContext context, ThemeMode themeMode) {
          // 🆕 (Prompt 27) [LocaleCubit]/[TextScaleCubit] تُقرآن عبر
          // `context.watch` (وليس `BlocBuilder` متداخلة إضافية) لتفادي
          // ثلاثة مستويات تعشيش غير ضرورية — كلاهما يُعيد بناء هذا
          // الودجة بالكامل فور تغيّرهما تماماً كما لو كانا
          // `BlocBuilder` صريحتين، لأن `_AvahiAppState.build` بأكملها
          // (بما فيها `BlocProvider`s) تُعاد أصلاً عند أي `setState`/
          // تحديث `InheritedWidget` أعلى منها في الشجرة.
          final Locale locale = context.watch<LocaleCubit>().state;
          final double textScale = context.watch<TextScaleCubit>().state;

          return MaterialApp.router(
            title: 'Avahi',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AvahiTheme.light,
            darkTheme: AvahiTheme.dark,

            // ── التوطين (Localization) ─────────────────────────
            // 🆕 (Prompt 27) [locale] لم يعد ثابتاً
            // (`AvahiApp.defaultLocale`) — يتبع [LocaleCubit.state]
            // فعلياً الآن (`language_settings.dart`). انظر توثيق نطاق
            // هذا التبديل الكامل في `ui/modes/locale_provider.dart`.
            locale: locale,
            supportedLocales: AvahiApp.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // ── حارس مقياس النص + الاتجاه (RTL افتراضياً) ──────
            builder: (BuildContext context, Widget? child) {
              return TextScaleGuard(
                userScale: textScale,
                child: AvahiDirectionalityProvider(
                  locale: locale,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },

            // ── التنقل (go_router) — Prompt 12 ──────────────────
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }

  /// 🆕 (Prompt 27) يحوّل الاسم النصي المحفوظ (`ThemeMode.name`، مثال:
  /// `'dark'`) إلى [ThemeMode] فعلي — `null`/قيمة غير معروفة ← الافتراضي
  /// [ThemeMode.system] (نفس الافتراضي القديم قبل هذه الخطوة، لضمان
  /// عدم تغيّر سلوك أي جلسة سابقة لم تحفظ تفضيلاً صراحة بعد).
  static ThemeMode _themeModeFromName(String? name) {
    return ThemeMode.values.firstWhere(
      (ThemeMode mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}
