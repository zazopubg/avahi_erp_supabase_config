/// إعادة تصدير [UserRole] من `core/constants/roles.dart`.
///
/// ⚠️ قرار معماري متعمّد: تعداد الأدوار [UserRole] هو **قيمة عابرة
/// للطبقات** (Cross-cutting) تُستخدم فعلياً في `core/constants/permissions.dart`
/// منذ Prompt 02، وقيمها النصية يجب أن تطابق تماماً عمود
/// `company_members.role` في قاعدة البيانات (انظر Prompt 03،
/// `002_create_company_members.sql`). لتجنّب وجود نسختين متعارضتين
/// من نفس التعداد (واحدة في `core` وأخرى في `domain`)، تُبقي هذه
/// الطبقة `domain/enums/user_role.dart` كنقطة استيراد موحّدة بحيث
/// تعتمد كل طبقات `domain/` و`data/` و`presentation/` على نفس
/// التعداد دون تكراره أو المخاطرة باختلاف القيم.
///
/// هذا الملف Dart نقي 100%: `core/constants/roles.dart` لا يستورد أي
/// شيء من Flutter أو Supabase، لذا لا ينتهك استقلالية طبقة الـ domain.
library;

export 'package:avahi/core/constants/roles.dart' show UserRole;
