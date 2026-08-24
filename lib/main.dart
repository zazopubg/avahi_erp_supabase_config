import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'ui/theme/avahi_theme.dart';

/// نقطة دخول تطبيق Avahi.
///
/// ✅ Prompt 11: أول إقلاع حقيقي — `bootstrap()` (`lib/bootstrap.dart`)
/// يُهيّئ Supabase وقاعدة البيانات المحلية وحاوية حقن التبعيات ومحرك
/// المزامنة قبل أي `runApp`. عند فشل أي مرحلة حرجة منها، يُعرض
/// [_BootstrapErrorApp] بدل [AvahiApp] بدل شاشة بيضاء أو Crash صامت.
void main() async {
  final BootstrapResult result = await bootstrap();

  runApp(
    switch (result) {
      BootstrapSuccess() => const AvahiApp(),
      BootstrapError(:final String message) =>
        _BootstrapErrorApp(message: message),
    },
  );
}

/// شاشة خطأ إقلاع بسيطة ومستقلة تماماً عن [AvahiApp] (لا تعتمد على أي
/// شيء فشلت تهيئته للتو: لا حقن تبعيات، لا Supabase) — الهدف الوحيد
/// إعلام المستخدم بوضوح مع خيار إعادة المحاولة (إعادة تحميل الصفحة).
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AvahiTheme.light,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'تعذّر إقلاع التطبيق',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
