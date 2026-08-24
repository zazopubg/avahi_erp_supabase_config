import 'package:flutter/widgets.dart';

import 'core/di/injection_container.dart';
import 'core/errors/app_exception.dart';
import 'core/services/local_settings_service.dart';
import 'core/utils/logger.dart';
import 'data/cloud/supabase/supabase_client_provider.dart';
import 'data/local/local_database.dart';
import 'data/sync/sync_scheduler.dart';

/// نتيجة [bootstrap] — إما نجاح تام، أو فشل بمرحلة واضحة ورسالة قابلة
/// للعرض، بدل ترك `main.dart` يتعامل مع استثناء خام غير متوقَّع.
sealed class BootstrapResult {
  const BootstrapResult();
}

/// نجحت كل مراحل الإقلاع الحرجة (Supabase + قاعدة البيانات المحلية +
/// حقن التبعيات). محرك المزامنة قد يكون بدأ أو لا (فشل بدئه غير حرج
/// — انظر [BootstrapResult.syncStartFailed] ضمن هذا الصنف).
final class BootstrapSuccess extends BootstrapResult {
  const BootstrapSuccess({this.syncStartFailed = false});

  /// صحيح إن نجح كل شيء حرج لكن تشغيل [SyncScheduler] تحديداً فشل
  /// (مثال: انقطاع اتصال فور الإقلاع) — غير كافٍ لإيقاف التطبيق عن
  /// الإقلاع أصلاً، لأن التطبيق Offline-first بطبيعته ويمكنه العمل دون
  /// مزامنة فورية وإعادة المحاولة لاحقاً عند استعادة الاتصال.
  final bool syncStartFailed;
}

/// فشلت إحدى مراحل الإقلاع **الحرجة** (لا يمكن للتطبيق العمل بدونها) —
/// `main.dart` يعرض شاشة خطأ واضحة بدل شاشة فارغة أو Crash صامت.
final class BootstrapError extends BootstrapResult {
  const BootstrapError({required this.stage, required this.message});

  /// اسم المرحلة التي فشلت (`'supabase'`, `'local_database'`,
  /// `'dependency_injection'`) — لأغراض التسجيل/التشخيص، وليس للعرض
  /// المباشر للمستخدم النهائي.
  final String stage;

  /// رسالة قابلة للعرض مباشرة ضمن شاشة خطأ الإقلاع (`main.dart`).
  final String message;
}

/// نقطة الإقلاع الموحّدة الوحيدة لتطبيق Avahi — يُستدعى مرة واحدة فقط
/// من `main()` **قبل** `runApp`. يُنفّذ بترتيب صارم لأن كل مرحلة تعتمد
/// على نجاح ما قبلها:
///
/// 1. `WidgetsFlutterBinding.ensureInitialized()` — إلزامي قبل أي
///    استدعاء async آخر يلمس منصّة Flutter (Supabase، Drift/Web...).
/// 2. `SupabaseClientProvider.initialize()` — يفشل بوضوح فوراً إن كانت
///    `SUPABASE_URL`/`SUPABASE_ANON_KEY` ناقصة بدل فشل غامض لاحقاً عند
///    أول استعلام.
/// 3. `configureDependencies()` (`core/di/injection_container.dart`) —
///    يُسجِّل كل شيء، ثم نفرض فتح [LocalDatabase] فوراً هنا (`sl<LocalDatabase>()`)
///    بدل الانتظار حتى أول استعلام فعلي من شاشة ما؛ أي خطأ في فتح
///    قاعدة البيانات المحلية (مثال: أصول `sqlite3.wasm` مفقودة على
///    الويب) يظهر هنا بوضوح أثناء الإقلاع، لا كشاشة بيضاء لاحقاً.
/// 4. 🆕 (Prompt 27) `sl<LocalSettingsService>().init()` — يحمّل
///    `SharedPreferences` مرة واحدة **قبل** إنشاء `AvahiApp` (`app.dart`
///    يقرأ `readGloveMode`/`readThemeModeName`/إلخ بشكل متزامن عند
///    `initState` لتهيئة `GloveModeCubit`/`DarkModeCubit`/`LocaleCubit`/
///    `TextScaleCubit` بالقيم المحفوظة — قراءة متزامنة قبل التهيئة
///    ستفشل). يُعامَل كخطوة حرجة (بخلاف `SyncScheduler.start()` أدناه)
///    لأن فشله يترك كل تفضيلات المستخدم بلا معنى طوال الجلسة.
/// 5. `SyncScheduler.start()` — غير حرج (انظر [BootstrapSuccess.syncStartFailed]).
Future<BootstrapResult> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseClientProvider.initialize();
  } on AppException catch (error) {
    AppLogger.error('bootstrap: فشلت تهيئة Supabase.', error: error);
    return BootstrapError(stage: 'supabase', message: error.message);
  } catch (error, stackTrace) {
    AppLogger.error(
      'bootstrap: خطأ غير متوقع أثناء تهيئة Supabase.',
      error: error,
      stackTrace: stackTrace,
    );
    return const BootstrapError(
      stage: 'supabase',
      message: 'تعذّر الاتصال بالخادم. تحقق من الشبكة وأعد المحاولة.',
    );
  }

  try {
    configureDependencies();
    // يفرض فتح اتصال قاعدة البيانات المحلية الآن (بدل تأجيله كسولاً
    // حتى أول استعلام فعلي من شاشة) — فشل الإقلاع المبكر الواضح أفضل
    // من شاشة بيضاء لاحقاً.
    sl<LocalDatabase>();
  } catch (error, stackTrace) {
    AppLogger.error(
      'bootstrap: فشل تهيئة حقن التبعيات أو قاعدة البيانات المحلية.',
      error: error,
      stackTrace: stackTrace,
    );
    return const BootstrapError(
      stage: 'dependency_injection',
      message: 'تعذّر تهيئة التطبيق محلياً. أعد تحميل الصفحة.',
    );
  }

  try {
    await sl<LocalSettingsService>().init();
  } catch (error, stackTrace) {
    AppLogger.error(
      'bootstrap: فشلت تهيئة إعدادات المستخدم المحلية (SharedPreferences).',
      error: error,
      stackTrace: stackTrace,
    );
    return const BootstrapError(
      stage: 'local_settings',
      message: 'تعذّر تحميل إعدادات المستخدم المحلية. أعد تحميل الصفحة.',
    );
  }

  bool syncStartFailed = false;
  try {
    await sl<SyncScheduler>().start();
  } catch (error, stackTrace) {
    // غير حرج عمداً — انظر توثيق [BootstrapSuccess.syncStartFailed].
    AppLogger.warning(
      'bootstrap: فشل بدء محرك المزامنة عند الإقلاع '
      '(${error.runtimeType}) — سيُعاد المحاولة تلقائياً لاحقاً.',
    );
    syncStartFailed = true;
    assert(() {
      AppLogger.debug('bootstrap: تفاصيل فشل المزامنة: $stackTrace');
      return true;
    }());
  }

  AppLogger.info('bootstrap: اكتمل إقلاع التطبيق بنجاح.');
  return BootstrapSuccess(syncStartFailed: syncStartFailed);
}
