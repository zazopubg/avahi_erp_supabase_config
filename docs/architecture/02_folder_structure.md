# 02 — هيكل المجلدات النهائي

هذا هو الهيكل الكامل والنهائي لمشروع Avahi بعد اكتمال كل الخطوات الثلاثين
(Prompt 00 → Prompt 30). يُستخدم هذا الملف كمرجع سريع لأي مطوّر جديد أو أي
أداة توليد كود (`tools/generators/`) لمعرفة أين يوضع كل ملف.

```
avahi/
├── Makefile                       # أوامر مختصرة (run/gen/test/analyze...)
├── README.md
├── analysis_options.yaml          # قواعد lint صارمة
├── build.yaml                     # إعدادات build_runner (freezed/drift/injectable)
├── pubspec.yaml / pubspec.lock
│
├── assets/
│   ├── animations/                # Lottie
│   ├── fonts/
│   ├── icons/ (+ svg/)
│   ├── images/ (+ empty_states/)
│   └── l10n/
│       ├── app_ar.arb             # العربية (اللغة الافتراضية، RTL)
│       └── app_en.arb             # الإنجليزية
│
├── backend/
│   ├── .env.example
│   ├── docker-compose.yml         # Supabase محلي كامل (Postgres/Auth/Storage/Kong)
│   ├── docker/
│   │   ├── 00-run-migrations-and-seed.sh
│   │   └── kong.yml
│   └── supabase/
│       ├── config.toml
│       ├── migrations/            # 001 → 020: مخطط قاعدة البيانات كاملاً بالترتيب
│       ├── functions/             # Edge Functions (Deno/TypeScript)
│       │   └── _shared/           # أدوات مشتركة (auth, cors, geo, response...)
│       └── seed/                  # بيانات تجريبية أولية (شركة/مستخدمين/مشروع تجريبي)
│
├── docs/                          # 🆕 (Prompt 30) — هذا المجلد
│   ├── architecture/
│   ├── security/
│   ├── ui_guidelines/
│   ├── platform_guides/
│   ├── onboarding/
│   └── user_manuals/
│
├── tools/                         # 🆕 (Prompt 30)
│   ├── scripts/
│   ├── generators/feature_template/
│   └── icons_generator/
│
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/                      # مشترك بين كل الطبقات، لا منطق أعمال خاص بميزة
│   │   ├── config/                # AppConfig + Env (dev/staging/prod)
│   │   ├── platform/              # كشف الجوال/سطح المكتب/الويب
│   │   ├── constants/             # roles.dart, permissions.dart, storage_keys...
│   │   ├── errors/                # Failure + Exceptions (auth/network/sync/permission)
│   │   ├── utils/ (+ extensions/) # مساعدات عامة (تنسيق تاريخ، GPS، ضغط صور...)
│   │   ├── services/              # خدمات عابرة (إشعارات محلية، تخزين تفضيلات...)
│   │   └── di/                    # get_it: core_module/data_module/domain_module/features_module
│   │
│   ├── domain/                    # Dart خالص — لا استيراد من data/ أو Flutter/Supabase
│   │   ├── entities/              # كائنات الأعمال (AppUser, Project, Task...)
│   │   ├── enums/                 # (LeaveStatus, TaskStatus...)
│   │   ├── repositories/          # عقود مجرّدة (I<Feature>Repository)
│   │   ├── usecases/<feature>/    # حالة استخدام واحدة = ملف واحد = فعل واحد
│   │   └── validators/            # قواعد تحقق أعمال خالصة
│   │
│   ├── data/
│   │   ├── dto/                   # كائنات نقل البيانات (JSON ⇄ Entity)
│   │   ├── cloud/supabase/
│   │   │   ├── client, auth      # تهيئة عميل Supabase + مصادقة
│   │   │   ├── repositories/      # تنفيذ فعلي بعيد (Remote) لكل عقد
│   │   │   ├── realtime/          # اشتراكات Supabase Realtime
│   │   │   └── queries/           # استعلامات معقدة معاد استخدامها
│   │   ├── local/                 # Drift (SQLite/WASM على الويب)
│   │   │   ├── tables/, daos/, migrations/
│   │   ├── storage/                # رفع/تنزيل ملفات (صور، مستندات، توقيعات)
│   │   ├── sync/                   # محرك المزامنة الكامل — انظر 03_sync_strategy.md
│   │   │   ├── outbox/, strategies/, conflict/, retry/, connectivity/
│   │   └── repositories_impl/     # يدمج local + cloud + sync خلف عقد domain الواحد
│   │
│   ├── navigation/
│   │   ├── app_router.dart (ضمنياً) + guards/ + shells/ (adaptive/mobile/desktop) + transitions/
│   │
│   ├── ui/                        # عناصر تصميم مشتركة، لا شاشات كاملة
│   │   ├── theme/  (colors, typography, spacing, radius, shadows, text_scale_guard)
│   │   ├── rtl/    (directionality, icon_flip_rules, number_direction, logical_extensions)
│   │   ├── modes/  (glove_mode, dark_mode, text_scale, locale providers)
│   │   └── widgets/common/
│   │
│   └── features/<feature_name>/   # كل ميزة = presentation فقط (domain/data مشتركة أعلاه)
│       ├── <feature>_feature.dart # ملف تجميعي (Barrel) يصدّر واجهة الميزة العامة فقط
│       └── presentation/
│           ├── screens/
│           │   ├── mobile/        # شاشات هاتف (إن وُجد تفرّع)
│           │   └── desktop/       # شاشات سطح مكتب/ويب عريض (إن وُجد تفرّع)
│           ├── state/             # <feature>_cubit.dart + <feature>_state.dart
│           └── widgets/           # ودجات خاصة بهذه الميزة فقط
│
└── test/
    ├── helpers/                   # Mocks + Test Fixtures + pump helpers مشتركة
    ├── unit/
    │   ├── domain/ (usecases/, validators/)
    │   └── data/ (sync/...)
    ├── widget/features/<feature>/ # اختبارات ودجت لكل ميزة
    ├── golden/ (rtl/, text_scaling/)
    └── integration/
```

## الميزات الـ 17 المبنية فعلياً تحت `lib/features/`

`auth`, `home`, `attendance`, `tasks`, `field_reports`, `photos`,
`punch_list`, `projects`, `documents`, `equipment`, `notifications`,
`leave_requests`, `analytics`, `users`, `settings`, `platform_admin` —
بالإضافة إلى `field_reports/core/services/` كاستثناء موثَّق (خدمة طقس تلقائي
مرتبطة حصراً بهذه الميزة، لا تستحق الانتقال لـ `core/services/` العام).

## قاعدة تسمية صارمة

- ملف الميزة التجميعي: `lib/features/<feature>/<feature>_feature.dart`.
- الحالة: `<feature>_state.dart` (Sealed Class) + `<feature>_cubit.dart`.
- عقد المستودع: `lib/domain/repositories/i_<feature>_repository.dart`.
- التنفيذ الفعلي المدموج: `lib/data/repositories_impl/<feature>_repository_impl.dart`.
- كل حالة استخدام: `lib/domain/usecases/<feature>/<verb>_<noun>_usecase.dart`.

انظر أيضاً [tools/generators/feature_template/](../../tools/generators/feature_template/)
الذي يولّد هذا الهيكل تلقائياً لأي ميزة جديدة مستقبلية.
