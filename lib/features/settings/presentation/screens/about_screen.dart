import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/env.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../widgets/setting_tile.dart';

/// شاشة "حول التطبيق" — تعرض [AppConfig.instance] الثابتة مباشرة
/// (بلا `BlocProvider`/حالة إطلاقاً؛ نفس نمط `profile_screen.dart` في
/// عدم الحاجة لـ `SettingsCubit`، انظر توثيق القرار في
/// `settings_screen.dart`). رقم الإصدار [_appVersion]/[_buildNumber]
/// مأخوذان يدوياً من `pubspec.yaml` (`version: 0.1.0+1`) — المشروع لا
/// يعتمد `package_info_plus` حالياً (لا حزمة جديدة أُضيفت لهذه الخطوة
/// تحديداً بخلاف `shared_preferences` الضرورية فعلياً لبقية الميزة)؛
/// إن أُضيفت لاحقاً، هذان الثابتان يُستبدلان بقراءة حقيقية من
/// `PackageInfo.fromPlatform()` دون أي تعديل آخر على هذه الشاشة.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _appVersion = '0.1.0';
  static const String _buildNumber = '1';
  static const String _supportEmail = 'support@avahi.app';

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final AppConfig config = AppConfig.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('حول Avahi')),
      body: ListView(
        padding: const EdgeInsets.all(AvahiSpacing.md),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colors.brandContainer,
                  child: Icon(
                    Icons.construction,
                    size: 40,
                    color: colors.onBrandContainer,
                  ),
                ),
                const SizedBox(height: AvahiSpacing.sm),
                Text(
                  'Avahi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AvahiSpacing.xxs),
                Text(
                  'الإصدار $_appVersion (بناء $_buildNumber)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AvahiSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline),
            ),
            child: Column(
              children: <Widget>[
                SettingTile(
                  icon: Icons.dns_outlined,
                  title: 'البيئة',
                  subtitle: config.apiBaseLabel,
                  showChevron: false,
                ),
                SettingTile(
                  icon: Icons.code_outlined,
                  title: 'رمز البناء',
                  subtitle: Env.buildLabel.isEmpty ? 'غير محدد' : Env.buildLabel,
                  showChevron: false,
                ),
                SettingTile(
                  icon: Icons.mail_outline,
                  title: 'الدعم الفني',
                  subtitle: _supportEmail,
                  onTap: () => _launchSupportEmail(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AvahiSpacing.xl),
          Center(
            child: Text(
              '© ${DateTime.now().year} Avahi — جميع الحقوق محفوظة.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchSupportEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: _supportEmail);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}
