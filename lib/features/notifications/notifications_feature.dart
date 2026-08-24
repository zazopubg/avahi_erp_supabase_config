/// ملف تجميعي (Barrel File) لميزة `features/notifications/` كاملة 🆕
/// (Prompt 23) — يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى
/// باستيراد كل شاشات وحالة هذه الميزة عبر سطر واحد، بنفس نمط
/// `features/equipment/equipment_feature.dart`/
/// `features/documents/documents_feature.dart` تماماً.
///
/// ⚠️ ملاحظة نطاق: هذه الميزة تصدّر شاشة واحدة يستهلكها
/// `app_router.dart` مباشرة كنقطة `go_router` — [NotificationsScreen]
/// (`/notifications`، شاشة موحَّدة لكل المنصات، انظر توثيق القرار
/// الكامل فيها). `navigation/shells/desktop/notification_panel.dart`
/// (اللوحة المنسدلة على سطح المكتب) تستهلك [NotificationsCubit]/
/// [NotificationTile]/[UnreadBadge] مباشرة من هذه الميزة أيضاً، لكنها
/// تبقى ملفاً ضمن `navigation/` (وليس `features/notifications/`) لأنها
/// جزء من قالب `DesktopShell` نفسه (`topbar.dart`) لا من الميزة —
/// بنفس منطق بقاء `notification_panel.dart` هناك أصلاً منذ Prompt 12.
library;

export 'presentation/screens/notifications_screen.dart';
export 'presentation/state/notifications_cubit.dart';
export 'presentation/state/notifications_state.dart';
export 'presentation/widgets/notification_tile.dart';
export 'presentation/widgets/notification_type_icon.dart';
export 'presentation/widgets/unread_badge.dart';
