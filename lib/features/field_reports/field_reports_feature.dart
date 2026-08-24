/// ملف تجميعي (Barrel File) لميزة `features/field_reports/` كاملة —
/// يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى باستيراد كل
/// شاشات وحالة هذه الميزة عبر سطر واحد:
/// `import 'package:avahi/features/field_reports/field_reports_feature.dart';`
///
/// بنفس نمط `features/attendance/attendance_feature.dart` تماماً.
///
/// ⚠️ ملاحظة نطاق: تصدّر شاشة دخول واحدة فقط ([FieldReportsScreen])
/// يستهلكها `app_router.dart` مباشرة — كل الشاشات الفرعية (`mobile/*`،
/// `desktop/*`) داخلية بالكامل للميزة، يُنقَل إليها محلياً
/// (`Navigator.push`/تبويبات) وليس عبر `go_router`، بنفس فلسفة
/// `AttendanceScreen`. تصدّر **`Cubit`ين** منفصلين (`ReportFormCubit`/
/// `ReportsInboxCubit`) بخلاف بقية الميزات ذات الـ`Cubit` الواحد —
/// انظر توثيق القرار الكامل في `core/di/features_module.dart`
/// (تعليق `_registerFieldReportsFeature`).
library;

export 'core/services/weather_api_service.dart';
export 'presentation/screens/field_reports_screen.dart';
export 'presentation/state/report_form_cubit.dart';
export 'presentation/state/report_form_state.dart';
export 'presentation/state/reports_inbox_cubit.dart';
export 'presentation/state/reports_inbox_state.dart';
