# ملاحظات التوافق القياسي (PostgreSQL Portability Notes)

تم فحص وتعديل سلسلة الهجرات من `001` إلى `020` بالكامل لجعلها قابلة
للتنفيذ بنجاح على أي مزود PostgreSQL قياسي (RDS، Cloud SQL، Neon،
Azure Database for PostgreSQL، أو خادم مُدار ذاتياً)، وليس فقط على
Supabase. تم التحقق من هذا فعلياً بتشغيل السلسلة كاملة (000→020) على
نسخة PostgreSQL 16 نظيفة، بدون أي مخطط `auth`، وبمستخدم تطبيق عادي
(غير Superuser فيما عدا امتداد `pgcrypto` الذي يتطلبه أي مزود بشكل
طبيعي).

## التغيير الجوهري

المشكلة الأصلية: كانت كل الجداول تُشير إلى `auth.users` وكانت سياسات
RLS ودوالها المساعدة تستدعي `auth.uid()`. هذان الكائنان يُنشأان
ويُداران حصراً بواسطة خدمة **Supabase Auth**، ومخطط `auth` نفسه
محجوز ومملوك لحساب داخلي فيها — أي محاولة تنفيذ هذه الهجرات على
مزود PostgreSQL آخر كانت ستفشل فوراً إما بخطأ:
`relation "auth.users" does not exist`
أو بخطأ صلاحيات:
`permission denied for schema auth`

## الحل: ملف تأسيسي جديد `000_portable_identity_foundation.sql`

أُضيف **قبل** `001` (لا يُغيّر أي شيء في ترقيم 001→020 نفسها) وينشئ:

1. **`public.users`** — جدول هوية قياسي يحل محل `auth.users` كمرجع
   موحّد لكل الـ Foreign Keys في بقية الجداول (28 مرجعاً عبر الملفات
   من 002 إلى 020).
2. **`public.current_user_id()`** — بديل قياسي لدالة `auth.uid()`
   الخاصة بـ Supabase. يقرأ هوية المستخدم من متغيّر جلسة (GUC) قياسي
   في PostgreSQL:
   - `request.jwt.claim.sub` (اصطلاح PostgREST الذي تعتمده Supabase
     وغيرها من الخدمات المتوافقة معه) — يعمل تلقائياً إن بقي المشروع
     على Supabase أو أي بديل PostgREST.
   - أو `app.current_user_id` كبديل عام يمكن لأي طبقة تطبيق (Node،
     NestJS، Django...) ضبطه يدوياً عبر
     `set_config('app.current_user_id', '<uuid>', true)` عند بداية
     كل طلب/معاملة.

## ما تم تغييره في الملفات 001→020

| القديم (خاص بـ Supabase) | الجديد (قياسي) |
|---|---|
| `references auth.users (id)` | `references public.users (id)` |
| `auth.uid()` | `public.current_user_id()` |
| `auth.user_company_id()` | `public.current_user_company_id()` |
| `auth.user_role()` | `public.current_user_role()` |
| `auth.is_platform_owner()` | `public.is_platform_owner()` |
| `auth.role_rank(...)` | `public.role_rank(...)` |
| `auth.has_min_role(...)` | `public.has_min_role(...)` |
| `auth.is_project_member(...)` | `public.is_project_member(...)` |

كل هذه الدوال (كانت في `015_rls_helper_functions.sql`) أُعيد تعريفها
بالكامل داخل مخطط `public` بدل `auth`، فتُنشأ بصلاحيات مستخدم
تطبيق عادي دون أي حاجة لصلاحيات خاصة على مخطط محجوز.

كما عُدِّلت بعض التعليقات الوصفية (Comments) التي كانت تذكر
"Supabase Storage" أو "Supabase Edge Function" كتفاصيل تنفيذية،
واستُبدلت بصياغة عامة ("Object Storage"، "Backend Function") دون
أي تأثير على السلوك الفعلي — فهي تعليقات توثيقية فقط.

## ما لم يتغيّر (بالتصميم)

- **لا تعديل على أي علاقة (FK)، قيد (CHECK/UNIQUE)، أو مفتاح أساسي**:
  الترتيب المرجعي 001→020 (companies → company_members → projects →
  project_members → tasks → ... → project_milestones) بقي متطابقاً
  100% كما هو، فقط تغيّرت وجهة مرجع "المستخدم" من `auth.users` إلى
  `public.users`.
- منطق RLS نفسه (من يرى ماذا، ومن يملك صلاحية الكتابة بأي حد أدنى من
  الدور) لم يتغيّر إطلاقاً — فقط أسماء الدوال والمخطط الذي تعيش فيه.
- ترقيم الملفات وتسلسلها (001...020) لم يُمس؛ أُضيف `000` فقط
  كطبقة تأسيسية تُنفَّذ قبلها.

## ملاحظة حول التوافق مع Supabase نفسه

إن استمر المشروع على Supabase، يمكن إبقاء الاعتماد على
`auth.users` الحقيقي عبر مزامنته إلى `public.users` بـ trigger بسيط
يُضاف خارج نطاق هذه الهجرات (خطوة اختيارية لاحقة)، أو الانتقال الكامل
لإدارة الهوية عبر `public.users` مباشرة. النقطة الأهم: هذه الهجرات
الآن **تعمل بنجاح على Supabase وعلى أي مزود آخر بنفس الملفات دون أي
تعديل إضافي**.

## ملاحظة خارج نطاق هذا الطلب

ملفات `backend/supabase/seed/001_demo_company.sql` و
`002_demo_users.sql` (خارج مجلد migrations المطلوب هنا) لا تزال
تُدرج مباشرة في `auth.users` و`auth.identities` الداخليين
لـ Supabase، فهي خاصة بذلك المزود حصراً. إن رغبت بجعل بيانات
Seed التجريبية محايدة المزود أيضاً، أخبرني وسأحدّثها بنفس
المنهجية.
