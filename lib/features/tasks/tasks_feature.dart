/// نقطة تصدير مجمّعة لميزة `features/tasks/` (Prompt 16) — بنفس نمط
/// `attendance_feature.dart` (Prompt 15): يستورد منها `app_router.dart`
/// وأي مكان آخر يحتاج نقاط الدخول العامة للميزة دون معرفة تفاصيل بنيتها
/// الداخلية (`presentation/state/`, `presentation/widgets/` ...).
library;

export 'presentation/screens/desktop/tasks_board_screen.dart';
export 'presentation/screens/tasks_screen.dart';
export 'presentation/state/tasks_cubit.dart';
export 'presentation/state/tasks_state.dart';
