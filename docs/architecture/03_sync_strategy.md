# 03 — استراتيجية المزامنة بالتفصيل

المزامنة في Avahi مبنية حول نمط **Outbox** الكلاسيكي: كل كتابة (Insert/
Update/Delete) تُسجَّل أولاً محلياً في Drift **قبل** أي محاولة اتصال
بالشبكة، ثم تُدفَع لاحقاً إلى Supabase بشكل غير متزامن ومستقل تماماً عن دورة
حياة الشاشة التي أطلقتها.

## 1. مكوّنات محرك المزامنة (`lib/data/sync/`)

```
sync/
├── sync.dart                  # ملف تجميعي يصدّر واجهة الوحدة بالكامل
├── sync_engine.dart           # المنسّق الأعلى: يربط Outbox + Strategies + Connectivity
├── sync_scheduler.dart        # يشغّل/يوقف الاستراتيجيات المسجّلة عبر SyncEngine
├── outbox/
│   ├── outbox_queue.dart          # واجهة الإضافة/القراءة عالية المستوى فوق OutboxDao
│   ├── outbox_processor.dart      # ينفّذ كل عملية معلّقة فعلياً (يستدعي Remote Writer)
│   ├── outbox_remote_writer.dart  # يرسل الحمولة فعلياً إلى Supabase ويكتشف التعارض
│   ├── photo_upload_processor.dart# معالج خاص بالصور (Supabase Storage، لا PostgREST)
│   └── idempotency_helper.dart    # يمنع تكرار نفس العملية عبر clientMutationId
├── strategies/
│   ├── sync_strategy.dart         # عقد موحّد: `start(onTrigger)` / `stop()`
│   ├── continuous_sync.dart       # مؤقّت دوري ثابت (30ث افتراضياً، حسب البيئة إنتاجاً)
│   └── foreground_sync.dart       # مزامنة فورية عند استعادة تركيز التبويب/التطبيق
├── conflict/
│   ├── conflict_resolver.dart     # العقد + enum النتيجة (keepLocal/keepRemote/needsManual)
│   ├── last_write_wins.dart       # المُحلِّل الافتراضي (بحسب `updated_at`)
│   ├── first_write_wins.dart      # إلزامي لبيانات الحضور (انظر أدناه لماذا)
│   └── manual_resolve.dart        # يبقي السجل بحالة conflict بانتظار تدخّل بشري
├── retry/
│   ├── retry_policy.dart          # عدد المحاولات القصوى + شروط التخلي
│   └── exponential_backoff.dart   # حساب مهلة الانتظار المتصاعدة بين المحاولات
└── connectivity/
    └── network_monitor.dart       # يبثّ حالة الاتصال (متصل/غير متصل) لبقية الوحدة
```

## 2. دورة حياة عملية كتابة واحدة (خطوة بخطوة)

1. **الكتابة المحلية الفورية**: `<Feature>RepositoryImpl` (في
   `data/repositories_impl/`) يكتب مباشرة إلى جدول Drift المحلي المعني
   ويُرجع النتيجة للـ `UseCase`/`Cubit` **فوراً** — المستخدم لا ينتظر الشبكة
   إطلاقاً، وهذا هو جوهر Offline-First (تفاصيل أوسع في
   [06_offline_first.md](./06_offline_first.md)).
2. **الإضافة إلى الطابور**: بالتوازي (ضمن نفس المعاملة المحلية)، تُستدعى
   `OutboxQueue.enqueue(...)` مع: `entityType` (مثال: `'attendance'`)،
   `entityId`، `operationType` (`insert`/`update`/`delete`)، `payload` (JSON
   بصيغة `snake_case` مطابقة لبنية جدول Supabase)، و`clientMutationId`
   اختياري لمنع التكرار (Idempotency) — إن أُعيد إرسال نفس الطلب (بسبب Retry
   من الواجهة نفسها) لن يُضاف مرتين للطابور.
3. **الانتظار حتى الزناد (Trigger)**: `SyncEngine` لا يعالج الطابور فوراً؛
   ينتظر تشغيلاً من إحدى `SyncStrategy` المسجّلة (انظر القسم 3) **و** توفر
   اتصال فعلي عبر `NetworkMonitor`.
4. **السحب والمعالجة**: عند التشغيل، `OutboxProcessor` يسحب العمليات
   المعلّقة عبر `OutboxQueue.pending()` — **مرتّبة حسب الأولوية أولاً، ثم
   الأقدم أولاً (FIFO) ضمن نفس الأولوية** — ويعالجها عملية تلو الأخرى (لا
   تعالج دورتان متوازيتان في آن، يضمن ذلك `SyncEngine`).
5. **الإرسال الفعلي**: `OutboxRemoteWriter` يرسل الحمولة إلى Supabase
   (`data/cloud/supabase/repositories/`)، ويقارن — إن كانت العملية
   `update` — الطابع الزمني/النسخة المحلية بالنسخة السحابية الحالية لاكتشاف
   تعارض حقيقي (`_isGenuineConflict`) قبل الكتابة فعلياً، لا بعدها.
6. **عند النجاح**: تُزال العملية من الطابور (`OutboxQueue.remove`) ويُحدَّث
   عمود `synced`/`syncState` للسجل المحلي المعني.
7. **عند الفشل (خطأ شبكة/خادم)**: تُسجَّل المحاولة الفاشلة
   (`OutboxQueue.recordFailure`) وتُطبَّق `RetryPolicy` +
   `ExponentialBackoff` قبل إعادة المحاولة في الدورة التالية — العملية تبقى
   في الطابور، لا تُفقَد أبداً.
8. **عند اكتشاف تعارض حقيقي**: يُستدعى `ConflictResolver` المناسب لنوع
   الكيان (انظر القسم 4) لحسم النتيجة تلقائياً، أو تعليم السجل بحالة
   `conflict` بانتظار حل يدوي مستقبلي إن تعذّر الحسم الآلي.

## 3. الاستراتيجيات (متى تُشغَّل دورة مزامنة؟)

يعمل نمطان معاً بأمان دون تعارض (كلاهما يستدعيان نفس `onTrigger`، و
`SyncEngine` يمنع التداخل):

| الاستراتيجية | الزناد | الفترة/الشرط |
|---|---|---|
| `ContinuousSyncStrategy` | `Timer.periodic` ثابت | 30 ثانية افتراضياً في التطوير؛ `AppConfig.instance.syncInterval` فعلياً — **دقيقة واحدة** في `dev`، **3 دقائق** في `staging`، **5 دقائق** في `prod` (لتقليل الحمل على الخادم) |
| `ForegroundSyncStrategy` | `WidgetsBindingObserver.didChangeAppLifecycleState == resumed` | فوري عند عودة تبويب المتصفح للواجهة (Page Visibility API عبر Flutter Web) |

كلا الاستراتيجيتين تتحققان أيضاً من `NetworkMonitor` قبل التنفيذ الفعلي —
لا قيمة لتشغيل دورة مزامنة بلا اتصال.

## 4. حل التعارضات (Conflict Resolution)

يُختار المُحلِّل بحسب `entityType`:

- **`FirstWriteWinsResolver` — إلزامي لبيانات الحضور (`attendance`)**: أول
  تسجيل حضور/انصراف يصل للخادم هو المعتمَد، وأي محاولة كتابة لاحقة لنفس
  السجل تُرفَض وتُبقي على القيمة السحابية. هذا قرار عمل متعمّد: حضور مزدوج
  أو انصراف مزدوج لنفس العامل في نفس اليوم مشكلة تشغيلية/محاسبية أخطر
  بكثير من فقدان تعديل ثانٍ، فالأولوية لأول قيمة "حقيقية" مسجَّلة وليس آخر
  قيمة.
- **`LastWriteWinsResolver` — الافتراضي لكل شيء آخر (المهام، إلخ)**: يقارن
  حقل `updated_at` بين النسخة المحلية والسحابية عبر Optimistic Concurrency
  Control؛ الأحدث زمنياً يفوز. إن تعذّر قراءة أحد الطابعين الزمنيين بثقة،
  الافتراض الآمن هو **الإبقاء على النسخة السحابية** (المصدر الرسمي للحقيقة
  عند الشك).
- **`ManualResolveResolver`**: يُبقي السجل بحالة `conflict` صراحة بانتظار
  واجهة حل تعارضات بشرية (خارج نطاق هذه الخطوات الثلاثين؛ البنية التحتية
  جاهزة له عبر `ConflictOutcome.needsManual`).

## 5. إعادة المحاولة (Retry) والتراجع الأسي (Backoff)

- `RetryPolicy` يحدّد عدد المحاولات القصوى قبل اعتبار العملية "متعثرة"
  (Stalled) وعرضها في واجهة المستخدم كعنصر يحتاج انتباهاً (شارة "غير
  متزامن" عبر `OutboxQueue.watchPendingCount()`).
- `ExponentialBackoff` يحسب مهلة الانتظار المتصاعدة بين المحاولات (تتضاعف
  تقريبياً في كل فشل متتالٍ) لتفادي إغراق الخادم بطلبات متكررة عند انقطاع
  ممتد.

## 6. حالة خاصة: رفع الصور (`photo_upload_processor.dart`)

الصور لا تُرسَل عبر `OutboxRemoteWriter` القياسي (PostgREST) لأنها بيانات
ثنائية كبيرة تُخزَّن في Supabase Storage لا في جدول عادي — لها معالج مستقل
(`PhotoUploadProcessor`) يرفع الملف الثنائي أولاً إلى Storage ثم يكتب سجل
البيانات الوصفية (Metadata) عبر PostgREST بعد نجاح الرفع، مع نفس منطق
Retry/Backoff للطابور القياسي.

## 7. الربط بواجهة المستخدم

`OutboxQueue.watchPendingCount()` بث حي (Stream) بعدد العمليات المعلّقة،
يُستهلَك من `ui/widgets/common/` لعرض شارة "غير متزامن" (Unsynced Badge) في
أي مكان مناسب من الواجهة — يمنح العامل الميداني ثقة مرئية بأن عمله محفوظ
محلياً حتى لو لم يُرسَل بعد.
