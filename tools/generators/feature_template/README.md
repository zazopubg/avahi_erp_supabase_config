# مولّد قالب الميزة (Feature Template Generator)

يولّد هيكل ميزة `presentation/` جديدة كاملة تحت `lib/features/<اسم_الميزة>/`
مطابقاً تماماً للنمط المعماري الفعلي المستخدَم في كل الميزات الـ 17
الموجودة (`auth`, `home`, `attendance`, `tasks`, `field_reports`,
`photos`, `punch_list`, `projects`, `documents`, `equipment`,
`notifications`, `leave_requests`, `analytics`, `users`, `settings`,
`platform_admin`) — Cubit + Sealed State بثلاث حالات (`Loading`/`Loaded`/
`Error`) + Barrel File + شاشات `mobile`/`desktop` اختيارية.

## الاستخدام

```bash
./tools/generators/feature_template/new_feature.sh <اسم_الميزة_snake_case>

# مثال:
./tools/generators/feature_template/new_feature.sh inspections
```

ينشئ:

```
lib/features/inspections/
├── inspections_feature.dart              # ملف تجميعي (Barrel)
└── presentation/
    ├── state/
    │   ├── inspections_state.dart        # Sealed State + InspectionsData
    │   └── inspections_cubit.dart        # InspectionsCubit
    ├── screens/
    │   ├── mobile/inspections_mobile_home.dart
    │   └── desktop/inspections_desktop_home.dart
    └── widgets/inspections_card.dart     # مثال ودجة عرض
```

## ماذا **لا** يولّده هذا القالب (متعمَّد)

القالب يولّد طبقة `presentation/` فقط — الطبقات الأخرى تختلف جوهرياً
لكل ميزة ولا يمكن توليدها آلياً بمعنى:

- **`domain/entities/`, `domain/repositories/`, `domain/usecases/`**:
  يجب تصميمها يدوياً حسب منطق أعمال ميزتك الفعلي.
- **`data/repositories_impl/`**: تنفيذ محلي أولاً + Outbox + مزامنة —
  راجع [docs/architecture/06_offline_first.md](../../../docs/architecture/06_offline_first.md)
  و[docs/architecture/03_sync_strategy.md](../../../docs/architecture/03_sync_strategy.md)
  قبل البناء.
- **`backend/supabase/migrations/`**: جدول قاعدة بيانات جديد + سياسة RLS
  مطابقة تماماً لصلاحيات الميزة — راجع
  [docs/security/rls_policies.md](../../../docs/security/rls_policies.md).
- **تسجيل DI**: استخدم [di_snippet.dart.tpl](./di_snippet.dart.tpl) كنقطة
  بداية للصقه يدوياً في `lib/core/di/features_module.dart`.
- **التوجيه (Routing)**: أضف مساراً يدوياً في `lib/navigation/app_router.dart`
  مع أي `Guard` صلاحية مناسب.

## خطوات ما بعد التوليد (بالترتيب الموصى به)

1. صمّم الكيانات وعقود المستودع وحالات الاستخدام في `domain/`.
2. نفّذ المستودع في `data/repositories_impl/` (محلي أولاً ← Outbox).
3. استبدل كل تعليقات `TODO` في الملفات المولَّدة تحت `presentation/`.
4. سجّل الـ Cubit في `core/di/features_module.dart` عبر
   [di_snippet.dart.tpl](./di_snippet.dart.tpl).
5. أضف مساراً في `navigation/app_router.dart`.
6. أضف مهاجرة قاعدة بيانات + سياسة RLS في `backend/supabase/migrations/`.
7. أضف اختبارات تحت `test/unit/` و`test/widget/features/<اسم_الميزة>/`.

## لماذا سكربت Bash بدل أداة Dart مخصصة؟

بساطة الصيانة والاستقلالية عن تبعيات Dart إضافية (لا حزمة `mason` أو
مولّد مخصص) — القالب نفسه (ملفات `.tpl`) هو المصدر الوحيد للحقيقة لبنية
أي ميزة جديدة؛ عدّل ملفات `.tpl` هنا مباشرة إن تغيّر النمط المعماري
القياسي مستقبلاً لكل الميزات، لا `new_feature.sh` نفسه (الذي يبقى مجرد
آلية نسخ/استبدال نصوص بسيطة).
