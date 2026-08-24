# Avahi

منصة إدارة العمليات الميدانية والقوى العاملة (Field Operations & Workforce
Management) — تطبيق **ويب حصراً** مبني بـ Flutter، يعتمد **Clean
Architecture** (Domain / Data / Presentation) وإدارة الحالة عبر **Cubit**
(flutter_bloc).

> ⚠️ **ملاحظة مهمة**: هذا المشروع يستهدف متصفح الويب (Chrome) حصراً في
> مرحلته الحالية. لا توجد ولن تُنشأ مجلدات `android/` أو `ios/` أو
> `windows/` أو `macos/` أو `linux/`.

---

## المتطلبات الأساسية

- Flutter SDK ≥ 3.22.0 (قناة stable)
- Dart SDK ≥ 3.4.0
- متصفح Google Chrome مثبّت على الجهاز
- حساب [Supabase](https://supabase.com) (للـ backend السحابي)

تحقق من إعداد بيئتك:

```bash
flutter doctor
flutter config --enable-web
```

---

## التشغيل السريع

```bash
# 1) تثبيت الحزم
flutter pub get

# 2) توليد الأكواد (freezed / json_serializable / injectable / drift)
dart run build_runner build --delete-conflicting-outputs

# 3) تشغيل التطبيق على Chrome
flutter run -d chrome
```

أو ببساطة عبر Makefile:

```bash
make run
```

---

## بنية المشروع (Clean Architecture)

```
lib/
├── main.dart, app.dart          # نقطة الدخول
├── ui/                          # الثيم، دعم RTL، الودجت المشتركة
├── core/                        # الإعدادات، الأخطاء، الأدوات، DI
├── domain/                      # Entities, Repositories (واجهات), UseCases
├── data/                        # DTOs, Supabase, Drift (محلي), مزامنة
├── navigation/                  # go_router, الحراس، الـ Shells
└── features/                    # كل ميزة بنمط Presentation-Cubit مستقل

backend/
└── supabase/                    # migrations, functions, seed
```

سيتم بناء هذه المجلدات تباعاً عبر خطوات (Prompts) لاحقة، دون حذف أو
إعادة إنشاء ما تم بناؤه سابقاً — يُتّبع مبدأ **الترقيع التراكمي (Patch &
Extend)**.

---

## الأوامر المتاحة (Makefile)

| الأمر         | الوصف                                             |
|---------------|----------------------------------------------------|
| `make run`    | تشغيل التطبيق على Chrome                           |
| `make gen`    | تشغيل build_runner لتوليد الأكواد                  |
| `make test`   | تشغيل جميع الاختبارات                              |
| `make analyze`| تحليل الكود بحسب قواعد analysis_options.yaml       |

---

## الخطوط المستخدمة

- **Cairo** (Regular / Medium / Bold) — الخط الأساسي للواجهة العربية
- **IBM Plex Sans Arabic** (Regular / Bold) — خط ثانوي/بديل

## الترجمة (l10n)

ملفات الترجمة موجودة في `assets/l10n/` بصيغة ARB:
- `app_ar.arb` — العربية (اللغة الافتراضية)
- `app_en.arb` — الإنجليزية

---

## حالة البناء الحالية

انظر شجرة الحالة التراكمية في وثائق المشروع الداخلية لمعرفة الخطوات
(Prompts) المكتملة والمتبقية.
