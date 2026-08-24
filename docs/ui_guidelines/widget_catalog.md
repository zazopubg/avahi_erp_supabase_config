# كتالوج الودجات المشتركة (Widget Catalog)

كل الودجات في `lib/ui/widgets/common/` هي **مكوّنات عرض بحتة (Pure
Presentational Components)** — لا تحمل أي منطق أعمال، استدعاء API، أو
اتصال مباشر بـ Cubit؛ تستقبل كل بياناتها عبر باراميترات، وتُستدعى من طبقة
`presentation/` في كل ميزة. الهدف: اتساق بصري كامل عبر الميزات الـ 17 دون
إعادة بناء نفس العنصر بأسلوب مختلف في كل ميزة.

## `AvahiButton`

`avahi_button.dart` — الزر الموحّد الوحيد في التطبيق.

- **الأنماط (`AvahiButtonVariant`)**: `primary` (مملوء)، `secondary`
  (حدود فقط)، `text` (بلا خلفية/حدود)، `danger` (دلالي للحذف/الإلغاء
  النهائي).
- **الأحجام**: `small` / `medium` / `large`.
- يستجيب تلقائياً لـ [وضع القفازات](./glove_mode.md) عبر
  `context.watch<GloveModeCubit>()` — أي استخدام له في أي ميزة يكبر تلقائياً
  دون تعديل موقع الاستدعاء.
- يدعم حالة `isLoading` (يعطّل الضغط ويعرض مؤشر تحميل داخلي).

## `AvahiTextField`

`avahi_text_field.dart` — غلاف موحّد فوق `TextFormField`، يطبّق
`InputDecorationTheme` من الثيم تلقائياً. يدعم أيقونات بداية/نهاية، نص
مساعدة، نص خطأ، و`validator` اختياري يُمرَّر من المستدعي (لا منطق تحقق
مضمَّن داخل الودجة نفسها).

## `AvahiDropdown<T>`

`avahi_dropdown.dart` — قائمة منسدلة عامة (Generic) بنفس الأسلوب البصري
لـ `AvahiTextField`، تُبنى من قائمة `AvahiDropdownItem<T>` (قيمة + تسمية +
أيقونة اختيارية).

## `AvahiDialog`

`avahi_dialog.dart` — حوار موحّد: عنوان، محتوى/رسالة، أزرار تأكيد/إلغاء
بنمط `AvahiButton`. يُستدعى عادة عبر `AvahiDialog.show(context, ...)` بدل
بناء `showDialog` يدوياً في كل شاشة.

## `Avatar`

`avatar.dart` — صورة رمزية بأربعة أحجام (`AvatarSize`: `small`/`medium`/
`large`/`xlarge`)؛ تعرض صورة شبكية عند توفر `imageUrl`، أو الأحرف الأولى
من `name` كبديل، مع نقطة حالة اتصال اختيارية (`showStatusDot`/`isOnline`).

## `StatusBadge`

`status_badge.dart` — شارة حالة نصية صغيرة، مبنية مباشرة فوق نظام الألوان
الدلالي (`AvahiStatus`: `success`/`danger`/`warning`/`info`) الموصوف في
[color_system.md](./color_system.md). هذه هي الودجة القياسية لعرض حالة أي
كيان (مهمة، تقرير، طلب إجازة) — لا تُعاد كتابة شارة حالة مخصصة داخل أي
ميزة فردية.

## `SyncIndicator`

`sync_indicator.dart` — مؤشر مزامنة صغير (أيقونة + نص اختياري) بأربع حالات
(`SyncState`): `synced` 🟢 / `syncing` 🟡 / `pending` ⚪ / `failed` 🔴. يستقبل
الحالة من طبقة أعلى (عادة مشتقة من `OutboxQueue.watchPendingCount()`؛ انظر
[docs/architecture/03_sync_strategy.md](../architecture/03_sync_strategy.md)) —
لا يحمل أي منطق مزامنة فعلي بنفسه.

## `OfflineBanner`

`offline_banner.dart` — شريط تنبيه ثابت أعلى الشاشة يظهر عند فقدان الاتصال.
يستقبل `isOffline` من طبقة أعلى (مرتبطة بـ `ConnectivityHelper`، انظر
[docs/architecture/06_offline_first.md](../architecture/06_offline_first.md)).
يُستخدَم عادة كأول عنصر في عمود `Scaffold.body`.

## `EmptyState`

`empty_state.dart` — عرض حالة "لا توجد بيانات بعد" الموحّد: أيقونة/رسمة،
عنوان، وصف اختياري، وزر إجراء اختياري بنمط `AvahiButton` (مثال: "إضافة مهمة
جديدة"). يُستخدَم في كل قائمة/شبكة فارغة عبر التطبيق بدل نص عادي بسيط.

## `ErrorView`

`error_view.dart` — عرض حالة خطأ موحّد: أيقونة تحذيرية، عنوان، وصف الخطأ،
وزر "إعادة المحاولة" اختياري. هذه هي الودجة القياسية لعرض حالة `<Feature>
Error(failure)` من أي Cubit (انظر نمط الحالة في
[docs/architecture/01_overview.md](../architecture/01_overview.md#إدارة-الحالة-عبر-cubit)).

## `LoadingIndicator`

`loading_indicator.dart` — مؤشر تحميل دائري بثلاثة أحجام (`small`/
`medium`/`large`) مع نص وصفي اختياري تحته. الودجة القياسية لعرض حالة
`<Feature>Loading`.

## قاعدة الاستخدام العامة

عند بناء أي شاشة جديدة تستهلك حالة Cubit بنمط `when<T>(loading:...,
loaded:..., error:...)`، الخريطة القياسية هي:

```dart
state.when(
  loading: () => const LoadingIndicator(),
  loaded: (data) => data.items.isEmpty
      ? const EmptyState(title: '...')
      : /* المحتوى الفعلي */,
  error: (failure) => ErrorView(
    title: '...',
    message: failure.message,
    onRetry: () => context.read<FeatureCubit>().refresh(),
  ),
)
```

لا تُبنى شاشة `Loading`/`Empty`/`Error` مخصصة داخل أي ميزة فردية — الثلاثة
دوماً عبر هذه الودجات المشتركة الثلاث لضمان اتساق تجربة المستخدم بأكملها.
