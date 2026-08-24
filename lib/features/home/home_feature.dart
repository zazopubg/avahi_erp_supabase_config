/// ملف تجميعي (Barrel File) لميزة `features/home/` كاملة — يسمح
/// لـ `navigation/app_router.dart` وأي طبقة أخرى باستيراد كل شاشات
/// وحالة هذه الميزة عبر سطر واحد:
/// `import 'package:avahi/features/home/home_feature.dart';`
///
/// بنفس نمط `features/auth/auth_feature.dart` (Prompt 13) تماماً.
library;

export 'presentation/screens/home_screen.dart';
export 'presentation/screens/manager_home.dart';
export 'presentation/screens/supervisor_home.dart';
export 'presentation/screens/worker_home.dart';
export 'presentation/state/home_cubit.dart';
export 'presentation/state/home_state.dart';
export 'presentation/widgets/alerts_section.dart';
export 'presentation/widgets/quick_actions.dart';
export 'presentation/widgets/today_summary.dart';
