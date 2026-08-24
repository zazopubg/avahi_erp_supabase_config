/// تمثيل مبسّط لإشعار محلي أو واصل عبر Push.
class AppNotificationPayload {
  const AppNotificationPayload({
    required this.title,
    required this.body,
    this.data = const <String, String>{},
  });

  final String title;
  final String body;

  /// بيانات إضافية للتوجيه عند النقر (مثال: `{'route': '/tasks/123'}`)
  /// تُستهلك لاحقاً من `navigation/` (Prompt 12).
  final Map<String, String> data;
}

/// واجهة خدمة الإشعارات: تسجيل الجهاز لاستقبال Push، عرض إشعارات
/// محلية فورية، والاستماع للنقر على الإشعارات.
///
/// ⚠️ نسخة Interface لهذه الخطوة، بلا اتصال فعلي بـ Firebase Cloud
/// Messaging أو Supabase Edge Function (`fetch-weather`/`send-push-
/// notification`) — سيُربط لاحقاً ضمن `features/notifications/`
/// (Prompt 23) و`core/di/` (Prompt 11).
abstract class NotificationService {
  /// يطلب إذن عرض الإشعارات من المتصفح، ويُعيد صحيح عند الموافقة.
  Future<bool> requestPermission();

  /// يعرض إشعاراً محلياً فورياً (بدون خادم Push).
  Future<void> showLocal(AppNotificationPayload payload);

  /// تدفّق يُصدر بيانات كل إشعار يُنقر عليه المستخدم.
  Stream<AppNotificationPayload> get onNotificationTapped;

  /// 🆕 (Prompt 27) هل الإذن ممنوح فعلياً الآن — حالة حيّة مباشرة من
  /// المنصّة (وليست ما حُفظ محلياً عبر `LocalSettingsService`، الذي
  /// يتتبّع فقط "هل طُلب الإذن من قبل" لا نتيجته الحالية، والتي قد
  /// تتغيّر خارج التطبيق تماماً من إعدادات المتصفح/النظام). تُستهلك من
  /// `features/settings/notification_settings.dart`.
  bool get isPermissionGranted;

  /// هل المستخدم رفض الإذن صراحة من قبل — يُستخدم لعرض رسالة توجيهية
  /// مختلفة ("فعّل الإذن من إعدادات المتصفح") بدل زر طلب عادي، لأن
  /// إعادة طلب إذن مرفوض سابقاً لا تعرض حواراً جديداً في أغلب
  /// المتصفحات (قرار سلوك قياسي في Notification API).
  bool get isPermissionDenied;
}
