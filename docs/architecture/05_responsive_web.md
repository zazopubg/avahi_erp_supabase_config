# 05 — تكييف الواجهة عبر عرض الشاشة على الويب

Avahi قاعدة برمجية واحدة تخدم ثلاث تجارب مختلفة على متصفح واحد (Chrome)
بحسب عرض نافذة المتصفح فعلياً — لا تطبيقين منفصلين ولا "نسخة موبايل" و"نسخة
ويب" مستقلتين. التبديل بينها حي وفوري عند تغيير حجم النافذة (`ResizeObserver`
الداخلي في Flutter Web).

## نقاط التوقف (Breakpoints)

معرَّفة في `lib/core/platform/shell_mode.dart` كمصدر وحيد للحقيقة:

```dart
static const double mobileBreakpoint  = 600;   // < 600   → ShellMode.mobile
static const double desktopBreakpoint = 1024;  // >= 1024 → ShellMode.desktop
                                                // 600-1024 → ShellMode.tablet
```

| `ShellMode` | العرض | الشل المستخدَم | يحاكي تجربة |
|---|---|---|---|
| `mobile` | `< 600px` | `mobile/mobile_shell.dart` | هاتف — عمود واحد، تنقّل سفلي |
| `tablet` | `600px – 1024px` | `tablet/tablet_shell.dart` | جهاز لوحي — وسيط، بلا ازدحام شريط سفلي بأيقونات كثيرة، وبلا هدر مساحة شريط جانبي كامل لعرض متوسط |
| `desktop` | `>= 1024px` | `desktop/desktop_shell.dart` | سطح مكتب — شريط جانبي كامل + لوحة إشعارات + شريط علوي |

## `AdaptiveShell` — نقطة القرار المركزية

`lib/navigation/shells/adaptive_shell.dart` هو الودجة الجذر التي تُقرأ عرض
الشاشة (`MediaQuery.sizeOf(context).width`) وتُفوّض العرض فعلياً لأحد الأصداف
الثلاثة أعلاه عبر `ShellMode.fromWidth(width)` — كل شاشات التطبيق (بما فيها
كل الميزات الـ 17) تُعرَض **داخل** هذا الصدف عبر `go_router` `ShellRoute`،
فلا حاجة لأي ميزة فردية لإعادة تطبيق منطق كشف العرض بنفسها.

## أنماط تفرّع الشاشات داخل الميزات

لاحظ أن ليست كل الميزات تحتاج شاشات منفصلة تماماً لكل صدف:

- **تفرّع كامل (`screens/mobile/` + `screens/desktop/`)**: للميزات ذات
  تجربة عمل مختلفة جوهرياً بين السياقين — مثال `attendance` (الهاتف:
  `check_in_screen.dart`/`qr_scan_screen.dart` بأزرار كبيرة ومسح QR؛ سطح
  المكتب: `attendance_monitor.dart`/`attendance_table.dart` لعرض جدولي
  لكل الفريق) و`leave_requests` (الهاتف: تقديم طلب شخصي؛ سطح المكتب: صندوق
  وارد اعتماد إداري).
- **شاشة دخول واحدة بمنطق تكييف داخلي**: ميزات أبسط (`documents`,
  `photos`) تستخدم `LayoutBuilder`/`ShellMode` داخل الشاشة نفسها لتبديل
  التخطيط (عمود واحد ↔ شبكة/تخطيط جانبي) دون الحاجة لملفي شاشة منفصلين
  فعلياً.
- الاختيار بين النمطين قرار هندسي لكل ميزة على حدة، موثَّق دوماً في تعليق
  رأس ملف `<feature>_feature.dart` الخاص بها (انظر مثال `attendance_
  feature.dart`).

## عناصر الشل الثلاثة

| الشل | العناصر الرئيسية |
|---|---|
| **Mobile** (`mobile_shell.dart`) | `bottom_nav_bar.dart` (تنقّل رئيسي بأيقونات) + `mobile_drawer.dart` (قائمة جانبية منزلقة للخيارات الثانوية) |
| **Tablet** (`tablet_shell.dart`) | تخطيط وسيط — عادة شريط جانبي مصغّر (أيقونات بلا تسميات) بلا الحاجة لـ Drawer كامل |
| **Desktop** (`desktop_shell.dart`) | `sidebar.dart` (شريط جانبي كامل بتسميات، ثابت) + `topbar.dart` (بحث/بروفايل) + `notification_panel.dart` (لوحة جانبية منزلقة للإشعارات) |

## اتجاه RTL عبر كل الأصداف

كل الأصداف الثلاثة تحترم الاتجاه العام للتطبيق (العربية RTL افتراضياً) عبر
`lib/ui/rtl/` — الشريط الجانبي في `desktop_shell.dart` مثلاً يظهر تلقائياً
على يمين الشاشة (لا يسار) في وضع RTL دون أي شرط `if (isRtl)` يدوي متكرر،
بالاعتماد على `Directionality` القياسية في Flutter بدل إحداثيات مطلقة —
التفاصيل الكاملة في [docs/ui_guidelines/rtl_rules.md](../ui_guidelines/rtl_rules.md).

## حواجز التنقّل (Guards) لا علاقة لها بالعرض

`lib/navigation/guards/` (`auth_guard`, `role_guard`, `platform_guard`,
`subscription_guard`) تعمل بمعزل تام عن `ShellMode` — نفس منطق الحماية
(هل المستخدم مسجَّل دخوله؟ هل يملك الدور الكافي؟) يُطبَّق بصرف النظر عن كون
المستخدم يشاهد الصدف الهاتفي أو المكتبي؛ الفصل هنا متعمّد بين "من يمكنه
الوصول" (guards) و"كيف تُعرَض الشاشة" (shells).

## اختبار التكييف

`test/golden/` يحتوي لقطات Golden Test لعدة أحجام شاشة قياسية (حول نقاط
التوقف أعلاه) للتأكد من عدم كسر التخطيط عند أي تعديل مستقبلي — انظر أيضاً
[docs/ui_guidelines/text_scaling.md](../ui_guidelines/text_scaling.md) لتأثير
تكبير حجم الخط على نفس هذه التخطيطات.
