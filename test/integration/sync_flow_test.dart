import 'dart:async';

import 'package:avahi/data/local/daos/outbox_dao.dart';
import 'package:avahi/data/local/local_database.dart'
    show OutboxEntryRow, OutboxTableCompanion;
import 'package:avahi/data/sync/connectivity/network_monitor.dart';
import 'package:avahi/data/sync/outbox/outbox_processor.dart';
import 'package:avahi/data/sync/outbox/outbox_queue.dart';
import 'package:avahi/data/sync/outbox/outbox_remote_writer.dart';
import 'package:avahi/data/sync/sync_engine.dart';
import 'package:avahi/domain/enums/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOutboxDao extends Mock implements OutboxDao {}

class MockOutboxRemoteWriter extends Mock implements OutboxRemoteWriter {}

class MockNetworkMonitor extends Mock implements NetworkMonitor {}

/// يبني صف [OutboxEntryRow] حقيقياً (وليس Fake) — النوع مولَّد عبر
/// `build_runner`/Drift، لكن مُنشئه العادي (`OutboxEntryRow(...)`)
/// متاح تماماً كأي Data Class عادي بمجرد اكتمال التوليد؛ هذا يمنحنا
/// صفاً واقعياً بكل حقوله بدل `Fake` فارغ في اختبار التدفّق الكامل هذا.
OutboxEntryRow _buildQueuedEntry({
  required String id,
  required String payloadJson,
  int retryCount = 0,
}) {
  return OutboxEntryRow(
    id: id,
    entityType: 'attendance_records',
    entityId: 'attendance-offline-1',
    operationType: 'insert',
    payloadJson: payloadJson,
    createdAt: DateTime.utc(2026, 1, 10, 8),
    retryCount: retryCount,
    priority: 0,
    clientMutationId: 'mutation-offline-1',
  );
}

void main() {
  late MockOutboxDao dao;
  late MockOutboxRemoteWriter remoteWriter;
  late MockNetworkMonitor networkMonitor;
  late StreamController<ConnectivityStatus> connectivityController;
  late OutboxQueue queue;
  late OutboxProcessor processor;
  late SyncEngine engine;

  // حالة داخلية بسيطة تُحاكي فعلياً جدول `local_outbox` — تسمح بأن
  // يعكس `getPending`/`remove` المُموَّهان تغييرات حقيقية عبر التدفّق
  // الكامل (بخلاف `sync_engine_test.dart` الذي يثبّت قيماً ساكنة فقط
  // لعزل وحدة `SyncEngine` بمفردها).
  late List<OutboxEntryRow> localOutbox;

  setUpAll(() {
    registerFallbackValue(const OutboxTableCompanion());
  });

  setUp(() {
    dao = MockOutboxDao();
    remoteWriter = MockOutboxRemoteWriter();
    networkMonitor = MockNetworkMonitor();
    connectivityController = StreamController<ConnectivityStatus>.broadcast();
    localOutbox = <OutboxEntryRow>[];

    when(() => dao.getByEntity(any(), any())).thenAnswer((_) async => <OutboxEntryRow>[]);
    when(() => dao.enqueue(any())).thenAnswer((_) async {
      localOutbox.add(
        _buildQueuedEntry(
          id: 'outbox-entry-1',
          payloadJson: '{"id":"attendance-offline-1","geofence_valid":true}',
        ),
      );
    });
    when(() => dao.getPending(limit: any(named: 'limit')))
        .thenAnswer((_) async => List<OutboxEntryRow>.of(localOutbox));
    when(() => dao.remove(any())).thenAnswer((Invocation invocation) async {
      final String id = invocation.positionalArguments.first as String;
      localOutbox.removeWhere((OutboxEntryRow e) => e.id == id);
    });
    when(() => dao.recordFailedAttempt(any(), any())).thenAnswer((_) async {});

    when(() => networkMonitor.start()).thenAnswer((_) async {});
    when(() => networkMonitor.stop()).thenAnswer((_) async {});
    when(() => networkMonitor.dispose()).thenAnswer((_) async {});
    when(() => networkMonitor.onStatusChange)
        .thenAnswer((_) => connectivityController.stream);

    queue = OutboxQueue(dao);
    processor = OutboxProcessor(queue: queue, remoteWriter: remoteWriter);
    engine = SyncEngine(
      outboxQueue: queue,
      processor: processor,
      networkMonitor: networkMonitor,
    );
  });

  tearDown(() async {
    await connectivityController.close();
  });

  group('تدفّق المزامنة الكامل: offline → حضور → online → تحقق الوصول '
      'للخادم', () {
    test(
        'المرحلة 1 (Offline): تسجيل الحضور يُضاف محلياً للطابور فوراً رغم '
        'انقطاع الاتصال، بلا أي محاولة اتصال بالخادم', () async {
      when(() => networkMonitor.isOnline).thenReturn(false);

      // "تسجيل الحضور" المحلي — نفس ما تستدعيه طبقة
      // `data/repositories_impl/attendance_repository_impl.dart` فعلياً
      // بعد كتابة السجل في Drift محلياً (Offline-first: الكتابة المحلية
      // تنجح دوماً بصرف النظر عن حالة الاتصال).
      await queue.enqueue(
        entityType: 'attendance_records',
        entityId: 'attendance-offline-1',
        operationType: OutboxOperationType.insert,
        payload: const <String, dynamic>{
          'id': 'attendance-offline-1',
          'geofence_valid': true,
        },
        clientMutationId: 'mutation-offline-1',
      );

      verify(() => dao.enqueue(any())).called(1);
      expect(localOutbox, hasLength(1));

      await engine.start();
      expect(engine.currentState, SyncState.pending);
      verifyNever(
        () => remoteWriter.push(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test(
        'المرحلة 2 (Online): فور استعادة الاتصال تُرسَل العملية المعلّقة '
        'فعلياً للخادم (OutboxRemoteWriter.push)، وتُزال من الطابور '
        'المحلي، وتنتهي الحالة العامة بـ synced', () async {
      // إعداد نفس حالة "بعد تسجيل الحضور محلياً أثناء الانقطاع" من
      // المرحلة الأولى مباشرة (طابور محلي يحوي عنصراً واحداً معلّقاً).
      when(() => networkMonitor.isOnline).thenReturn(false);
      await queue.enqueue(
        entityType: 'attendance_records',
        entityId: 'attendance-offline-1',
        operationType: OutboxOperationType.insert,
        payload: const <String, dynamic>{
          'id': 'attendance-offline-1',
          'geofence_valid': true,
        },
        clientMutationId: 'mutation-offline-1',
      );
      await engine.start();
      expect(engine.currentState, SyncState.pending);

      // الخادم يقبل الدفعة بنجاح تام (بلا أي تعارض).
      when(
        () => remoteWriter.push(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => const OutboxPushSuccess());

      when(() => networkMonitor.isOnline).thenReturn(true);
      connectivityController.add(ConnectivityStatus.online);
      // انتظار قصير للسماح بسلسلة `unawaited(triggerManualSync())` غير
      // المتزامنة بالاكتمال بالكامل (بما فيها `_refreshIdleState`
      // اللاحقة داخلياً).
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // ✅ التحقق الجوهري من هذا الاختبار: "الوصول الفعلي للخادم" —
      // العملية المحلية المعلّقة وصلت فعلاً إلى الطبقة السحابية
      // (`OutboxRemoteWriter.push`) بالكيان والحمولة الصحيحين.
      verify(
        () => remoteWriter.push(
          entityType: 'attendance_records',
          entityId: 'attendance-offline-1',
          operation: OutboxOperationType.insert,
          payload: <String, dynamic>{
            'id': 'attendance-offline-1',
            'geofence_valid': true,
          },
        ),
      ).called(1);

      expect(localOutbox, isEmpty);
      expect(engine.currentState, SyncState.synced);
    });

    test(
        'تعذّر الاتصال الفعلي بالخادم (استثناء) أثناء محاولة الإرسال '
        'يُبقي العنصر في الطابور المحلي بحالة failed، دون فقدان البيانات',
        () async {
      when(() => networkMonitor.isOnline).thenReturn(true);
      await queue.enqueue(
        entityType: 'attendance_records',
        entityId: 'attendance-offline-1',
        operationType: OutboxOperationType.insert,
        payload: const <String, dynamic>{
          'id': 'attendance-offline-1',
          'geofence_valid': true,
        },
        clientMutationId: 'mutation-offline-1',
      );

      when(
        () => remoteWriter.push(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(Exception('Connection refused'));

      await engine.start();
      await engine.triggerManualSync();

      // العنصر يبقى محفوظاً محلياً (لم يُحذف رغم فشل الإرسال) — لا فقدان
      // بيانات إطلاقاً في استراتيجية Offline-first.
      expect(localOutbox, hasLength(1));
      expect(engine.currentState, SyncState.failed);
      verify(() => dao.recordFailedAttempt(any(), any())).called(1);
    });
  });
}
