/// ملف تجميعي (Barrel File) لميزة `features/attendance/` كاملة —
/// يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى باستيراد كل
/// شاشات وحالة هذه الميزة عبر سطر واحد:
/// `import 'package:avahi/features/attendance/attendance_feature.dart';`
///
/// بنفس نمط `features/auth/auth_feature.dart` و
/// `features/home/home_feature.dart` تماماً.
///
/// ⚠️ ملاحظة نطاق: على عكس `home_feature.dart` (الذي يصدّر ثلاث شاشات
/// دور منفصلة يستهلكها `app_router.dart` مباشرة)، هذه الميزة تصدّر
/// شاشة دخول واحدة فقط ([AttendanceScreen]) — كل الشاشات الفرعية
/// (`mobile/*`, `desktop/*`) داخلية بالكامل للميزة، يُنقَل إليها محلياً
/// (`Navigator.push`/تبويبات) وليس عبر `go_router` — انظر توثيق هذا
/// القرار المعماري في `presentation/state/attendance_cubit.dart`.
library;

export 'presentation/screens/attendance_screen.dart';
export 'presentation/state/attendance_cubit.dart';
export 'presentation/state/attendance_state.dart';
