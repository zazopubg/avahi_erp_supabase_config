import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// مساعد مراقبة حالة الاتصال بالإنترنت، يُبسّط `connectivity_plus`
/// إلى `Stream<bool>` واحد (متصل/غير متصل) بدلاً من تفاصيل نوع
/// الاتصال (wifi/mobile/ethernet)، وهو كل ما تحتاجه آلية العمل دون
/// اتصال (Offline-first، `data/sync/connectivity.dart`، Prompt 09).
class ConnectivityHelper {
  ConnectivityHelper({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// تدفّق منبثق بحالة الاتصال الحالية عند كل تغيير: true = متصل.
  Stream<bool> get onStatusChange {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  /// يتحقق من حالة الاتصال الحالية فوراً (بدون انتظار تغيير).
  Future<bool> get isConnectedNow async {
    final List<ConnectivityResult> result =
        await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }
}
