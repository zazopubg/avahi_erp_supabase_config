import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';

/// نقطة الوصول الموحّدة لعميل Supabase (`SupabaseClient`) عبر كل طبقة
/// `data/cloud/supabase/`.
///
/// ⚠️ لا يقوم هذا الملف بأي تهيئة تلقائية عند الاستيراد؛ يجب استدعاء
/// [SupabaseClientProvider.initialize] مرة واحدة فقط أثناء الإقلاع
/// (`lib/bootstrap.dart`، Prompt 11) قبل استخدام [client] في أي مكان،
/// تماماً كما لم يُعدَّل `lib/main.dart` بعد لهذا الغرض (لا يزال ينتظر
/// Prompt 11). كل صفوف `*RepositoryImpl` في هذه الطبقة تستقبل
/// `SupabaseClient` عبر الحقن (Constructor Injection) بدل الاعتماد
/// المباشر على هذا الـ Singleton، لتبقى قابلة للاختبار (Unit Testing)
/// بسهولة عبر تمرير عميل وهمي (Mock/Fake).
abstract final class SupabaseClientProvider {
  static bool _initialized = false;

  /// يهيّئ اتصال Supabase عبر `Supabase.initialize` باستخدام قيم
  /// [Env.supabaseUrl]/[Env.supabaseAnonKey]. آمن للاستدعاء أكثر من
  /// مرة (يتجاهل الاستدعاءات اللاحقة بعد أول تهيئة ناجحة).
  static Future<void> initialize() async {
    if (_initialized) {
      AppLogger.debug('SupabaseClientProvider: تمت التهيئة مسبقاً، تجاهل.');
      return;
    }

    if (!Env.isConfigComplete) {
      throw const UnexpectedAppException(
        message:
            'إعدادات Supabase غير مكتملة (SUPABASE_URL/SUPABASE_ANON_KEY). '
            'تحقق من --dart-define أو ملف البيئة المستخدم عند البناء.',
      );
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
      debug: Env.current.isDev,
    );

    _initialized = true;
    AppLogger.info('SupabaseClientProvider: تمت التهيئة بنجاح.');
  }

  /// صحيح بعد نجاح [initialize] مرة واحدة على الأقل.
  static bool get isInitialized => _initialized;

  /// عميل Supabase الفعّال. يرمي [StateError] إن استُدعي قبل
  /// [initialize] — خطأ إقلاع مبكر متعمّد بدل فشل غامض لاحقاً.
  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'SupabaseClientProvider.client استُخدم قبل استدعاء initialize(). '
        'تأكد من استدعاء SupabaseClientProvider.initialize() أثناء '
        'bootstrap.dart قبل أي استخدام لطبقة data/cloud/supabase/.',
      );
    }
    return Supabase.instance.client;
  }

  /// اختصار شائع الاستخدام لعميل المصادقة (`client.auth`).
  static GoTrueClient get auth => client.auth;

  /// اختصار شائع الاستخدام لعميل التخزين (`client.storage`).
  static SupabaseStorageClient get storage => client.storage;

  /// معرّف المستخدم الحالي المسجّل دخوله، أو `null`.
  static String? get currentUserId => auth.currentUser?.id;
}
