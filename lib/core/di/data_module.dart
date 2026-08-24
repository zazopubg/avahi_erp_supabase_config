import 'package:get_it/get_it.dart';

import '../../data/cloud/supabase/repositories/repositories_impl.dart'
    as cloud;
import '../../data/local/local_database.dart';
import '../../data/repositories_impl/repositories_impl.dart';
import '../../data/storage/document_storage_service.dart';
import '../../data/storage/photo_storage_service.dart';
import '../../data/storage/signature_storage_service.dart';
import '../../data/sync/conflict/conflict_resolver.dart';
import '../../data/sync/conflict/first_write_wins.dart';
import '../../data/sync/conflict/last_write_wins.dart';
import '../../data/sync/connectivity/network_monitor.dart';
import '../../data/sync/outbox/outbox_processor.dart';
import '../../data/sync/outbox/outbox_queue.dart';
import '../../data/sync/outbox/outbox_remote_writer.dart';
import '../../data/sync/outbox/photo_upload_processor.dart';
import '../../data/sync/strategies/continuous_sync.dart';
import '../../data/sync/strategies/foreground_sync.dart';
import '../../data/sync/strategies/sync_strategy.dart';
import '../../data/sync/sync_engine.dart';
import '../../data/sync/sync_scheduler.dart';
import '../../domain/repositories/repositories.dart';
import '../constants/api_constants.dart';
import '../services/local_settings_service.dart';
import '../services/session_service.dart';

/// يسجّل كل طبقة `data/`: قاعدة البيانات المحلية (Drift)، محرّك
/// المزامنة الكامل، وكل `*RepositoryImpl` مربوطة بواجهتها من
/// `domain/repositories/` (Prompt 06) — [LazySingleton] لكل شيء هنا:
/// نسخة واحدة فقط طوال عمر التطبيق (خاصة [LocalDatabase]: فتح اتصال
/// قاعدة بيانات مرتين كارثي)، لكن لا شيء يُنشأ فعلياً قبل أول
/// `sl<T>()` فعلي (`bootstrap.dart` يفرض إنشاء [LocalDatabase] مبكراً
/// عمداً — انظر تعليق هناك).
///
/// ── ترتيب التسجيل هنا مقصود وليس عشوائياً ──────────────────────
/// [OutboxProcessor] يحتاج خريطة `localWriters` التي تشير إلى نفس
/// مستودعات `data/repositories_impl/` (كل منها ينفّذ [LocalSyncStateWriter]
/// أيضاً)، بينما تلك المستودعات نفسها تحتاج [OutboxQueue]/[NetworkMonitor]
/// فقط (وليس [OutboxProcessor] أو [SyncEngine]) — فلا توجد أي دورة
/// اعتماد فعلية (Circular Dependency)، لكن يجب بناء المستودعات **قبل**
/// [OutboxProcessor] نصّاً هنا حتى تُستخدم كقيم في خريطته مباشرة.
void registerDataModule(GetIt sl) {
  // ── قاعدة البيانات المحلية (Drift) ─────────────────────────────
  sl.registerLazySingleton<LocalDatabase>(() => LocalDatabase());

  // ── خدمات تخزين Supabase Storage ─────────────────────────────────
  // [SignatureStorageService]: أول استخدام فعلي من `features/field_reports/`
  // (Prompt 17، `signature_capture_pad.dart`). [PhotoStorageService]:
  // العقد/التنفيذ جاهزان مسبقاً (Prompt 07)؛ يُستهلك مبكراً هنا أيضاً من
  // `report_photo_attach.dart` (إرفاق صور بتقرير ميداني) قبل بناء واجهة
  // `features/photos/` الكاملة نفسها (Prompt 18) — الاستخدام محصور بربط
  // الصور بكيان `field_report` عبر `IPhotoRepository` أدناه، دون أي
  // اعتماد على شاشات `features/photos/` غير الموجودة بعد.
  sl.registerLazySingleton<SignatureStorageService>(
    () => SignatureStorageService(),
  );
  sl.registerLazySingleton<PhotoStorageService>(() => PhotoStorageService());
  // 🆕 (Prompt 21) [DocumentStorageService]: أول استخدام فعلي من
  // `features/documents/` (`documents_manager.dart`، رفع سطح المكتب).
  sl.registerLazySingleton<DocumentStorageService>(
    () => DocumentStorageService(),
  );

  // ── محرك المزامنة: لبنات أساسية مشتركة ──────────────────────────
  sl.registerLazySingleton<NetworkMonitor>(() => NetworkMonitor());

  sl.registerLazySingleton<OutboxQueue>(
    () => OutboxQueue(sl<LocalDatabase>().outboxDao),
  );

  sl.registerLazySingleton<OutboxRemoteWriter>(
    () => SupabaseOutboxRemoteWriter(),
  );

  // ── مستودعات `data/repositories_impl/` (محلي + سحابي مدموج) ─────
  // هذه هي التنفيذات النهائية التي تُحقن في `UseCases` عبر
  // `domain_module.dart` — وليست تلك تحت `data/cloud/supabase/repositories/`
  // (أصبحت تفاصيل داخلية تُستدعى من هنا فقط عبر بعضها).
  sl.registerLazySingleton<IAttendanceRepository>(
    () => AttendanceRepositoryImpl(
      dao: sl<LocalDatabase>().attendanceDao,
      outboxQueue: sl<OutboxQueue>(),
      networkMonitor: sl<NetworkMonitor>(),
    ),
  );

  sl.registerLazySingleton<IEquipmentRepository>(
    () => EquipmentRepositoryImpl(
      dao: sl<LocalDatabase>().equipmentDao,
      outboxQueue: sl<OutboxQueue>(),
      sessionService: sl<SessionService>(),
    ),
  );

  sl.registerLazySingleton<ILeaveRepository>(
    () => LeaveRepositoryImpl(
      dao: sl<LocalDatabase>().leaveDao,
      outboxQueue: sl<OutboxQueue>(),
    ),
  );

  sl.registerLazySingleton<INotificationRepository>(
    () => NotificationRepositoryImpl(
      dao: sl<LocalDatabase>().notificationDao,
      outboxQueue: sl<OutboxQueue>(),
      networkMonitor: sl<NetworkMonitor>(),
    ),
  );

  sl.registerLazySingleton<IReportRepository>(
    () => ReportRepositoryImpl(
      dao: sl<LocalDatabase>().reportDao,
      outboxQueue: sl<OutboxQueue>(),
    ),
  );

  sl.registerLazySingleton<ITaskRepository>(
    () => TaskRepositoryImpl(
      dao: sl<LocalDatabase>().taskDao,
      outboxQueue: sl<OutboxQueue>(),
    ),
  );

  // ── مستودعات سحابية خالصة (لا نسخة محلية مدموجة بعد) ─────────────
  // 🆕 ستنتقل كل واحدة منها إلى `data/repositories_impl/` بنفس نمط
  // الست أعلاه فقط عند الحاجة الفعلية لدعم Offline لها ضمن الـ Prompt
  // المسؤول عن ميزتها (`auth` في 13، `documents` في 21، إلخ)؛ الاعتماد
  // المباشر هنا على `data/cloud/supabase/repositories/` هو القرار
  // الصحيح اليوم وليس نقصاً.
  sl.registerLazySingleton<IAuthRepository>(() => cloud.AuthRepositoryImpl());
  sl.registerLazySingleton<ICompanyRepository>(
    () => cloud.CompanyRepositoryImpl(),
  );
  sl.registerLazySingleton<IDocumentRepository>(
    () => cloud.DocumentRepositoryImpl(),
  );
  sl.registerLazySingleton<IPhotoRepository>(
    () => cloud.PhotoRepositoryImpl(),
  );
  // 🆕 (Prompt 28) — بنفس منطق `ICompanyRepository`/`IUserRepository`
  // أعلاه: لوحة إدارية (`platformOwner` حصراً، Desktop فقط) تفترض
  // اتصالاً دائماً بالإنترنت، بلا حاجة فعلية لدعم أوفلاين — انظر
  // توثيق القرار الكامل في `PlatformAdminRepositoryImpl`.
  sl.registerLazySingleton<IPlatformAdminRepository>(
    () => cloud.PlatformAdminRepositoryImpl(),
  );
  sl.registerLazySingleton<IProjectRepository>(
    () => cloud.ProjectRepositoryImpl(),
  );
  sl.registerLazySingleton<IPunchRepository>(
    () => cloud.PunchRepositoryImpl(),
  );
  // 🆕 (Prompt 26) — بنفس منطق `ICompanyRepository` أعلاه تماماً:
  // إدارة أعضاء الشركة عملية إدارية تفترض اتصالاً دائماً بالإنترنت،
  // بلا حاجة فعلية لدعم أوفلاين — انظر توثيق القرار الكامل في
  // `UserRepositoryImpl`.
  sl.registerLazySingleton<IUserRepository>(() => cloud.UserRepositoryImpl());

  // ── محرك المزامنة: التوصيل الكامل الآن بعد وجود كل المستودعات ────
  sl.registerLazySingleton<OutboxProcessor>(
    () => OutboxProcessor(
      queue: sl<OutboxQueue>(),
      remoteWriter: sl<OutboxRemoteWriter>(),
      // نفس سياسة الحضور الحسّاسة قانونياً من `SyncEngine.withDefaults`
      // (أولوية دائماً للنسخة الأولى المرسلة فعلاً — انظر تعليق
      // `AttendanceRepositoryImpl` حول `attendance-guard`)، والباقي
      // صراحة "آخر كتابة تفوز" (بما يشمل المهام رغم كونها الافتراضي
      // أصلاً، توثيقاً للقرار لا اعتماداً ضمنياً عليه).
      conflictResolvers: const <String, ConflictResolver>{
        ApiConstants.tableAttendance: FirstWriteWinsResolver(),
        ApiConstants.tableTasks: LastWriteWinsResolver(),
        ApiConstants.tableEquipment: LastWriteWinsResolver(),
        ApiConstants.tableLeaveRequests: LastWriteWinsResolver(),
        ApiConstants.tableNotifications: LastWriteWinsResolver(),
        ApiConstants.tableFieldReports: LastWriteWinsResolver(),
      },
      localWriters: <String, LocalSyncStateWriter>{
        ApiConstants.tableAttendance:
            sl<IAttendanceRepository>() as LocalSyncStateWriter,
        ApiConstants.tableEquipment:
            sl<IEquipmentRepository>() as LocalSyncStateWriter,
        ApiConstants.tableLeaveRequests:
            sl<ILeaveRepository>() as LocalSyncStateWriter,
        ApiConstants.tableNotifications:
            sl<INotificationRepository>() as LocalSyncStateWriter,
        ApiConstants.tableFieldReports:
            sl<IReportRepository>() as LocalSyncStateWriter,
        ApiConstants.tableTasks: sl<ITaskRepository>() as LocalSyncStateWriter,
      },
    ),
  );

  // 🆕 (Prompt 18) معالج طابور الصور — مستقل تماماً عن [OutboxProcessor]
  // أعلاه (لا يشترك معه بأي `LocalSyncStateWriter`/`ConflictResolver`؛
  // انظر توثيق القرار الكامل في `photo_upload_processor.dart`)، يُبنى
  // فوق [PhotoDao] (من [LocalDatabase] مباشرة، وليس عبر `localWriters`
  // كبقية الكيانات — طابور الصور لا يمر بـ `OutboxTable` إطلاقاً)،
  // و[PhotoStorageService]/[IPhotoRepository] المسجَّلين أعلاه بالفعل.
  sl.registerLazySingleton<PhotoUploadProcessor>(
    () => PhotoUploadProcessor(
      photoDao: sl<LocalDatabase>().photoDao,
      photoStorageService: sl<PhotoStorageService>(),
      photoRepository: sl<IPhotoRepository>(),
    ),
  );

  sl.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      outboxQueue: sl<OutboxQueue>(),
      processor: sl<OutboxProcessor>(),
      networkMonitor: sl<NetworkMonitor>(),
      strategies: <SyncStrategy>[
        ContinuousSyncStrategy(),
        ForegroundSyncStrategy(),
      ],
      // 🆕 (Prompt 18) تفعيل مزامنة الصور الخلفية منخفضة الأولوية —
      // انظر توثيق القرار الكامل في `SyncEngine._syncPhotosInBackground`.
      photoProcessor: sl<PhotoUploadProcessor>(),
      photoDao: sl<LocalDatabase>().photoDao,
    ),
  );

  sl.registerLazySingleton<SyncScheduler>(
    // 🆕 (Prompt 27) `settingsService` مُمرَّرة الآن لتسجيل "آخر وقت
    // مزامنة ناجحة" محلياً تلقائياً — انظر توثيق القرار الكامل في
    // `SyncScheduler` نفسها. `LocalSettingsService` مسجَّلة في
    // `core_module.dart` (Prompt 27) قبل `data_module.dart` دائماً
    // (`registerCoreModule` يُستدعى أولاً من `injection_container.dart`).
    () => SyncScheduler(
      sl<SyncEngine>(),
      settingsService: sl<LocalSettingsService>(),
    ),
  );
}
