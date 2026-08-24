import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/utils/logger.dart';
import '../supabase_client_provider.dart';

/// نقطة مركزية لإنشاء/إعادة استخدام/إغلاق قنوات Supabase Realtime
/// (`RealtimeChannel`) عبر كل `realtime/*_subscription.dart`، بدل ترك
/// كل صف اشتراك يدير دورة حياة قناته الخاصة بشكل منعزل.
///
/// الفوائد:
/// - إعادة استخدام نفس القناة إن طُلبت بنفس الاسم مرتين (بدل فتح
///   اتصال WebSocket مكرر لنفس الجدول/الفلتر).
/// - نقطة تنظيف واحدة ([disposeAll]) تُستدعى عند تسجيل الخروج أو إغلاق
///   التطبيق (`core/di/`، Prompt 11) لضمان عدم تسرّب اشتراكات مفتوحة.
class RealtimeManager {
  RealtimeManager({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;
  final Map<String, sb.RealtimeChannel> _channels = <String, sb.RealtimeChannel>{};

  /// يعيد قناة موجودة باسم [channelName] إن وُجدت، أو ينشئ قناة جديدة
  /// عبرها [build] ويحتفظ بها للاستخدام اللاحق. [build] يستقبل القناة
  /// الفارغة الجديدة ليُضيف عليها مستمعات `onPostgresChanges` قبل أن
  /// يستدعي `RealtimeManager` نفسه `.subscribe()` عليها.
  sb.RealtimeChannel channelFor(
    String channelName,
    sb.RealtimeChannel Function(sb.RealtimeChannel channel) build,
  ) {
    final sb.RealtimeChannel? existing = _channels[channelName];
    if (existing != null) return existing;

    final sb.RealtimeChannel created = build(_client.channel(channelName));
    created.subscribe();
    _channels[channelName] = created;
    AppLogger.debug('RealtimeManager: تم فتح قناة "$channelName".');
    return created;
  }

  /// يغلق قناة محددة ويزيلها من السجل الداخلي، إن وُجدت.
  Future<void> disposeChannel(String channelName) async {
    final sb.RealtimeChannel? channel = _channels.remove(channelName);
    if (channel == null) return;
    await _client.removeChannel(channel);
    AppLogger.debug('RealtimeManager: تم إغلاق قناة "$channelName".');
  }

  /// يغلق كل القنوات المفتوحة حالياً (يُستدعى عند تسجيل الخروج).
  Future<void> disposeAll() async {
    final List<String> names = _channels.keys.toList(growable: false);
    for (final String name in names) {
      await disposeChannel(name);
    }
  }
}
