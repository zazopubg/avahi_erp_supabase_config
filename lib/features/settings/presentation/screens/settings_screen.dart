import 'package:flutter/material.dart';

import '../widgets/setting_tile.dart';
import 'about_screen.dart';
import 'display_settings.dart';
import 'glove_mode_settings.dart';
import 'language_settings.dart';
import 'notification_settings.dart';
import 'profile_screen.dart';
import 'sync_settings.dart';

/// الشاشة الرئيسية لميزة `features/settings/` (Prompt 27) — قائمة
/// تنقّل بحتة تقود لكل الشاشات الفرعية السبع، مسجَّلة على
/// `RouteNames.settings`/`RoutePaths.settings` (`app_router.dart`).
///
/// ⚠️ توزيع المسؤولية بين هذه الشاشة و`SettingsCubit`: هذه الشاشة
/// **لا تحمل أي حالة إطلاقاً** (لا `BlocProvider` هنا) — كل شاشة فرعية
/// مسؤولة عن حالتها بنفسها عند فتحها فعلياً:
/// - `glove_mode_settings.dart`/`display_settings.dart`/
///   `language_settings.dart` تقرأ/تكتب `GloveModeCubit`/`DarkModeCubit`/
///   `TextScaleCubit`/`LocaleCubit` مباشرة (مزوَّدة أصلاً على مستوى
///   `AvahiApp` كاملاً في `app.dart` — لا حاجة لتزويدها هنا مجدداً).
/// - `sync_settings.dart`/`notification_settings.dart` هما فقط من
///   يحتاجان `SettingsCubit` فعلياً (البيانات الوحيدة التي تحتاج بثاً
///   حياً/طلبات صريحة) — كل منهما يُزوِّد نسخته الخاصة عبر
///   `BlocProvider(create: (_) => sl<SettingsCubit>()..loadInitial())`
///   عند فتحها هي، وليس هنا على مستوى القائمة الرئيسية، لتفادي إبقاء
///   اشتراك `stateStream` حياً طوال وجود `settings_screen.dart` نفسها
///   دون داعٍ إن لم يفتح المستخدم تلك الشاشتين تحديداً إطلاقاً.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: <Widget>[
          const SettingSectionHeader(title: 'الحساب'),
          SettingTile(
            icon: Icons.person_outline,
            title: 'الملف الشخصي',
            subtitle: 'بياناتك، دورك، والشركة الحالية',
            onTap: () => _push(context, const ProfileScreen()),
          ),
          const SettingSectionHeader(title: 'العرض والاستخدام'),
          SettingTile(
            icon: Icons.back_hand_outlined,
            title: 'وضع القفازات',
            subtitle: 'تكبير أزرار وعناصر اللمس للعمل الميداني',
            onTap: () => _push(context, const GloveModeSettings()),
          ),
          SettingTile(
            icon: Icons.brightness_6_outlined,
            title: 'العرض',
            subtitle: 'المظهر الداكن/الفاتح، وحجم النص',
            onTap: () => _push(context, const DisplaySettings()),
          ),
          SettingTile(
            icon: Icons.language_outlined,
            title: 'اللغة',
            subtitle: 'العربية / English',
            onTap: () => _push(context, const LanguageSettings()),
          ),
          const SettingSectionHeader(title: 'البيانات'),
          SettingTile(
            icon: Icons.sync_outlined,
            title: 'المزامنة',
            subtitle: 'حالة المزامنة، مزامنة يدوية، وضبط التلقائي',
            onTap: () => _push(context, const SyncSettings()),
          ),
          SettingTile(
            icon: Icons.notifications_outlined,
            title: 'الإشعارات',
            subtitle: 'تصنيفات الإشعارات وإذن المتصفح',
            onTap: () => _push(context, const NotificationSettings()),
          ),
          const SettingSectionHeader(title: 'عن التطبيق'),
          SettingTile(
            icon: Icons.info_outline,
            title: 'حول Avahi',
            subtitle: 'الإصدار، البيئة، ومعلومات الدعم',
            onTap: () => _push(context, const AboutScreen()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}
