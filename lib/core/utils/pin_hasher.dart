import 'dart:convert';

import 'package:crypto/crypto.dart';

/// يحوّل رمز PIN المحلي إلى تجزئة (SHA-256) قبل تخزينه عبر
/// `SessionService.savePinHash` — لا يُخزَّن رمز PIN الخام أبداً على
/// القرص، حتى ضمن تخزين آمن (`flutter_secure_storage`).
///
/// ⚠️ هذا PIN **محلي بحت** (بوابة دخول سريعة على نفس الجهاز لمستخدم
/// جلسته الفعلية محفوظة أصلاً عبر `SessionService`/Supabase)، وليس
/// بديلاً عن أي تحقق خادمي — لا حاجة لملح (Salt) عشوائي هنا لأن مساحة
/// المقارنة محلية بالكامل ومحدودة بمحاولات لوحة المفاتيح على نفس
/// الجهاز فقط.
abstract final class PinHasher {
  static String hash(String pin) {
    final List<int> bytes = utf8.encode('avahi.pin::$pin');
    return sha256.convert(bytes).toString();
  }

  static bool matches(String pin, String storedHash) => hash(pin) == storedHash;
}
