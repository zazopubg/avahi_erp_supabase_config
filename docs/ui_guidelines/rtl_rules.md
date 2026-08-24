# قواعد RTL

العربية هي اللغة الافتراضية للتطبيق واتجاهها RTL هو الوضع الأساسي المُختبَر
أولاً لكل شاشة — الإنجليزية (LTR) دعم ثانوي، لا العكس. كل قواعد RTL موحّدة
مركزياً في `lib/ui/rtl/` بدل تفريقها بمنطق شرطي متكرر (`if (isRtl) ...`)
داخل شاشات الميزات.

## 1. استخدم الخصائص المنطقية (Logical/Directional) دوماً — لا `left`/`right`

`lib/ui/rtl/logical_extensions.dart` يوفّر امتدادات بنّاءة فوق
`EdgeInsetsDirectional`/`AlignmentDirectional`/`BorderRadiusDirectional`
القياسية في Flutter:

```dart
// ✅ صحيح — ينعكس تلقائياً بحسب اتجاه النص الحالي
16.paddingStart          // يمين الشاشة في RTL، يسارها في LTR
16.paddingHorizontal
paddingOnly(start: 8, end: 16)

// ❌ خطأ — لا ينعكس أبداً، يكسر التخطيط في RTL
EdgeInsets.only(left: 16)
```

**القاعدة**: `start` = يمين الشاشة في RTL / يسارها في LTR. `end` = العكس.
أي `Padding`/`Align`/`BorderRadius` جديد في أي شاشة **يجب** أن يستخدم صيغة
`*Directional` أو الامتدادات أعلاه، لا القيم المطلقة `left`/`right` مطلقاً.

## 2. انعكاس الأيقونات — فقط الاتجاهية منها

`lib/ui/rtl/icon_flip_rules.dart` يفرّق صراحة بين نوعين من الأيقونات:

- **أيقونات اتجاهية (تنعكس في RTL)**: كل أسهم التنقّل (`arrow_forward`,
  `chevron_right`, `navigate_next`...) وأيقونات الدخول/الخروج/الإرسال
  (`login`, `logout`, `send`, `reply`...) — القائمة الكاملة في
  `AvahiIconFlipRules.directionalIcons`.
- **أيقونات ثابتة (لا تنعكس أبداً)**: ⚙️ الإعدادات، 🔔 الإشعارات، 📷 الكاميرا،
  وأي أيقونة لا تحمل دلالة اتجاه بصري — انعكاسها فعلياً **خطأ بصري**، ليس
  تحسيناً.

استخدم `AvahiIconFlipRules.shouldFlip(icon)` أو الودجة الجاهزة الملفوفة
حولها بدل قرار يدوي متكرر في كل شاشة تستخدم أيقونة سهم.

## 3. الأرقام تبقى دوماً LTR حتى داخل جملة عربية

`lib/ui/rtl/number_direction.dart` يلفّ أي نص رقمي (هاتف، معرّف، رقم إحصائي)
بعلامات Unicode للتضمين الاتجاهي الصريح (`LRE`/`PDF`) لضمان بقاء ترتيب
الأرقام صحيحاً بصرياً بصرف النظر عن اتجاه الجملة المحيطة:

```dart
Text(AvahiNumberDirection.forceLtr('+964 750 123 4567'))
Text(AvahiNumberDirection.forceLtrNumber(1234.56))
```

**متى تستخدمه إلزامياً**: أرقام هواتف، مُعرّفات (IDs)، أرقام تسلسلية،
إحداثيات GPS، أي رقم يُعرَض داخل نص عربي محيط به فواصل/أقواس/رموز أخرى.
**غير ضروري** لأرقام معزولة تماماً في حقل خاص بها (مثال: عداد كبير في
بطاقة إحصائية بلا نص محيط).

## 4. `DirectionalityProvider`

`lib/ui/rtl/directionality_provider.dart` هو مصدر الحقيقة الوحيد لاتجاه
التطبيق الحالي، مرتبط بـ `LocaleProvider` (`ui/modes/locale_provider.dart`)
— تبديل اللغة عربي↔إنجليزي يُبدّل الاتجاه تلقائياً عبر شجرة الودجات كاملة
دون أي إعادة تشغيل للتطبيق.

## 5. الأصداف (Shells) والاتجاه

الشريط الجانبي في `desktop_shell.dart` والقائمة المنزلقة في
`mobile_drawer.dart` يعتمدان حصراً على `Directionality`/الخصائص المنطقية
القياسية في Flutter — يظهران تلقائياً في الجهة الصحيحة (يمين الشاشة
افتراضياً بالعربية) بلا أي شرط يدوي. انظر
[docs/architecture/05_responsive_web.md](../architecture/05_responsive_web.md#اتجاه-rtl-عبر-كل-الأصداف).

## 6. قائمة تحقق سريعة لأي شاشة جديدة

- [ ] لا استخدام مباشر لـ `EdgeInsets.only(left:/right:)` — استخدم
      `EdgeInsetsDirectional`/الامتدادات.
- [ ] لا `Alignment.centerLeft`/`centerRight` مباشرة — استخدم
      `AlignmentDirectional.centerStart`/`centerEnd`.
- [ ] كل سهم/أيقونة تنقّل تمر عبر `AvahiIconFlipRules`.
- [ ] كل رقم هاتف/معرّف/إحداثية داخل نص عربي ملفوف بـ
      `AvahiNumberDirection.forceLtr`.
- [ ] اختبار الشاشة بصرياً في وضع RTL **أولاً** (الوضع الافتراضي)، ثم LTR
      كتحقق ثانوي — انظر `test/golden/rtl/` لأمثلة لقطات مرجعية.
