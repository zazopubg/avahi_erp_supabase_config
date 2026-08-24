/// ملف تجميعي (Barrel File) لكامل طبقة المزامنة `data/sync/`، لتسهيل
/// الاستيراد عبر سطر واحد من `core/di/` (Prompt 11) أو
/// `data/repositories_impl/` (Prompt 10):
/// `import 'package:avahi/data/sync/sync.dart';`
library;

export 'conflict/conflict_resolver.dart';
export 'conflict/first_write_wins.dart';
export 'conflict/last_write_wins.dart';
export 'conflict/manual_resolve.dart';
export 'connectivity/network_monitor.dart';
export 'outbox/idempotency_helper.dart';
export 'outbox/outbox_processor.dart';
export 'outbox/outbox_queue.dart';
export 'outbox/outbox_remote_writer.dart';
export 'retry/exponential_backoff.dart';
export 'retry/retry_policy.dart';
export 'strategies/continuous_sync.dart';
export 'strategies/foreground_sync.dart';
export 'strategies/sync_strategy.dart';
export 'sync_engine.dart';
export 'sync_scheduler.dart';
