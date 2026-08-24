# مقياس النص (Text Scaling)

Avahi يدعم تكبير حجم النص من مصدرين مختلفين معاً، مركّبين بأمان فوق بعضهما
عبر `TextScaleGuard` (`lib/ui/theme/text_scale_guard.dart`).

## المصدران

1. **عامل نظام التشغيل/المتصفح** (`MediaQuery.textScaler`): القيمة التي
   يضبطها المستخدم في إعدادات إمكانية الوصول لنظامه (Chrome/Windows/macOS).
2. **عامل داخلي بتحكم المستخدم** (`TextScaleCubit`،
   `lib/ui/modes/text_scale_provider.dart`، 🆕 Prompt 27): مضاعِف إضافي
   يتحكم به المستخدم يدوياً من داخل التطبيق نفسه (`display_settings.dart`
   ضمن `features/settings/`)، بأزرار `+`/`-` بخطوة `0.05`، مستقل تماماً عن
   إعدادات نظام التشغيل — مفيد خصوصاً للعامل الميداني الذي قد لا يعرف كيف
   يضبط إعدادات نظام تشغيله لكنه يحتاج نصاً أكبر تحت أشعة الشمس المباشرة.

## آلية التركيب (لماذا الترتيب مهم)

```dart
final double systemFactor = mediaQuery.textScaler
    .clamp(minScaleFactor: minScale, maxScaleFactor: maxScale)
    .scale(1.0);
final TextScaler clampedScaler =
    TextScaler.linear(systemFactor * userScale)
        .clamp(minScaleFactor: minScale, maxScaleFactor: maxScale);
```

عامل النظام يُحصَر أولاً ضمن الحدود الآمنة، **ثم** يُضرَب بعامل المستخدم
الداخلي، **ثم** يُحصَر الناتج النهائي مرة أخرى ضمن نفس الحدود — بحيث يبقى
التخطيط سليماً دوماً بصرف النظر عن أي تركيبة من القيمتين (مثال: نظام على
أقصى تكبير + المستخدم يضغط `+` عدة مرات أيضاً لا يكسر الشاشة).

## الحدود الآمنة

| الحد | القيمة |
|---|---|
| `minScale` | `0.85` |
| `maxScale` | `1.4` |
| القيمة الافتراضية لعامل المستخدم | `1.0` (بلا أي تأثير إضافي) |
| خطوة زر `+`/`-` | `0.05` |

هذه الحدود مطبَّقة عبر `TextScaleGuard` على مستوى `MaterialApp.builder`،
أي أنها تُطبَّق **مرة واحدة على مستوى التطبيق بأكمله**، لا داخل كل شاشة —
لا حاجة لأي شاشة فردية للتعامل مع منطق الحصر بنفسها.

## قواعد إلزامية عند بناء أي شاشة

- **لا تستخدم أحجام خط ثابتة بالبكسل داخل `Container` بأبعاد ثابتة أيضاً**
  — إن كبر النص عن حدوده، يجب أن يلتف (Wrap) أو يتمدد الحاوي معه، لا أن
  يُقطَع (Overflow/Clip) بصمت.
- استخدم أنماط `AvahiTypography` (`lib/ui/theme/avahi_typography.dart`)
  الجاهزة بدل `TextStyle(fontSize: ...)` مباشرة — هذه الأنماط مبنية لتتجاوب
  بشكل متسق مع `TextScaler` تلقائياً.
- اختبر كل شاشة جديدة بصرياً عند `maxScale` (1.4) على الأقل مرة واحدة —
  خصوصاً الأزرار الكبيرة (`BigCheckInButton`) والبطاقات المضغوطة
  (`worker_row.dart`, `leave_request_card.dart`) الأكثر عرضة لكسر التخطيط
  عند تكبير النص.
- تجنّب `maxLines` صارم بلا `overflow: TextOverflow.ellipsis` مصاحب —
  نص مقطوع بصمت بلا مؤشر بصري (...) يُفقِد المستخدم معلومات دون علمه.

## الاختبار الآلي

`test/golden/text_scaling/` يحتوي لقطات Golden Test لعدة شاشات رئيسية عند
`minScale`/`1.0`/`maxScale` للتأكد من عدم كسر أي تخطيط عند تعديلات مستقبلية
— شغّلها عبر `flutter test --update-goldens` عند تغيير مقصود في التصميم،
أو `flutter test` عادي للتحقق من عدم وجود انحراف غير مقصود.
