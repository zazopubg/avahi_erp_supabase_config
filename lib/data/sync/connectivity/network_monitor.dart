import 'dart:async';

import '../../../core/utils/connectivity_helper.dart';
import '../../../core/utils/logger.dart';

/// حالة الاتصال المبسّطة التي تعتمدها آلية المزامنة بأكملها — طبقة
/// رقيقة فوق [ConnectivityHelper] (`core/utils/`، Prompt 02) تُحوّل
/// `Stream<bool>` الخام إلى تعداد صريح أوضح عند الاستخدام من
/// `data/sync/strategies/` و`sync_engine.dart`.
enum ConnectivityStatus { online, offline }

/// مراقب اتصال واحد مشترك عبر محرك المزامنة كاملاً: يبثّ [onStatusChange]
/// عند كل تغيّر فعلي في حالة الاتصال (لا يُعيد بث نفس الحالة مرتين
/// متتاليتين)، ويحتفظ بآخر حالة معروفة عبر [current]/[isOnline] دون
/// الحاجة لانتظار تغيّر جديد.
///
/// ⚠️ يجب استدعاء [start] مرة واحدة (عادة من `SyncEngine.start`) قبل
/// الاعتماد على [current]/[isOnline] — قبل ذلك تُعتبر الحالة الافتراضية
/// `offline` تحفظاً (Fail-safe) لمنع أي محاولة إرسال مبكرة قبل التأكد
/// الفعلي من الاتصال.
class NetworkMonitor {
  NetworkMonitor({ConnectivityHelper? connectivityHelper})
      : _helper = connectivityHelper ?? ConnectivityHelper();

  final ConnectivityHelper _helper;

  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<bool>? _subscription;
  ConnectivityStatus? _current;
  bool _started = false;

  /// بثّ حي بحالة الاتصال، يصدر قيمة جديدة فقط عند تغيّر فعلي.
  Stream<ConnectivityStatus> get onStatusChange => _controller.stream;

  /// آخر حالة اتصال معروفة (`offline` افتراضياً قبل [start]).
  ConnectivityStatus get current => _current ?? ConnectivityStatus.offline;

  bool get isOnline => current == ConnectivityStatus.online;

  /// يبدأ المراقبة: يتحقق من الحالة الحالية فوراً ثم يشترك في تدفّق
  /// `connectivity_plus`. آمن للاستدعاء أكثر من مرة (يتجاهل التكرار).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final bool connectedNow = await _helper.isConnectedNow;
    _emit(connectedNow);

    _subscription = _helper.onStatusChange.listen(_emit);
    AppLogger.debug(
      'NetworkMonitor: بدأت المراقبة — الحالة الحالية: ${current.name}.',
    );
  }

  void _emit(bool connected) {
    final ConnectivityStatus next =
        connected ? ConnectivityStatus.online : ConnectivityStatus.offline;
    if (next == _current) return;

    final ConnectivityStatus? previous = _current;
    _current = next;
    _controller.add(next);

    if (previous != null) {
      AppLogger.info('NetworkMonitor: تغيّرت حالة الاتصال إلى ${next.name}.');
    }
  }

  /// يوقف المراقبة ويحرر الاشتراك — لا يُغلق البثّ (يبقى المراقب
  /// قابلاً لإعادة [start] لاحقاً)؛ استخدم [dispose] للتخلص النهائي.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
