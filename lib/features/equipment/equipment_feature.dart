/// ملف تجميعي (Barrel File) لميزة `features/equipment/` كاملة 🆕
/// (Prompt 22) — يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى
/// باستيراد كل شاشات وحالة هذه الميزة عبر سطر واحد، بنفس نمط
/// `features/documents/documents_feature.dart`/
/// `features/punch_list/punch_list_feature.dart` تماماً.
///
/// ⚠️ ملاحظة نطاق: هذه الميزة تصدّر شاشتين يستهلكهما `app_router.dart`
/// مباشرة كنقطتَي `go_router` — [MyEquipmentScreen] (`/equipment`،
/// تُفوِّض داخلياً لـ [EquipmentRegistry] على سطح المكتب دون مسار
/// منفصل لها، بنفس منطق `PunchListScreen`/`PunchDashboard`) و
/// [LogUsageScreen] (`/equipment/log-usage`، عبر [LogUsageRouteArgs]
/// الممرَّرة كـ `extra:` — بنفس منطق `PunchItemDetailsRouteArgs`).
/// [EquipmentRegistry]/[EquipmentDetailsPanel]/[MaintenanceSchedule]
/// داخلية بالكامل (يستهلكها [MyEquipmentScreen] نفسها حسب `ShellMode`)
/// لكنها مُصدَّرة أيضاً لتسهيل اختبارها بمعزل لاحقاً في `test/`
/// (Prompt 29).
library;

export 'presentation/screens/desktop/equipment_details.dart';
export 'presentation/screens/desktop/equipment_registry.dart';
export 'presentation/screens/desktop/maintenance_schedule.dart';
export 'presentation/screens/mobile/log_usage_screen.dart';
export 'presentation/screens/mobile/my_equipment_screen.dart';
export 'presentation/state/equipment_cubit.dart';
export 'presentation/state/equipment_state.dart';
export 'presentation/widgets/assign_equipment_dialog.dart';
export 'presentation/widgets/equipment_card.dart';
export 'presentation/widgets/equipment_status_badge.dart';
export 'presentation/widgets/usage_hours_chart.dart';
