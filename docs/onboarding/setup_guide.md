# دليل إعداد بيئة التطوير

يشرح هذا الدليل خطوة بخطوة كيفية تجهيز بيئة تطوير محلية كاملة لمشروع
Avahi: Flutter + Supabase محلي (عبر Docker) + تشغيل التطبيق على Chrome.

## المتطلبات الأساسية

| الأداة | الإصدار الأدنى | ملاحظة |
|---|---|---|
| Flutter SDK | `>=3.22.0` | يطابق `pubspec.yaml: environment.flutter` |
| Dart SDK | `>=3.4.0 <4.0.0` | مرفق مع Flutter SDK |
| Google Chrome | أي إصدار حديث | منصة التشغيل الوحيدة المستهدَفة (`flutter run -d chrome`) |
| Docker + Docker Compose | حديث | لتشغيل Supabase محلياً عبر `backend/docker-compose.yml` |
| Supabase CLI | حديث | اختياري (بديل لـ docker-compose المباشر) لإدارة `supabase db reset`/المهاجرات |

تحقق من تثبيت Flutter بشكل صحيح ودعمه للويب:

```bash
flutter doctor
flutter config --enable-web
```

## الخطوة 1 — استنساخ المشروع وتثبيت الحزم

```bash
git clone <رابط المستودع> avahi
cd avahi
make get          # أو: flutter pub get
```

## الخطوة 2 — تشغيل Supabase محلياً

### الخيار أ: عبر Docker Compose مباشرة (يطابق `backend/docker-compose.yml`)

```bash
cd backend
cp .env.example .env    # ثم عدّل القيم الحساسة إن لزم (انظر تعليقات الملف)
docker compose up -d
```

هذا يشغّل: Postgres (منفذ `54322`)، Kong/API Gateway (منفذ `54321`)،
Supabase Studio (منفذ `54323`)، Inbucket للبريد التجريبي (منفذ `54324`).

### الخيار ب: عبر Supabase CLI (يطابق `backend/supabase/config.toml`)

```bash
cd backend
supabase start
```

يقرأ `config.toml` تلقائياً وينشئ نفس الخدمات بنفس المنافذ.

### تطبيق المخطط والبيانات التجريبية

المهاجرات (`backend/supabase/migrations/001` → `020`) تُطبَّق تلقائياً عند
أول تشغيل (`00-run-migrations-and-seed.sh`)، أو يدوياً:

```bash
tools/scripts/supabase_reset.sh
```

هذا يعيد ضبط قاعدة البيانات كاملة (المخطط + سياسات RLS + بيانات تجريبية من
`backend/supabase/seed/`) — مفيد بعد أي تعديل على المهاجرات نفسها.

### التحقق من عمل الخدمات

- **Supabase Studio**: `http://localhost:54323` — واجهة إدارة قاعدة
  البيانات (تصفح الجداول، تشغيل SQL، إلخ).
- **Inbucket** (بريد تجريبي): `http://localhost:54324` — لعرض رسائل
  البريد الإلكتروني المرسَلة من `auth` (تأكيد حساب، إعادة تعيين كلمة مرور)
  دون الحاجة لخادم بريد حقيقي.

## الخطوة 3 — ربط Flutter بـ Supabase (عبر `dart_define.json`)

⚠️ تصحيح: القيم الحساسة (`SUPABASE_URL`/`SUPABASE_ANON_KEY`) لا تُقرأ من
`env.dev.dart` إطلاقاً — ذلك الملف يحتوي فقط على قيم غير حساسة (مهلة
الشبكة، فترة المزامنة). القيم الحساسة تُقرأ حصراً عبر `--dart-define` وقت
البناء/التشغيل (`lib/core/config/env.dart`)، ولا يوجد ملف `.env` حقيقي على
مستوى Flutter نفسه.

أنشئ ملف الإعداد المحلي (غير مُدرَج في Git — مُستثنى عبر `.gitignore`):

```bash
cp dart_define.example.json dart_define.json
```

ثم عدّل `SUPABASE_URL`/`SUPABASE_ANON_KEY` داخل `dart_define.json`:
- **Supabase محلي (Docker)**: `SUPABASE_URL=http://localhost:54321`،
  و`SUPABASE_ANON_KEY` = قيمة `ANON_KEY` من `backend/.env`.
- **مشروع Supabase سحابي**: عنوان المشروع (`https://<project-ref>.supabase.co`)
  والمفتاح العلني (`anon`/`publishable`) من لوحة تحكم المشروع
  (Project Settings → API).

`make run`/`tools/scripts/run_web.sh` يقرآن هذا الملف تلقائياً عبر
`--dart-define-from-file` — لا حاجة لتمرير القيم يدوياً في كل مرة.

## الخطوة 4 — توليد الأكواد (Code Generation)

المشروع يعتمد على `build_runner` لعدة حزم (freezed، json_serializable،
injectable، drift):

```bash
make gen
# أو للمراقبة المستمرة أثناء التطوير:
make watch
```

**يجب تشغيل هذا قبل أول `flutter run`** — بدونه ستفشل الأكواد التي تعتمد
على ملفات `.g.dart` المولَّدة (خصوصاً جداول/DAOs Drift و`injection_
container.config.dart`).

## الخطوة 5 — تشغيل التطبيق

```bash
make run
# أو مباشرة عبر السكربت الجاهز (نفس الغطاء + تحقق إضافي من توفر Chrome):
tools/scripts/run_web.sh
```

كلاهما يحقن `dart_define.json` تلقائياً (الخطوة 3) — إن كان الملف مفقوداً
سيُقلع التطبيق برسالة خطأ واضحة أثناء `bootstrap.dart` بدل شاشة بيضاء.

يفتح Chrome تلقائياً على التطبيق مع Hot Reload مفعّلاً.

## الخطوة 6 — توليد ملفات الترجمة (إن عدّلت `.arb`)

عند إضافة/تعديل مفاتيح في `assets/l10n/app_ar.arb` أو `app_en.arb`:

```bash
tools/scripts/generate_l10n.sh
```

## الخطوة 7 — تشغيل الاختبارات

```bash
make test
# أو السكربت الشامل (تنسيق + تحليل + اختبار):
tools/scripts/run_tests.sh
```

## تسجيل الدخول التجريبي

بعد `supabase_reset.sh`، بيانات الشركة والمستخدمين التجريبيين متوفرة عبر
`backend/supabase/seed/001_demo_company.sql` و`002_demo_users.sql` — راجع
تلك الملفات مباشرة لبيانات اعتماد الدخول التجريبية الحالية (بريد إلكتروني/
كلمة مرور) لكل دور (`worker`, `foreman`, `engineer`, `projectManager`,
`admin`).

## مشاكل شائعة

| المشكلة | الحل |
|---|---|
| `flutter run -d chrome` لا يجد Chrome | تأكد من تثبيت Chrome وتوفره في `PATH`، أو حدّد المسار عبر `CHROME_EXECUTABLE` |
| فشل الاتصال بـ Supabase محلياً | تحقق من تشغيل الحاويات: `docker compose ps` (من `backend/`) |
| أخطاء بعد تعديل جدول Drift | أعد تشغيل `make gen` — تأكد من عدم نسيان تحديث `database_migrations.dart` لرقم إصدار جديد |
| تعارض منافذ (Port already in use) | منافذ Supabase المحلية ثابتة في `config.toml`/`.env` — أوقف أي خدمة أخرى تستخدم نفس المنفذ أو عدّل القيم محلياً |

انظر أيضاً [new_developer_guide.md](./new_developer_guide.md) للخطوات
التالية بعد اكتمال الإعداد، و
[coding_standards.md](./coding_standards.md) قبل أول Commit.
