import 'dart:async';

import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../../domain/enums/sync_state.dart';
import '../local/daos/photo_dao.dart';
import '../local/local_database.dart';
import 'conflict/conflict_resolver.dart';
import 'conflict/first_write_wins.dart';
import 'conflict/last_write_wins.dart';
import 'connectivity/network_monitor.dart';
import 'outbox/outbox_processor.dart';
import 'outbox/outbox_queue.dart';
import 'outbox/outbox_remote_writer.dart';
import 'outbox/photo_upload_processor.dart';
import 'strategies/continuous_sync.dart';
import 'strategies/foreground_sync.dart';
import 'strategies/sync_strategy.dart';

/// المنسّق الرئيسي لكامل آلية المزامنة (`data/sync/`) — نقطة الدخول
/// الوحيدة التي يجب أن تعتمد عليها أي طبقة أعلى (`data/repositories_impl/`
/// Prompt 10، `core/di/` Prompt 11، وواجهات المستخدم لعرض شارة حالة
/// المزامنة). يُوحِّد ثلاثة مصادر تشغيل لدورات المزامنة في تدفّق واحد
/// متسلسل (لا تتزامن دورتان أبداً في آن واحد):
/// 1. استعادة الاتصال بعد انقطاع (عبر [NetworkMonitor]).
/// 2. أي [SyncStrategy] مسجَّلة ([ContinuousSyncStrategy]/
///    [ForegroundSyncStrategy] أو غيرها).
/// 3. استدعاء يدوي صريح عبر [triggerManualSync] (مثال: زر "مزامنة
///    الآن" في واجهة المستخدم).
///
/// 🆕 (Prompt 18) مصدر رابع مستقل تماماً بأولوية أقل صراحة: رفع طابور
/// الصور (`local_photo_queue` عبر [PhotoUploadProcessor]) — انظر
/// توثيق القرار الكامل في [_syncPhotosInBackground] أدناه.
class SyncEngine {
  SyncEngine({
    required OutboxQueue outboxQueue,
    required OutboxProcessor processor,
    required NetworkMonitor networkMonitor,
    List<SyncStrategy> strategies = const <SyncStrategy>[],
    PhotoUploadProcessor? photoProcessor,
    PhotoDao? photoDao,
    int photoBatchLimit = 3,
  })  : _outboxQueue = outboxQueue,
        _processor = processor,
        _networkMonitor = networkMonitor,
        _strategies = strategies,
        _photoProcessor = photoProcessor,
        _photoDao = photoDao,
        _photoBatchLimit = photoBatchLimit;

  /// يبني محرّكاً جاهزاً بإعدادات افتراضية معقولة فوق [database]
  /// مباشرة عبر Supabase (`SupabaseOutboxRemoteWriter`)، مع محللَي
  /// التعارض الإلزاميَين ([FirstWriteWinsResolver] للحضور،
  /// [LastWriteWinsResolver] افتراضياً لكل شيء آخر بما فيها المهام
  /// صراحة)، واستراتيجيتي [ContinuousSyncStrategy]+[ForegroundSyncStrategy]
  /// معاً. مناسب للاستخدام المباشر من `core/di/` (Prompt 11) دون إعادة
  /// كتابة هذا التوصيل يدوياً في كل مكان.
  ///
  /// ⚠️ لا يُفعِّل مزامنة الصور ([PhotoUploadProcessor]) هنا: تلك تحتاج
  /// [PhotoStorageService]/[IPhotoRepository] (طبقتا `data/storage/`
  /// و`data/cloud/`) اللتين لا يملكهما هذا المصنع المبسَّط أصلاً (يبني
  /// فقط فوق [LocalDatabase])؛ التوصيل الفعلي الكامل يبقى في
  /// `core/di/data_module.dart` (الذي يبني [SyncEngine] مباشرة عبر
  /// المُنشئ الأساسي أعلاه، وليس عبر هذا المصنع، منذ Prompt 09 أصلاً).
  factory SyncEngine.withDefaults(LocalDatabase database) {
    final OutboxQueue queue = OutboxQueue(database.outboxDao);
    return SyncEngine(
      outboxQueue: queue,
      processor: OutboxProcessor(
        queue: queue,
        remoteWriter: SupabaseOutboxRemoteWriter(),
        conflictResolvers: const <String, ConflictResolver>{
          ApiConstants.tableAttendance: FirstWriteWinsResolver(),
          ApiConstants.tableTasks: LastWriteWinsResolver(),
        },
      ),
      networkMonitor: NetworkMonitor(),
      strategies: <SyncStrategy>[
        ContinuousSyncStrategy(),
        ForegroundSyncStrategy(),
      ],
    );
  }

  final OutboxQueue _outboxQueue;
  final OutboxProcessor _processor;
  final NetworkMonitor _networkMonitor;
  final List<SyncStrategy> _strategies;

  /// `null` حتى تُمرَّر فعلياً من `core/di/data_module.dart` — تبقى كل
  /// دورة مزامنة عامة (الحضور/التقارير/المهام...) تعمل بشكل كامل
  /// ومستقل حتى بدونه (بنفس فلسفة `LocalSyncStateWriter` الاختيارية
  /// في `OutboxProcessor`)، فقط طابور الصور نفسه يبقى دون معالجة.
  final PhotoUploadProcessor? _photoProcessor;
  final PhotoDao? _photoDao;

  /// عدد الصور المعالَجة كحد أقصى في كل دورة خلفية واحدة — انظر توثيق
  /// القرار الكامل في [_syncPhotosInBackground].
  final int _photoBatchLimit;

  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  bool _hasStarted = false;
  bool _isProcessing = false;
  bool _isSyncingPhotos = false;
  SyncState _lastState = SyncState.pending;

  /// بثّ عام بالحالة الإجمالية لمحرّك المزامنة (وليس حالة سجل بعينه).
  /// يُعيد استخدام تعداد `SyncState` نفسه المعرَّف أصلاً في
  /// `domain/enums/sync_state.dart` (Prompt 08) بدل تكراره: `pending`
  /// = توجد عمليات معلّقة لم تُعالَج بعد، `syncing` = دورة جارية الآن،
  /// `synced` = لا شيء معلّق، `failed` = آخر دورة انتهت بفشل عابر
  /// واحد على الأقل، `conflict` = يوجد تعارض واحد على الأقل بانتظار
  /// حلّ يدوي.
  ///
  /// ⚠️ لا يعكس هذا البث حالة طابور الصور عمداً (انظر
  /// [watchPendingPhotoCount] بدلاً منه) — شارة "غير متزامن" العامة في
  /// واجهة المستخدم يجب أن تبقى مرتبطة فقط بالبيانات الحرجة (حضور/
  /// تقارير/مهام)، بينما رفع الصور خلفي بحت ولا يستحق إثارة قلق
  /// المستخدم بنفس درجة إلحاح تلك البيانات — بالضبط جوهر قرار "الأولوية
  /// الأقل" المطلوب صراحة في Prompt 18.
  Stream<SyncState> get stateStream => _stateController.stream;

  SyncState get currentState => _lastState;

  bool get isOnline => _networkMonitor.isOnline;

  /// بثّ حي بعدد العمليات المعلّقة — تمرير مباشر لتسهيل ربط شارة
  /// واجهة المستخدم دون الحاجة لحقن [OutboxQueue] بشكل منفصل.
  Stream<int> watchPendingCount() => _outboxQueue.watchPendingCount();

  /// 🆕 (Prompt 18) بثّ حي بعدد الصور بانتظار الرفع — تمرير مباشر عبر
  /// [PhotoDao.watchPendingCount] (بنفس نمط [watchPendingCount] أعلاه)
  /// لعرض شارة "N صورة بانتظار الرفع" في `upload_progress_indicator.dart`
  /// دون حاجة الشاشة لحقن [PhotoDao] بشكل منفصل. بثّ فارغ (لا عناصر
  /// أبداً) إن لم يُمرَّر [PhotoDao] فعلياً للمُنشئ.
  Stream<int> watchPendingPhotoCount() =>
      _photoDao?.watchPendingCount() ?? const Stream<int>.empty();

  /// يبدأ المحرّك: يشغّل مراقبة الاتصال، يشترك في استعادته لتشغيل
  /// مزامنة فورية، ويبدأ كل [SyncStrategy] مسجَّلة. آمن للاستدعاء
  /// المتكرر (يتجاهل الاستدعاءات اللاحقة بعد أول بدء ناجح).
  Future<void> start() async {
    if (_hasStarted) return;
    _hasStarted = true;

    await _networkMonitor.start();
    _connectivitySubscription = _networkMonitor.onStatusChange.listen(
      (ConnectivityStatus status) {
        if (status == ConnectivityStatus.online) {
          AppLogger.info('SyncEngine: عاد الاتصال — تشغيل مزامنة فورية.');
          unawaited(triggerManualSync());
        } else {
          _emit(SyncState.pending);
        }
      },
    );

    for (final SyncStrategy strategy in _strategies) {
      strategy.start(triggerManualSync);
    }

    unawaited(_refreshIdleState());
    AppLogger.info(
      'SyncEngine: بدأ التشغيل مع ${_strategies.length} استراتيجية مزامنة.',
    );
  }

  /// يوقف كل الاستراتيجيات ومراقبة الاتصال — لا يمسح الطابور نفسه
  /// (العمليات المعلّقة تبقى محفوظة محلياً بانتظار [start] التالي).
  Future<void> stop() async {
    for (final SyncStrategy strategy in _strategies) {
      strategy.stop();
    }
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    await _networkMonitor.stop();
    _hasStarted = false;
    AppLogger.info('SyncEngine: تم الإيقاف.');
  }

  /// يشغّل دورة مزامنة كاملة الآن. آمن للاستدعاء المتزامن من مصادر
  /// متعددة (اتصال مستعاد + استراتيجية + زر يدوي في آن واحد) — يتجاهل
  /// أي استدعاء يصل أثناء دورة جارية أصلاً بدل تكديس دورات متداخلة.
  Future<void> triggerManualSync() async {
    if (_isProcessing) return;

    if (!_networkMonitor.isOnline) {
      _emit(SyncState.pending);
      return;
    }

    _isProcessing = true;
    _emit(SyncState.syncing);

    try {
      final List<OutboxProcessResult> results = await _processor.processPending();

      final bool anyConflict = results.any((OutboxProcessResult r) => r.isConflict);
      final bool anyFailed = results.any(
        (OutboxProcessResult r) =>
            !r.isSuccess && r.outcome != OutboxEntryOutcome.conflictPending,
      );

      if (anyConflict) {
        _emit(SyncState.conflict);
      } else if (anyFailed) {
        _emit(SyncState.failed);
      } else {
        await _refreshIdleState();
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'SyncEngine: خطأ غير متوقع أثناء دورة مزامنة.',
        error: error,
        stackTrace: stackTrace,
      );
      _emit(SyncState.failed);
    } finally {
      _isProcessing = false;
    }

    // 🆕 (Prompt 18) رفع طابور الصور — عمداً *بعد* اكتمال دورة الطابور
    // العام أعلاه بالكامل (وليس بالتوازي معها)، وعمداً `unawaited` بلا
    // انتظار هنا: هذا هو جوهر "أولوية أقل" المطلوبة صراحة في هذه
    // الخطوة مقارنة ببيانات الحضور/التقارير الميدانية —
    // 1) لا يبدأ رفع صورة واحدة قبل أن تُرسَل كل عمليات الحضور/
    //    التقارير/المهام المعلّقة أولاً.
    // 2) لا يُبقي [triggerManualSync] (ولا أي طرف ينتظره، مثل زر
    //    "مزامنة الآن" في واجهة المستخدم) معلّقاً بانتظار اكتمال رفع
    //    الصور — التي قد تكون أكبر حجماً وأبطأ بكثير من أي حمولة JSON
    //    عادية في `OutboxTable`.
    // 3) [_photoBatchLimit] الصغير (3 افتراضياً) يمنع دفعة صور ضخمة من
    //    الاستحواذ على الاتصال لفترة طويلة دفعة واحدة؛ الباقي يُرفَع
    //    تدريجياً عبر دورات [ContinuousSyncStrategy] اللاحقة.
    unawaited(_syncPhotosInBackground());
  }

  Future<void> _syncPhotosInBackground() async {
    final PhotoUploadProcessor? photoProcessor = _photoProcessor;
    if (photoProcessor == null) return;
    if (_isSyncingPhotos) return;
    if (!_networkMonitor.isOnline) return;

    _isSyncingPhotos = true;
    try {
      final List<PhotoUploadResult> results =
          await photoProcessor.processPending(limit: _photoBatchLimit);
      if (results.isNotEmpty) {
        AppLogger.debug(
          'SyncEngine: عولجت ${results.length} صورة من الطابور الخلفي '
          '(${results.where((PhotoUploadResult r) => r.isSuccess).length} نجحت).',
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'SyncEngine: خطأ غير متوقع أثناء رفع طابور الصور الخلفي.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isSyncingPhotos = false;
    }
  }

  Future<void> _refreshIdleState() async {
    final int pendingCount = (await _outboxQueue.pending()).length;
    _emit(pendingCount == 0 ? SyncState.synced : SyncState.pending);
  }

  void _emit(SyncState state) {
    _lastState = state;
    _stateController.add(state);
  }

  Future<void> dispose() async {
    await stop();
    await _networkMonitor.dispose();
    await _stateController.close();
  }
}
