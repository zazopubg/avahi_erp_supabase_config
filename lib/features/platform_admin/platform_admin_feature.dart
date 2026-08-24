/// ملف تجميعي (Barrel File) لميزة `features/platform_admin/` كاملة 🆕
/// (Prompt 28) — يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى
/// باستيراد كل شاشات وودجات وحالة هذه الميزة عبر سطر واحد، بنفس نمط
/// `features/users/users_feature.dart`/`features/analytics/analytics_feature.dart`
/// تماماً.
///
/// ⚠️ ملاحظة نطاق: هذه الميزة تصدّر شاشة واحدة فقط يستهلكها
/// `app_router.dart` مباشرة كنقطة `go_router` وحيدة —
/// [PlatformAdminDashboard] (`/platform-admin`، بلا أي مسار فرعي
/// إضافي — بنفس منطق `AnalyticsDashboard`/`UsersListScreen`). الشاشات
/// الثلاث الأخرى داخل `tenants/` (`TenantDetailsScreen`/
/// `TenantCreateScreen`/`TenantDataExportScreen`) داخلية بالكامل
/// (تُفتح حصراً عبر `Navigator.push` من `TenantsListScreen`) لكنها
/// مُصدَّرة أيضاً لتسهيل اختبارها بمعزل لاحقاً في `test/` (Prompt 29)،
/// بنفس منطق `InviteUserDialog` في `users_feature.dart`.
library;

export 'presentation/screens/admin_dashboard.dart';
export 'presentation/screens/audit/audit_logs_viewer.dart';
export 'presentation/screens/monitoring/error_logs.dart';
export 'presentation/screens/monitoring/usage_monitor.dart';
export 'presentation/screens/subscriptions/billing_overview.dart';
export 'presentation/screens/subscriptions/plans_management.dart';
export 'presentation/screens/tenants/tenant_create.dart';
export 'presentation/screens/tenants/tenant_data_export.dart';
export 'presentation/screens/tenants/tenant_details.dart';
export 'presentation/screens/tenants/tenants_list.dart';
export 'presentation/state/platform_admin_cubit.dart';
export 'presentation/state/platform_admin_state.dart';
export 'presentation/widgets/platform_kpi_card.dart';
export 'presentation/widgets/platform_usage_trend_chart.dart';
export 'presentation/widgets/section_card.dart';
