import 'package:uuid/uuid.dart';

/// مولّد معرّفات فريدة (UUID v4) موحّد عبر التطبيق.
///
/// يُستخدم لتوليد معرّفات محلية (Client-generated IDs) قبل المزامنة
/// مع Supabase — أساسي لآلية `data/sync/outbox` (Prompt 09) حيث يجب
/// أن يُنشأ المعرّف على الجهاز فور إنشاء السجل محلياً (Offline-first)
/// دون انتظار استجابة الخادم.
abstract final class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// يولّد UUID v4 عشوائياً جديداً.
  static String v4() => _uuid.v4();

  /// يتحقق مما إذا كانت سلسلة نصية معطاة بصيغة UUID صالحة (أي إصدار).
  static bool isValid(String value) {
    final RegExp pattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return pattern.hasMatch(value);
  }
}
