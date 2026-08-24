import 'dart:async';

import '../../core/services/local_settings_service.dart';
import '../../core/utils/logger.dart';
import '../../domain/enums/sync_state.dart';
import 'sync_engine.dart';

/// نقطة تحكم عالية المستوى لبدء/إيقاف [SyncEngine] بكامل استراتيجياته
/// دفعة واحدة — الواجهة التي يستدعيها `lib/bootstrap.dart` (Prompt 11)
/// بعد نجاح تسجيل الدخول واستعادة الجلسة، ويوقفها
/// `core/services/session_service.dart` (Prompt 02) عند تسجيل الخروج
/// لتفادي أي محاولة مزامنة بعد إبطال الجلسة الحالية.
///
/// هذا الفصل بين [SyncEngine] (المنطق) و[SyncScheduler] (التحكّم
/// بدورة حياته) يسمح لطبقة العرض (Cubit خاص بحالة المزامنة، خطوات
/// لاحقة) بالاعتماد على [SyncScheduler] فقط دون الحاجة لمعرفة أي
/// تفاصيل توصيل داخلية لمحرّك المزامنة نفسه.
class SyncScheduler {
  SyncScheduler(this._engine, {LocalSettingsService? settingsService})
      : _settingsService = settingsService {
    // 🆕 (Prompt 27) اشتراك داخلي بحالة المحرك لتسجيل "آخر وقت مزامنة
    // ناجحة" محلياً فور وصولها [SyncState.synced] — يستهلكها
    // `sync_settings.dart` عبر [lastSuccessfulSyncAt] دون الحاجة
    // لحقن `LocalSettingsService` بشكل منفصل في تلك الشاشة. لا تأثير
    // إن لم يُمرَّر [settingsService] (بقية استهلاك [SyncScheduler]
    // القديم منذ Prompt 09/11 يبقى يعمل دون أي تعديل مطلوب).
    if (_settingsService != null) {
      _stateSubscription = _engine.stateStream.listen((SyncState state) {
        if (state == SyncState.synced) {
          unawaited(_settingsService.saveLastSuccessfulSyncAt(DateTime.now()));
        }
      });
    }
  }

  final SyncEngine _engine;
  final LocalSettingsService? _settingsService;
  StreamSubscription<SyncState>? _stateSubscription;
  bool _isRunning = false;

  /// 🆕 (Prompt 27) هل استراتيجيات المزامنة التلقائية مُفعَّلة حالياً —
  /// منفصل عن [isRunning] (الذي يعكس فقط ما إذا كان [SyncEngine] بدأ
  /// أصلاً بغض النظر عن رغبة المستخدم). يبدأ `true` افتراضياً، ويعكس
  /// آخر تفضيل محفوظ عبر [LocalSettingsService.readSyncAutoEnabled]
  /// إن تحمّل `sync_settings.dart` مسؤولية إعادة تطبيقه عند الإقلاع
  /// (انظر `SettingsCubit.loadInitial`) — [SyncScheduler] نفسه لا
  /// يقرأ التفضيل المحفوظ تلقائياً عند الإنشاء عمداً، لأن ترتيب
  /// الإقلاع في `bootstrap.dart` يستدعي [start] قبل أن تُقرأ أي
  /// إعدادات مستخدم بعد؛ إيقافه لاحقاً (إن كان معطَّلاً) مسؤولية
  /// الطبقة الأعلى (`SettingsCubit`) صراحة.
  bool _autoEnabled = true;
  bool get isAutoEnabled => _autoEnabled;

  bool get isRunning => _isRunning;

  /// بثّ حي بحالة محرّك المزامنة — تمرير مباشر لـ
  /// `SyncEngine.stateStream` لتسهيل ربط `sync_settings.dart` دون
  /// حاجتها لحقن [SyncEngine] بشكل منفصل عن [SyncScheduler] نفسه.
  Stream<SyncState> get stateStream => _engine.stateStream;

  SyncState get currentState => _engine.currentState;

  bool get isOnline => _engine.isOnline;

  Stream<int> watchPendingCount() => _engine.watchPendingCount();

  /// آخر وقت مزامنة ناجحة معروف — مقروء مباشرة من
  /// [LocalSettingsService] (وليس من ذاكرة [SyncScheduler] المؤقتة)
  /// بحيث يبقى صحيحاً حتى بعد إعادة تحميل الصفحة (Web Refresh) قبل
  /// أي دورة مزامنة جديدة. `null` إن لم تنجح أي دورة مزامنة إطلاقاً
  /// من قبل على هذا الجهاز.
  DateTime? get lastSuccessfulSyncAt => _settingsService?.readLastSuccessfulSyncAt();

  /// يبدأ المحرّك إن لم يكن يعمل مسبقاً. آمن للاستدعاء المتكرر.
  Future<void> start() async {
    if (_isRunning) {
      AppLogger.debug('SyncScheduler: المزامنة تعمل مسبقاً، تجاهل.');
      return;
    }
    await _engine.start();
    _isRunning = true;
    AppLogger.info('SyncScheduler: تم تشغيل محرك المزامنة.');
  }

  /// يوقف المحرّك (مثال: عند تسجيل الخروج). لا يفقد أي عمليات معلّقة
  /// محلياً — تبقى محفوظة في `local_outbox` بانتظار [start] التالي
  /// (قد يكون لمستخدم مختلف بعد تسجيل دخول جديد على نفس الجهاز).
  Future<void> stop() async {
    if (!_isRunning) return;
    await _engine.stop();
    _isRunning = false;
    AppLogger.info('SyncScheduler: تم إيقاف محرك المزامنة.');
  }

  /// إعادة تشغيل فورية (مثال: بعد تبديل حساب المستخدم دون إعادة تحميل
  /// كامل التطبيق).
  Future<void> restart() async {
    await stop();
    await start();
  }

  /// اختصار لتشغيل دورة مزامنة يدوية فورية دون التأثير على حالة
  /// الجدولة (`isRunning`) — مثال: زر "مزامنة الآن" في واجهة المستخدم.
  /// يبقى متاحاً دائماً حتى لو [pauseAutomatic] استُدعيت — "مزامنة
  /// الآن" فعل صريح للمستخدم، لا "مزامنة تلقائية".
  Future<void> triggerNow() => _engine.triggerManualSync();

  /// 🆕 (Prompt 27) يوقف الاستراتيجيات التلقائية فقط
  /// ([ContinuousSyncStrategy]/[ForegroundSyncStrategy] عبر
  /// [SyncEngine.stop]) دون التأثير على [triggerNow] — يُستدعى من
  /// `sync_settings.dart` عند تعطيل مفتاح "مزامنة تلقائية". بخلاف
  /// [stop] القديمة (Prompt 09، تُستدعى عند تسجيل الخروج فعلياً)،
  /// هذه تُحدِّث [isAutoEnabled] وتُحفظ عبر [LocalSettingsService]
  /// صراحة ليبقى التفضيل محترَماً عبر إعادة تحميل الصفحة.
  Future<void> pauseAutomatic() async {
    _autoEnabled = false;
    await _settingsService?.saveSyncAutoEnabled(false);
    if (_isRunning) {
      await _engine.stop();
      _isRunning = false;
      AppLogger.info('SyncScheduler: أُوقفت المزامنة التلقائية يدوياً.');
    }
  }

  /// عكس [pauseAutomatic] — يعيد تشغيل المحرّك ويُحفظ التفضيل.
  Future<void> resumeAutomatic() async {
    _autoEnabled = true;
    await _settingsService?.saveSyncAutoEnabled(true);
    await start();
  }

  Future<void> dispose() async {
    await _stateSubscription?.cancel();
  }
}
