// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

import '../utils/logger.dart';
import 'notification_service.dart';

/// تنفيذ [NotificationService] الفعلي الأول فوق Notification API
/// القياسي للمتصفح (`dart:html`) — يستبدل غياب أي تنفيذ حتى الآن
/// (انظر الملاحظة القديمة في `core/di/core_module.dart` التي وعدت
/// بربطه ضمن `features/notifications/` في Prompt 23 لكنها لم تُنفَّذ
/// فعلياً هناك؛ `features/settings/notification_settings.dart` —
/// أول مستهلك فعلي يحتاج طلب الإذن صراحة من المستخدم — هي نقطة
/// الربط الطبيعية الأولى).
///
/// ⚠️ نطاق متعمَّد: المشروع يستهدف الويب (Chrome) حصراً في هذه
/// المرحلة (انظر ملاحظة `pubspec.yaml`) — لذا `dart:html` مقبول هنا
/// دون أي غلاف `dart:io`/منصّة مشروط، بخلاف ما سيلزم لو استهدف
/// التطبيق الهاتف/سطح المكتب الأصلي لاحقاً (عندها سيحتاج هذا الملف
/// تنفيذاً بديلاً عبر `flutter_local_notifications`، خارج نطاق هذه
/// الخطوة تماماً).
class WebNotificationService implements NotificationService {
  final StreamController<AppNotificationPayload> _tapController =
      StreamController<AppNotificationPayload>.broadcast();

  @override
  Future<bool> requestPermission() async {
    if (!html.Notification.supported) {
      AppLogger.warning('WebNotificationService: المتصفح لا يدعم Notification API.');
      return false;
    }

    try {
      final String permission = await html.Notification.requestPermission();
      final bool granted = permission == 'granted';
      AppLogger.info('WebNotificationService: نتيجة طلب الإذن = $permission.');
      return granted;
    } catch (error, stackTrace) {
      AppLogger.error(
        'WebNotificationService: خطأ أثناء طلب إذن الإشعارات.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> showLocal(AppNotificationPayload payload) async {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') return;

    try {
      final html.Notification notification = html.Notification(
        payload.title,
        body: payload.body,
      );
      notification.onClick.listen((_) => _tapController.add(payload));
    } catch (error, stackTrace) {
      AppLogger.error(
        'WebNotificationService: خطأ أثناء عرض إشعار محلي.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<AppNotificationPayload> get onNotificationTapped =>
      _tapController.stream;

  @override
  bool get isPermissionGranted =>
      html.Notification.supported && html.Notification.permission == 'granted';

  @override
  bool get isPermissionDenied =>
      html.Notification.supported && html.Notification.permission == 'denied';
}
