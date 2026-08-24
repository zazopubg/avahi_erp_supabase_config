# معايير الكود (Coding Standards)

هذا الملف يلخّص القواعد الملزمة لأي كود جديد يُضاف لمشروع Avahi، مبنية على
`analysis_options.yaml` الفعلي (`flutter analyze` يفشل عند مخالفتها) بالإضافة
لاصطلاحات معمارية غير قابلة للفرض آلياً لكنها موثَّقة صراحة في المشروع.

## 1. صرامة النوع (Type Strictness)

المحلل مضبوط بأقصى صرامة:

```yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
```

- لا `dynamic` ضمني — كل متغيّر ودالة عامة يجب أن يكون نوعها واضحاً
  (`type_annotate_public_apis: true`, `always_declare_return_types: true`).
- لا تحويلات نوع (Casts) غير آمنة بلا تحقق صريح.
- لا أنواع عامة (Generics) خام بلا معامل نوع (`List` بدل `List<String>`
  مثلاً) — ممنوع (`strict-raw-types`).

## 2. قواعد أسلوب إلزامية (من `linter.rules`)

| القاعدة | المعنى العملي |
|---|---|
| `prefer_single_quotes` | اقتباس مفرد `'...'` دوماً، لا مزدوج `"..."` |
| `require_trailing_commas` | فاصلة زائدة في كل استدعاء متعدد الأسطر (`dart format` يطبّقها تلقائياً) |
| `prefer_const_constructors` / `prefer_const_declarations` | `const` في كل مكان ممكن — أداء وإعادة بناء أقل |
| `prefer_final_locals` / `prefer_final_fields` | `final` دوماً ما لم تحتج لإعادة تعيين فعلية |
| `directives_ordering` | ترتيب `import`: Dart/Flutter SDK ← حزم خارجية ← ملفات محلية، كل مجموعة أبجدياً |
| `prefer_relative_imports` | استيراد نسبي (`../../core/...`) بين ملفات المشروع، لا `package:avahi/...` |
| `unawaited_futures` | كل `Future` إما `await` أو ملفوف صراحة بـ `unawaited(...)` — لا نسيان صامت |
| `cancel_subscriptions` / `close_sinks` | كل `StreamSubscription`/`StreamController` يُلغى/يُغلق في `dispose`/`close` |
| `exhaustive_cases` | كل `switch` على `enum`/`sealed class` يغطي كل الحالات — لا `default` كسول يخفي حالة منسية |
| `only_throw_errors` | `throw` فقط لكائنات `Error`/`Exception`، لا نص خام أو أي كائن آخر |
| `avoid_print` | ممنوع `print()` — استخدم `AppLogger` (`core/utils/logger.dart`) دوماً |
| `use_key_in_widget_constructors` | كل `Widget` عام يقبل `super.key` |
| `sort_child_properties_last` | خاصية `child`/`children` دوماً آخر باراميتر في استدعاء Widget |

القائمة الكاملة في [analysis_options.yaml](../../analysis_options.yaml)
مباشرة — لا تُكرَّر هنا كل قاعدة، فقط الأكثر أهمية معمارياً.

## 3. أخطاء تُرفَض دوماً (`analyzer.errors`)

`missing_required_param`, `missing_return`, `must_be_immutable` مضبوطة
كـ `error` صراحة (لا `warning`) — أي كود يخالفها **يفشل** `flutter analyze`
بالكامل، لا يُسمَح بدمجه.

## 4. اصطلاحات معمارية (غير مفروضة آلياً، لكن إلزامية بالمراجعة)

هذه القواعد لا يفرضها `flutter analyze` مباشرة لكنها معيار المشروع الصارم
— أي طلب دمج (Pull Request) يخالفها يُرفَض في المراجعة:

- **لا استيراد من `data/` أو Flutter داخل `domain/`** — طبقة `domain/`
  Dart خالص تماماً (باستثناء `equatable`).
- **لا إنشاء مباشر لتبعية (`XxxRepository()`, `XxxService()`) داخل أي
  Cubit أو شاشة** — كل شيء يُحقَن عبر `sl<T>()`/باني الكلاس
  (`lib/core/di/`).
- **كل حالة Cubit جديدة تتبع نمط `sealed class` بثلاث حالات** (`Loading`/
  `Loaded`/`Error`) بنفس أسلوب الميزات الموجودة — انظر
  [docs/architecture/01_overview.md](../architecture/01_overview.md#إدارة-الحالة-عبر-cubit)
  و[tools/generators/feature_template/](../../tools/generators/feature_template/).
- **لا ألوان/مسافات/استدارات حرّة** — دوماً عبر `AvahiColors`/
  `AvahiSpacing`/`AvahiRadius` (انظر
  [docs/ui_guidelines/color_system.md](../ui_guidelines/color_system.md)).
- **لا `EdgeInsets.only(left:/right:)` مباشرة** — دوماً `EdgeInsetsDirectional`
  أو امتدادات `lib/ui/rtl/logical_extensions.dart` (انظر
  [docs/ui_guidelines/rtl_rules.md](../ui_guidelines/rtl_rules.md)).
- **كل سياسة صلاحية جديدة في `RolePermissions.map` (Flutter) تُقابَل
  بسياسة RLS مطابقة تماماً** في `backend/supabase/migrations/` — لا يُدمَج
  أحدهما بلا الآخر (انظر
  [docs/security/rls_policies.md](../security/rls_policies.md)).
- **كل كتابة بيانات جديدة تمر عبر النمط: محلي أولاً ← Outbox ← مزامنة
  خلفية** — لا استدعاء مباشر لـ Supabase من `presentation/` أو `domain/`
  متجاوزاً `data/repositories_impl/` (انظر
  [docs/architecture/06_offline_first.md](../architecture/06_offline_first.md)).

## 5. التسمية

- الملفات: `snake_case.dart`.
- الأصناف/الأنواع: `PascalCase`.
- المتغيّرات/الدوال: `camelCase`.
- الثوابت على مستوى الملف: `camelCase` مع بادئة `_k` للخاصة
  (`_kLocalDatabaseName`)، أو `SCREAMING_CASE` غير مستخدَم في هذا المشروع.
- كل حالة استخدام (`UseCase`): اسم فعل + اسم، ملف مستقل
  (`check_in_usecase.dart`، لا `attendance_usecases.dart` مجمَّع).

## 6. التوثيق (Doc Comments)

يتبع المشروع أسلوب توثيق غني بالعربية (`///`) لكل صنف عام ودالة عامة غير
بديهية، يشرح **لماذا** لا فقط **ماذا** — خصوصاً القرارات المعمارية غير
الواضحة من الكود وحده (مثال: تعليقات `LeaveCubit` الموسّعة حول قرار عدم
استخدام `UseCase` منفصلة لجلب طلبات الفريق). كود جديد يُتوقَّع منه نفس
مستوى التوثيق، لا فقط تعليق سطر واحد مقتضب.

## 7. التنسيق والتحقق قبل أي Commit

```bash
make format     # dart format lib/ test/
make analyze    # flutter analyze — يجب أن يمر بلا أخطاء ولا تحذيرات
make test       # flutter test — يجب أن تمر كل الاختبارات
```

هذه الأوامر الثلاثة (`tools/scripts/run_tests.sh` يغطي الأخيرين معاً) هي
الحد الأدنى الإلزامي قبل أي طلب دمج — انظر
[setup_guide.md](./setup_guide.md) لتفاصيل تجهيز البيئة كاملة.
