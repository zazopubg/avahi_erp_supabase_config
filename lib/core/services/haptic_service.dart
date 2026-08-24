/// أنماط الاهتزاز اللمسي المدعومة منطقياً في التطبيق.
enum HapticPattern { light, medium, heavy, success, warning, error }

/// واجهة خدمة الاهتزاز اللمسي (Haptic Feedback)، تُستخدم لتحسين
/// التغذية الراجعة عند إجراءات حساسة (اعتماد حضور، إغلاق ملاحظة في
/// قائمة Punch List) على الأجهزة التي تدعمها.
///
/// ⚠️ وفق [CapabilityService]، الاهتزاز **غير مضمون** على متصفح الويب
/// (`AppCapability.haptics = false`)؛ لذا التنفيذ الفعلي لاحقاً يجب
/// أن يتحقق من الدعم أولاً ويتجاهل الطلب بصمت عند عدم التوفر بدلاً
/// من إظهار خطأ للمستخدم. هذه الخطوة تُعرّف العقد فقط.
abstract class HapticService {
  Future<void> trigger(HapticPattern pattern);
}

/// تنفيذ مؤقت لا يفعل شيئاً، يُستخدم كافتراضي آمن حتى ربط تنفيذ فعلي
/// (أو حتى تأكيد عدم جدوى الاهتزاز على الويب نهائياً).
class NoopHapticService implements HapticService {
  const NoopHapticService();

  @override
  Future<void> trigger(HapticPattern pattern) async {}
}
