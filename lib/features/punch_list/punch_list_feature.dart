/// ملف تجميعي (Barrel File) لميزة `features/punch_list/` كاملة —
/// يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى باستيراد كل
/// شاشات وحالة هذه الميزة عبر سطر واحد، بنفس نمط
/// `features/photos/photos_feature.dart`/`features/tasks/tasks_feature.dart`
/// تماماً.
///
/// ⚠️ ملاحظة نطاق: هذه الميزة تصدّر **ثلاث** شاشات يستهلكها
/// `app_router.dart` مباشرة كنقاط `go_router` منفصلة —
/// [PunchListScreen] (`/punch-list`، تُفوِّض داخلياً لـ [PunchDashboard]
/// على سطح المكتب دون مسار منفصل لها)، [PunchItemCreateScreen]
/// (`/punch-list/create`)، و[PunchItemDetailsScreen] (`/punch-list/details`،
/// عبر [PunchItemDetailsRouteArgs] الممرَّرة كـ `extra:`) — بنفس منطق
/// تصدير `features/photos/` الثلاثي الخاص بها؛ انظر توثيق القرار
/// الكامل في `PunchItemCreateScreen`/`PunchItemDetailsRouteArgs`
/// و`RoutePaths.punchListCreate`/`punchListDetails` (`navigation/route_paths.dart`).
/// [PunchDashboard]/[PunchItemManage] داخليتان بالكامل (يستهلكهما
/// [PunchListScreen] نفسها حسب `ShellMode`) لكنهما مُصدَّرتان أيضاً
/// لتسهيل اختبارهما بمعزل لاحقاً في `test/` (Prompt 29).
library;

export 'presentation/screens/desktop/punch_dashboard.dart';
export 'presentation/screens/desktop/punch_item_manage.dart';
export 'presentation/screens/mobile/punch_item_create.dart';
export 'presentation/screens/mobile/punch_item_details.dart';
export 'presentation/screens/mobile/punch_list_screen.dart';
export 'presentation/state/punch_cubit.dart';
export 'presentation/state/punch_state.dart';
export 'presentation/widgets/punch_close_form.dart';
export 'presentation/widgets/punch_item_card.dart';
export 'presentation/widgets/punch_status_filter.dart';
