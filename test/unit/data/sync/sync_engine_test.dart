import 'dart:async';

import 'package:avahi/data/local/local_database.dart' show OutboxEntryRow;
import 'package:avahi/data/sync/connectivity/network_monitor.dart';
import 'package:avahi/data/sync/outbox/outbox_processor.dart';
import 'package:avahi/data/sync/outbox/outbox_queue.dart';
import 'package:avahi/data/sync/sync_engine.dart';
import 'package:avahi/domain/enums/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ⚠️ [OutboxQueue]/[OutboxProcessor]/[NetworkMonitor] كلها صفوف عادية
// (Concrete، وليست واجهات `abstract interface`) — نموذج `mocktail`
// القياسي `extends Mock implements X` يعمل هنا تماماً كما مع الواجهات:
// `Mock` لا يستدعي مُنشئ [X] الحقيقي إطلاقاً (`noSuchMethod` فقط)، لذا
// لا حاجة لأي اتصال قاعدة بيانات أو `connectivity_plus` فعلي حتى في
// هذا الاختبار رغم أن [SyncEngine] نفسه في الإنتاج يعتمد عليهما مباشرة.
class MockOutboxQueue extends Mock implements OutboxQueue {}

class MockOutboxProcessor extends Mock implements OutboxProcessor {}

class MockNetworkMonitor extends Mock implements NetworkMonitor {}

class FakeOutboxEntryRow extends Fake implements OutboxEntryRow {}

void main() {
  late MockOutboxQueue outboxQueue;
  late MockOutboxProcessor processor;
  late MockNetworkMonitor networkMonitor;
  late StreamController<ConnectivityStatus> connectivityController;
  late SyncEngine engine;

  setUpAll(() {
    registerFallbackValue(FakeOutboxEntryRow());
  });

  setUp(() {
    outboxQueue = MockOutboxQueue();
    processor = MockOutboxProcessor();
    networkMonitor = MockNetworkMonitor();
    connectivityController = StreamController<ConnectivityStatus>.broadcast();

    when(() => networkMonitor.start()).thenAnswer((_) async {});
    when(() => networkMonitor.stop()).thenAnswer((_) async {});
    when(() => networkMonitor.dispose()).thenAnswer((_) async {});
    when(() => networkMonitor.onStatusChange)
        .thenAnswer((_) => connectivityController.stream);
    when(() => outboxQueue.pending())
        .thenAnswer((_) async => <OutboxEntryRow>[]);

    engine = SyncEngine(
      outboxQueue: outboxQueue,
      processor: processor,
      networkMonitor: networkMonitor,
    );
  });

  tearDown(() async {
    await connectivityController.close();
  });

  group('SyncEngine — سيناريو offline → online', () {
    test('لا يحاول المزامنة أثناء الانقطاع، ويصدر SyncState.pending فوراً',
        () async {
      when(() => networkMonitor.isOnline).thenReturn(false);
      await engine.start();

      await engine.triggerManualSync();

      expect(engine.currentState, SyncState.pending);
      verifyNever(() => processor.processPending());
    });

    test('يُشغّل مزامنة تلقائية فور استعادة الاتصال، وينتهي بحالة synced '
        'عند نجاح كل العمليات المعلّقة', () async {
      when(() => networkMonitor.isOnline).thenReturn(false);
      await engine.start();

      // العودة للاتصال: NetworkMonitor يبثّ `online`، ويستمع SyncEngine
      // لهذا التغيّر تلقائياً (`_connectivitySubscription`) ليشغّل
      // `triggerManualSync()` من تلقاء نفسه دون أي تدخّل خارجي.
      when(() => networkMonitor.isOnline).thenReturn(true);
      when(() => processor.processPending())
          .thenAnswer((_) async => <OutboxProcessResult>[]);

      connectivityController.add(ConnectivityStatus.online);
      // انتظار قصير للسماح لسلسلة `unawaited(triggerManualSync())` غير
      // المتزامنة بالاكتمال داخل مستمع البث.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verify(() => processor.processPending()).called(greaterThanOrEqualTo(1));
      expect(engine.currentState, SyncState.synced);
    });

    test('يتجاهل استدعاء triggerManualSync إضافياً أثناء دورة جارية أصلاً '
        '(لا يُكدِّس دورات متداخلة)', () async {
      when(() => networkMonitor.isOnline).thenReturn(true);
      final Completer<List<OutboxProcessResult>> pendingCompleter =
          Completer<List<OutboxProcessResult>>();
      when(() => processor.processPending())
          .thenAnswer((_) => pendingCompleter.future);
      await engine.start();

      final Future<void> first = engine.triggerManualSync();
      final Future<void> second = engine.triggerManualSync();

      expect(engine.currentState, SyncState.syncing);
      pendingCompleter.complete(<OutboxProcessResult>[]);
      await first;
      await second;

      verify(() => processor.processPending()).called(1);
    });
  });

  group('SyncEngine — انعكاس نتائج المعالجة على الحالة العامة', () {
    test('يصدر SyncState.conflict عند وجود عنصر واحد على الأقل بحالة '
        'conflictPending', () async {
      when(() => networkMonitor.isOnline).thenReturn(true);
      when(() => processor.processPending()).thenAnswer(
        (_) async => <OutboxProcessResult>[
          OutboxProcessResult(
            entry: FakeOutboxEntryRow(),
            outcome: OutboxEntryOutcome.conflictPending,
          ),
        ],
      );
      await engine.start();

      await engine.triggerManualSync();

      expect(engine.currentState, SyncState.conflict);
    });

    test('يصدر SyncState.failed عند فشل حقيقي (retryScheduled) دون أي '
        'تعارض', () async {
      when(() => networkMonitor.isOnline).thenReturn(true);
      when(() => processor.processPending()).thenAnswer(
        (_) async => <OutboxProcessResult>[
          OutboxProcessResult(
            entry: FakeOutboxEntryRow(),
            outcome: OutboxEntryOutcome.retryScheduled,
          ),
        ],
      );
      await engine.start();

      await engine.triggerManualSync();

      expect(engine.currentState, SyncState.failed);
    });

    test('يصدر SyncState.pending إن بقيت عناصر معلّقة رغم اكتمال الدورة '
        'دون فشل صريح', () async {
      when(() => networkMonitor.isOnline).thenReturn(true);
      when(() => processor.processPending())
          .thenAnswer((_) async => <OutboxProcessResult>[]);
      when(() => outboxQueue.pending())
          .thenAnswer((_) async => <OutboxEntryRow>[FakeOutboxEntryRow()]);
      await engine.start();

      await engine.triggerManualSync();

      expect(engine.currentState, SyncState.pending);
    });
  });
}
