# 01 — نظرة عامة على معمارية Avahi

## ما هو Avahi؟

Avahi منصة إدارة عمليات ميدانية وقوى عاملة (Field Operations & Workforce
Management) مبنية بـ Flutter، تعمل بشكل أساسي عبر المتصفح (`flutter run -d
chrome`)، بخلفية Supabase (Postgres + Auth + Storage + Realtime + Edge
Functions)، ومصممة لتعمل **Offline-First**: كل عملية يقوم بها المستخدم تُكتب
أولاً محلياً (Drift) ثم تُزامَن لاحقاً مع السحابة، بحيث يستمر عمل العامل
الميداني حتى بلا اتصال إنترنت مستقر.

التطبيق متعدد المستأجرين (Multi-tenant): كل شركة (`companies`) معزولة تماماً
عن غيرها عبر سياسات RLS في Postgres، ويوجد فوق كل الشركات مستوى "مالك منصة"
(`platform_admins`) له رؤية وصلاحيات عابرة لكل المستأجرين (`lib/features/
platform_admin/`).

## المبادئ المعمارية الحاكمة

1. **Clean Architecture صارمة بثلاث طبقات**: `domain` (منطق أعمال خالص، بلا
   أي اعتماد على Flutter أو Supabase) ← `data` (تنفيذ فعلي محلي/سحابي) ←
   `presentation` (شاشات + Cubit لكل ميزة). الاعتماد يتجه دوماً من الخارج
   إلى الداخل: `presentation` يعتمد على `domain`، و`data` ينفّذ عقود
   `domain`، لكن `domain` لا يعرف شيئاً عن `data` أو `presentation`.
2. **إدارة حالة موحّدة عبر Cubit** (`flutter_bloc`) — لا `Provider` عاري ولا
   `setState` لمنطق أعمال. كل ميزة لها Cubit واحد أو أكثر بحالة مكتوبة يدوياً
   كـ Sealed Class (`Loading` / `Loaded` / `Error`)، انظر
   [03_state_management (ضمن هذا الملف أدناه)](#إدارة-الحالة-عبر-cubit).
3. **Offline-First حقيقي، لا مجرد تخزين مؤقت** — التفاصيل الكاملة في
   [06_offline_first.md](./06_offline_first.md) واستراتيجية المزامنة في
   [03_sync_strategy.md](./03_sync_strategy.md).
4. **حقن الاعتماديات المركزي عبر `get_it`** (`lib/core/di/`) — لا إنشاء
   مباشر (`XxxRepository()`) داخل أي Cubit أو شاشة؛ كل التبعيات تُحقَن عبر
   `sl<T>()` (Service Locator)، مما يجعل الاستبدال بنسخ وهمية (Mocks) في
   الاختبارات ممكناً بلا تعديل كود الإنتاج.
5. **تكييف واجهة كامل بين الهاتف/الجوال وسطح المكتب/الويب من نفس القاعدة
   البرمجية** — لا تطبيقين منفصلين. التفاصيل في
   [05_responsive_web.md](./05_responsive_web.md).
6. **أمان على مستوى قاعدة البيانات، لا فقط الواجهة** — كل تحقق صلاحية يظهر في
   الواجهة (`core/constants/permissions.dart`) يقابله دوماً سياسة RLS مطابقة
   في Postgres (`backend/supabase/migrations/016_rls_policies.sql`)، لأن
   الواجهة يمكن التحايل عليها لكن قاعدة البيانات لا يمكن. التفاصيل الكاملة في
   [docs/security/rls_policies.md](../security/rls_policies.md).

## خريطة الطبقات الثلاث

```
┌─────────────────────────────────────────────────────────────┐
│  presentation/  (lib/features/<feature>/presentation/)        │
│  شاشات (screens/mobile, screens/desktop) + Cubit + State      │
│  تعتمد على → domain فقط (عبر usecases/repositories interfaces)│
└───────────────────────────┬─────────────────────────────────┘
                             │ يستدعي عقود (interfaces)
┌───────────────────────────▼─────────────────────────────────┐
│  domain/  (lib/domain/)                                       │
│  entities/ + enums/ + repositories/ (abstract) + usecases/ +  │
│  validators/ — Dart خالص، بلا أي import من data أو Flutter    │
│  Material/Supabase (باستثناء Equatable/dart:core)              │
└───────────────────────────▲─────────────────────────────────┘
                             │ ينفّذ العقود (implements)
┌───────────────────────────┴─────────────────────────────────┐
│  data/  (lib/data/)                                            │
│  cloud/supabase/ (مصدر بعيد) + local/ (Drift، مصدر محلي) +     │
│  sync/ (Outbox + Strategies + Conflict) + repositories_impl/   │
│  (يدمج المصدرين حسب الأولوية Offline-First)                    │
└─────────────────────────────────────────────────────────────┘
```

## خريطة تدفّق طلب نموذجي (مثال: تسجيل حضور "Check-in")

1. المستخدم يضغط `BigCheckInButton` في `attendance/presentation/widgets/`.
2. الشاشة تستدعي `context.read<AttendanceCubit>().checkIn(...)`.
3. `AttendanceCubit` يستدعي `CheckInUsecase` (طبقة `domain/usecases/
   attendance/`) — الذي يتحقق من قواعد العمل الخالصة (مثلاً: عدم تسجيل
   حضور مزدوج) دون معرفة كيف يُخزَّن ذلك فعلياً.
4. `CheckInUsecase` يستدعي `IAttendanceRepository` (عقد مجرد في `domain/
   repositories/`).
5. `AttendanceRepositoryImpl` (في `data/repositories_impl/`) ينفّذ العقد:
   يكتب أولاً إلى Drift المحلي (استجابة فورية دون انتظار الشبكة)، ثم يضيف
   العملية إلى `OutboxQueue` (`data/sync/outbox/`) لتُزامَن لاحقاً.
6. `SyncEngine` (`data/sync/sync_engine.dart`) يلتقط العملية من الـ Outbox
   عند توفر اتصال (`ConnectivityHelper`) ويرسلها إلى Supabase عبر
   `SupabaseAttendanceRepository` الفعلي في `data/cloud/supabase/`.
7. عند النجاح، تُحدَّث حالة العملية في Drift (`synced = true`)، وإن حدث
   تعارض (Conflict) يُحل عبر استراتيجية `LastWriteWins`/`FirstWriteWins`/
   حل يدوي — التفاصيل في [03_sync_strategy.md](./03_sync_strategy.md).

## الملفات الأخرى في هذا المجلد

| الملف | المحتوى |
|---|---|
| [02_folder_structure.md](./02_folder_structure.md) | هيكل المجلدات النهائي الكامل لكل `lib/` و`backend/` و`test/` |
| [03_sync_strategy.md](./03_sync_strategy.md) | تفاصيل كاملة لاستراتيجية المزامنة والـ Outbox وحل التعارضات |
| [04_data_model_erd.md](./04_data_model_erd.md) | نموذج البيانات الكامل (ERD نصي) لكل جداول Postgres |
| [05_responsive_web.md](./05_responsive_web.md) | تكييف الواجهة عبر عرض الشاشة على الويب (Breakpoints/Shells) |
| [06_offline_first.md](./06_offline_first.md) | فلسفة Offline-First وتفاصيلها التقنية الكاملة |

## إدارة الحالة عبر Cubit

كل ميزة (`lib/features/<feature>/presentation/state/`) تتبع نمطاً موحّداً
صارماً في كل الميزات الـ 17 المبنية (`auth`, `home`, `attendance`, `tasks`,
`field_reports`, `photos`, `punch_list`, `projects`, `documents`,
`equipment`, `notifications`, `leave_requests`, `analytics`, `users`,
`settings`, `platform_admin`):

- ملف `<feature>_state.dart`: `sealed class` بثلاث حالات فقط —
  `<Feature>Loading` / `<Feature>Loaded(data)` / `<Feature>Error(failure)` —
  مع دالتي مساعدة `when<T>(...)` و`maybeWhen<T>(...)` مكتوبتين يدوياً (بلا
  حزمة `freezed` لتوليد الحالة، لتبسيط الاطلاع على الكود وتقليل زمن البناء
  عبر `build_runner`).
- ملف `<feature>_cubit.dart`: يرث `Cubit<<Feature>State>`، يستقبل كل
  `UseCase`/`Repository` التي يحتاجها عبر الباني (Constructor Injection) —
  لا `sl<T>()` مباشرة داخل جسم الـ Cubit إلا في حالات موثّقة استثنائياً
  (انظر تعليقات `LeaveCubit`/`PhotosCubit` كأمثلة).
- الحالة `Loaded` تحمل كائن بيانات مجمّع واحد (مثال: `LeaveData`،
  `AttendanceData`) بدل حقول متفرقة، بحيث تستهلكه كل شاشات الميزة (الهاتفية
  والمكتبية) من نفس المصدر الموحّد.

انظر [tools/generators/feature_template/](../../tools/generators/feature_template/)
للقالب الجاهز الذي يطبّق هذا النمط تلقائياً عند إضافة ميزة جديدة مستقبلاً.
