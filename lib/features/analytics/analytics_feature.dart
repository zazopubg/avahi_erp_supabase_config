/// ملف تجميعي (Barrel File) لميزة `features/analytics/` كاملة 🆕
/// (Prompt 25) — يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى
/// باستيراد كل شاشات وودجات وحالة هذه الميزة عبر سطر واحد، بنفس نمط
/// `features/equipment/equipment_feature.dart`/
/// `features/leave_requests/leave_requests_feature.dart` تماماً.
///
/// ⚠️ ملاحظة نطاق: هذه الميزة تصدّر شاشة واحدة فقط يستهلكها
/// `app_router.dart` مباشرة كنقطة `go_router` وحيدة — [AnalyticsDashboard]
/// (`/analytics`، بلا أي مسار فرعي إضافي — انظر توثيق القرار الكامل
/// في `analytics_dashboard.dart` حول اعتماد ألسنة داخلية بدل مسارات
/// منفصلة لكل من [ProjectAnalytics]/[AttendanceAnalytics]/
/// [ExportAnalyticsScreen]). الثلاثة الأخيرة داخلية بالكامل (تُستهلَك
/// حصراً من [AnalyticsDashboard] نفسها) لكنها مُصدَّرة أيضاً لتسهيل
/// اختبارها بمعزل لاحقاً في `test/` (Prompt 29)، بنفس منطق
/// `EquipmentRegistry`/`MaintenanceSchedule` في `equipment_feature.dart`.
library;

export 'presentation/screens/desktop/analytics_dashboard.dart';
export 'presentation/screens/desktop/attendance_analytics.dart';
export 'presentation/screens/desktop/export_analytics_screen.dart';
export 'presentation/screens/desktop/project_analytics.dart';
export 'presentation/state/analytics_cubit.dart';
export 'presentation/state/analytics_state.dart';
export 'presentation/widgets/attendance_trend_chart.dart';
export 'presentation/widgets/date_range_filter.dart';
export 'presentation/widgets/kpi_summary_row.dart';
export 'presentation/widgets/project_progress_chart.dart';
export 'presentation/widgets/task_distribution_chart.dart';
