import '../../domain/entities/app_user.dart';

/// حارس الاشتراك — **Stub فارغ عمداً في هذه الخطوة**: لا يوجد بعد أي
/// كيان `Subscription`/`TenantPlan` في `domain/entities/` ولا أي مصدر
/// بيانات فعلي لحالة اشتراك المستأجر (لا في `data/cloud/supabase/`
/// ولا في `data/local/`)، لذا لا معنى فعلياً لأي منطق حظر حقيقي هنا
/// الآن — إضافته الآن سيُخفي أخطاء لاحقاً بدل كشفها (نفس مبدأ
/// `core/di/core_module.dart` تجاه الخدمات غير المبنية بعد).
///
/// ⚠️ يبقى موجوداً كملف مستقل الآن (بدل تأجيله بالكامل) فقط لتثبيت
/// **موضعه** في سلسلة الحراس داخل `app_router.dart` (بعد [AuthGuard]
/// و[RoleGuard] و[PlatformGuard] مباشرة) — بحيث لا يتطلب ربط منطق
/// الاشتراك الفعلي لاحقاً أي إعادة ترتيب لسلسلة التحقق نفسها، بل فقط
/// تعبئة جسم [redirect] هنا بمنطق حقيقي (مثال محتمل: إعادة توجيه
/// لشاشة "انتهى الاشتراك" عند `tenant.plan.isExpired`).
class SubscriptionGuard {
  const SubscriptionGuard();

  String? redirect({
    required String? currentRouteName,
    required AppUser? currentUser,
  }) {
    // لا حظر فعلي بعد — انظر التوثيق أعلاه.
    return null;
  }
}
