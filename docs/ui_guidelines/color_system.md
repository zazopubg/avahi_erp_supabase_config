# نظام الألوان (Color System)

نظام ألوان **دلالي (Semantic)** بالكامل — كل لون يُستخدم للدلالة على معنى
ثابت في كل أنحاء التطبيق، لا لأغراض جمالية بحتة. مُعرَّف في
`lib/ui/theme/avahi_colors.dart` بنسختين كاملتين (`AvahiColors.light` /
`AvahiColors.dark`) تتبدلان تلقائياً عبر `DarkModeCubit`
(`ui/modes/dark_mode_provider.dart`).

## الدلالات الأربع الأساسية

| اللون | الدلالة | مثال استخدام |
|---|---|---|
| 🟢 `success` (أخضر) | مكتمل / متزامن (Synced / Completed / Approved) | شارة "متزامن"، حالة مهمة `done`، اعتماد حضور |
| 🔴 `danger` (أحمر) | متأخر / خطأ / مرفوض (Overdue / Error / Rejected) | تجاوز الموعد النهائي، فشل مزامنة، رفض طلب إجازة |
| 🟡 `warning` (أصفر) | جارٍ / قيد الانتظار (Pending / In Progress) | حضور بانتظار الاعتماد، مهمة `in_progress` |
| 🔵 `info` (أزرق) | معلوماتي (Informational) | إشعار عام، تلميح مساعدة |

كل دلالة تأتي بأربع درجات (`AvahiColors` كامل): اللون الأساسي (مثال:
`success`)، اللون فوقه (`onSuccess`، للنص/الأيقونات فوق خلفية ملوّنة)،
حاوية خفيفة (`successContainer`، لخلفيات البطاقات/الشارات)، ولون فوق تلك
الحاوية (`onSuccessContainer`).

## ألوان العلامة التجارية والسطح

| الفئة | الاستخدام |
|---|---|
| `brand` / `brandOnBrand` / `brandContainer` / `onBrandContainer` | لون Avahi الأساسي (أخضر مؤسسي `#0F6E4F`) — أزرار أساسية، شعار، تمييز تنقّل نشط |
| `background` / `surface` / `surfaceVariant` / `surfaceElevated` | خلفية الشاشة، خلفية البطاقات، تدرّجات سطح إضافية |
| `onBackground` / `onSurface` / `onSurfaceVariant` | نص فوق كل من الخلفيات أعلاه، بتباين متدرّج (أساسي/ثانوي) |
| `outline` / `outlineVariant` | حدود الحقول والفواصل |
| `disabled` / `onDisabled` | عناصر معطَّلة |
| `shadow` / `scrim` / `overlay` | ظلال، تعتيم خلف حوارات، تراكب شفاف خفيف |

## القاعدة الذهبية: لا ألوان حرّة (Hex) مباشرة في شاشات الميزات

```dart
// ❌ خطأ — لون حرّ، لا دلالة له، لا يتبدل مع الوضع الداكن
Container(color: Color(0xFF1E8E5A))

// ✅ صحيح — دلالي، يتبدل تلقائياً بين فاتح/داكن
Container(color: context.avahiColors.success)
```

كل لون مستخدَم في أي ودجة جديدة **يجب** أن يأتي من `AvahiColors` عبر
الثيم الحالي (`Theme.of(context).extension<AvahiColors>()` أو الامتداد
المختصر إن وُجد في `context_extensions.dart`) — لا قيمة `Color(0x...)`
حرّة مباشرة داخل `lib/features/`.

## الوضع الداكن

`AvahiColors.dark` نسخة كاملة موازية بنفس البنية تماماً (نفس أسماء
الحقول، قيم مختلفة) — أي ودجة تعتمد على الدلالة (`context.avahiColors.
danger` مثلاً) تعمل صحيحاً تلقائياً في كلا الوضعين دون أي شرط
`if (isDark)` يدوي. يُتحكَّم بالتبديل عبر `DarkModeCubit`
(`ui/modes/dark_mode_provider.dart`)، مُدار من `display_settings.dart`.

## نظام المسافات (`AvahiSpacing`) ونظام الاستدارة (`AvahiRadius`)

يُستخدَمان دوماً مع نظام الألوان لبناء أي ودجة، مبنيان على وحدة أساس 4px:

| `AvahiSpacing` | القيمة | `AvahiRadius` | القيمة |
|---|---|---|---|
| `none` | 0 | `none` | 0 |
| `xxs` | 4 | `xs` | 4 (شارات، أزرار مصغّرة) |
| `xs` | 8 | `sm` | 8 (حقول، أزرار قياسية) |
| `sm` | 12 | `md` | 12 (بطاقات، حوارات) |
| `md` | 16 (الأكثر استخداماً) | `lg` | 16 (بطاقات كبيرة، Bottom Sheets) |
| `lg` | 24 | `xl` | 24 (عناصر بارزة) |
| `xl` | 32 | `full` | 999 (استدارة كاملة/كبسولية) |
| `xxl` | 40 | | |
| `xxxl` | 48 | | |
| `huge` | 64 (فواصل أقسام كبيرة) | | |

استخدم `AvahiRadius.radiusMd` (وما شابه) الجاهزة كـ `BorderRadius` مباشرة
بدل `BorderRadius.circular(AvahiRadius.md)` المتكرر يدوياً.

## قائمة تحقق سريعة عند إضافة عنصر واجهة جديد

- [ ] لا `Color(0x...)` حرّ — كل لون عبر `AvahiColors` الدلالي.
- [ ] الدلالة تطابق المعنى الفعلي (لا تستخدم `danger` لعنصر ليس خطأ فعلياً).
- [ ] اختبار بصري في كلا الوضعين (فاتح/داكن).
- [ ] كل مسافة/استدارة عبر `AvahiSpacing`/`AvahiRadius`، لا أرقام حرّة.
