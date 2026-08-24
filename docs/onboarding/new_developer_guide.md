# دليل المطور الجديد

مرحباً بك في مشروع Avahi! هذا الدليل يوجّهك خلال أول أسبوع عمل على المشروع
— من فهم البنية العامة إلى تنفيذ أول تعديل فعلي بثقة.

## اليوم الأول: افهم الصورة الكبيرة قبل الكود

اقرأ بهذا الترتيب **قبل** فتح أي محرر كود:

1. [docs/architecture/01_overview.md](../architecture/01_overview.md) —
   المبادئ المعمارية الحاكمة الستة، وخريطة تدفّق طلب نموذجي كامل (مثال
   تسجيل حضور) من الضغطة إلى قاعدة البيانات.
2. [docs/architecture/02_folder_structure.md](../architecture/02_folder_structure.md)
   — أين يقع كل شيء، وقاعدة التسمية الصارمة لكل ميزة.
3. [docs/architecture/06_offline_first.md](../architecture/06_offline_first.md)
   — لماذا Avahi مبني كما هو (محلي أولاً، سحابي لاحقاً) وليس العكس؛ هذا
   القرار يفسّر أغلب "الغرابة" الظاهرية في بنية `data/` عند أول قراءة.

ثم جهّز بيئتك عملياً عبر [setup_guide.md](./setup_guide.md).

## اليوم الثاني: تتبّع ميزة كاملة من طرف لطرف

أفضل طريقة لفهم النمط المعماري فعلياً هي تتبّع ميزة واحدة موجودة بالكامل،
من الشاشة حتى قاعدة البيانات. نوصي بـ `attendance` (تسجيل الحضور) كمثال
مرجعي لأنها تغطي كل الطبقات + المزامنة + RLS الحساسة:

```
lib/features/attendance/presentation/screens/mobile/check_in_screen.dart
    → استدعاء context.read<AttendanceCubit>().checkIn(...)

lib/features/attendance/presentation/state/attendance_cubit.dart
    → يستدعي CheckInUsecase

lib/domain/usecases/attendance/check_in_usecase.dart
    → يستدعي IAttendanceRepository (عقد مجرّد)

lib/domain/repositories/i_attendance_repository.dart
    → العقد نفسه، بلا تنفيذ

lib/data/repositories_impl/attendance_repository_impl.dart
    → التنفيذ الفعلي: يكتب لـ Drift محلياً، ثم OutboxQueue.enqueue(...)

lib/data/sync/outbox/outbox_processor.dart + outbox_remote_writer.dart
    → يرسل لاحقاً إلى Supabase عند توفر اتصال

backend/supabase/migrations/006_create_attendance.sql
backend/supabase/migrations/016_rls_policies.sql (قسم attendance)
    → الجدول الفعلي وسياسات RLS المطابقة تماماً لمنطق الصلاحيات في Flutter
```

اقرأ كل ملف من هذه القائمة بالترتيب، مع فتح
[docs/architecture/03_sync_strategy.md](../architecture/03_sync_strategy.md)
جنباً إلى جنب لفهم لماذا `attendance` تحديداً تستخدم `FirstWriteWinsResolver`
بدل الافتراضي `LastWriteWins`.

## اليوم الثالث: القواعد غير القابلة للتفاوض

اقرأ [coding_standards.md](./coding_standards.md) بالكامل — خصوصاً قسم
"اصطلاحات معمارية" (لا استيراد Flutter داخل `domain/`، لا إنشاء تبعية
مباشرة بدل الحقن، مطابقة صلاحية Flutter لكل سياسة RLS). هذه ليست اقتراحات؛
أي طلب دمج يخالفها يُرفَض في المراجعة.

اقرأ أيضاً موجزاً عن:
- [docs/security/roles_matrix.md](../security/roles_matrix.md) — من يملك
  حق فعل ماذا.
- [docs/ui_guidelines/rtl_rules.md](../ui_guidelines/rtl_rules.md) — العربية
  RTL هي الوضع الافتراضي المُختبَر أولاً، لا استثناءً لاحقاً.

## اليوم الرابع-الخامس: أول مهمة فعلية

ابدأ بمهمة صغيرة ومحدودة النطاق ضمن ميزة موجودة (إضافة حقل، تعديل ودجة،
إصلاح خلل بسيط) قبل بناء ميزة جديدة كاملة. هذا يبني حدسك حول النمط الفعلي
المستخدم أسرع من قراءة التوثيق وحده.

عند بناء ميزة جديدة كاملة مستقبلاً، استخدم
[tools/generators/feature_template/](../../tools/generators/feature_template/)
كنقطة بداية بدل نسخ ميزة موجودة يدوياً — القالب مبني ليطابق النمط الفعلي
المستخدم في كل الميزات الـ 17 الحالية تماماً (Cubit + Sealed State + Barrel
File + تفرّع `mobile/desktop` اختياري).

## أين تطلب المساعدة؟

- أسئلة معمارية عامة → راجع `docs/architecture/` أولاً، أغلبها موثَّق.
- أسئلة أمنية/صلاحيات → `docs/security/`.
- أسئلة واجهة/تصميم → `docs/ui_guidelines/`.
- سلوك خاص بالويب لا تتوقعه → `docs/platform_guides/web_notes.md`.
- كل ميزة تحمل توثيقاً غنياً داخل تعليقات `///` في ملفاتها الرئيسية
  (`<feature>_feature.dart`, `<feature>_cubit.dart`) — يشرح القرارات
  المعمارية الخاصة بها تحديداً، اقرأها قبل افتراض أي شيء عن سلوكها.

## قائمة تحقق سريعة قبل أول Pull Request

- [ ] `make format && make analyze && make test` يمرّون بلا أخطاء.
- [ ] كل كتابة بيانات جديدة تتبع نمط محلي-أولاً + Outbox (لا استدعاء
      Supabase مباشر من `presentation/`).
- [ ] أي صلاحية جديدة موجودة في كل من `RolePermissions.map` (Flutter) و
      سياسة RLS مطابقة (Postgres).
- [ ] لا ألوان/مسافات حرّة، لا `EdgeInsets.only(left:/right:)` مباشرة.
- [ ] اختُبرت الشاشة بصرياً بوضع RTL (الافتراضي) على الأقل.
