/// ثوابت عامة متعلقة بالاتصال بواجهات API الخارجية (Supabase وغيرها).
///
/// ⚠️ لا يحتوي هذا الملف على أي عناوين أو مفاتيح فعلية — تلك تُقرأ حصراً
/// من `core/config/env.dart`. هذا الملف يحصر فقط القيم البنيوية الثابتة
/// (أسماء الجداول، مسارات Storage Buckets، أسماء دوال Edge Functions)
/// التي سيُعتمد عليها بدءاً من Prompt 03/04/07.
///
/// ⚠️ [Prompt 07] ترقيع: القيم أدناه كانت (منذ Prompt 02) أسماء
/// اجتهادية مؤقتة سبقت تصميم المخطط الفعلي. بعد اكتمال الهجرات في
/// `backend/supabase/migrations/` (Prompt 03/04) استُبدلت هنا **بأسماء
/// الجداول/الدوال الحقيقية والمطابقة تماماً** لضمان اعتماد طبقة
/// `data/` (هذه الخطوة) عليها دون أي انحراف عن قاعدة البيانات الفعلية.
abstract final class ApiConstants {
  // ── أسماء جداول قاعدة البيانات (Supabase/Postgres) ─────────────
  // مطابقة حرفياً لأسماء الجداول في backend/supabase/migrations/.
  static const String tableCompanies = 'companies';
  static const String tablePlatformAdmins = 'platform_admins';
  static const String tableCompanyMembers = 'company_members';
  static const String tableProjects = 'projects';
  static const String tableProjectMembers = 'project_members';
  static const String tableProjectMilestones = 'project_milestones';
  static const String tableTasks = 'tasks';
  static const String tableAttendance = 'attendance';
  static const String tableFieldReports = 'field_reports';
  static const String tablePunchItems = 'punch_items';
  static const String tablePhotos = 'photos';
  static const String tableDocuments = 'documents';
  static const String tableAuditLogs = 'audit_logs';
  static const String tableEquipment = 'equipment';
  static const String tableNotifications = 'notifications';
  static const String tableLeaveRequests = 'leave_requests';

  // ── مخازن الملفات (Storage Buckets) ─────────────────────────────
  static const String bucketPhotos = 'photos';
  static const String bucketDocuments = 'documents';
  static const String bucketSignatures = 'signatures';
  static const String bucketAvatars = 'avatars';

  /// 🆕 (Prompt 28) — أرشيفات تصدير بيانات المستأجر (JSON) الناتجة
  /// عن Edge Function `export-tenant-data`. مخزن **خاص** (Private)
  /// بنفس منطق [bucketDocuments] — الوصول حصراً عبر رابط موقّع مؤقت
  /// (`createSignedUrl`)، وليس رابطاً عاماً دائماً؛ انظر توثيق القرار
  /// الكامل في `PlatformAdminRepositoryImpl.exportTenantData`.
  static const String bucketTenantExports = 'tenant-exports';

  // ── أسماء دوال Edge Functions ────────────────────────────────────
  // مطابقة حرفياً لأسماء المجلدات في backend/supabase/functions/.
  // ⚠️ report-notifications / leave-request-notify / equipment-alert /
  // sync-user-claims تعمل عبر Database Webhooks أو جدولة (pg_cron) من
  // جانب الخادم فقط، ولا تُستدعى مباشرة من عميل Flutter؛ التي
  // يستدعيها العميل مباشرة هنا هي [fnAttendanceGuard] و🆕 (Prompt 26)
  // [fnInviteUser] (تتطلّب JWT مستخدم مصادَق عليه صالحاً، بخلاف
  // [fnSyncUserClaims] التي تتحقق فقط من سرّ مشترك غير متاح للعميل —
  // انظر توثيق القرار الكامل في `UpdateMemberRoleUsecase`).
  static const String fnAttendanceGuard = 'attendance-guard';
  static const String fnCreateCompany = 'create-company';
  static const String fnSoftDeleteTenant = 'soft-delete-tenant';
  static const String fnSyncUserClaims = 'sync-user-claims';
  static const String fnReportNotifications = 'report-notifications';
  static const String fnEquipmentAlert = 'equipment-alert';
  static const String fnLeaveRequestNotify = 'leave-request-notify';
  static const String fnInviteUser = 'invite-user';
  // 🆕 (Prompt 28) — [fnExportTenantData] يُستدعى مباشرة من
  // `PlatformAdminRepositoryImpl.exportTenantData` (JWT مستخدم
  // `platformOwner` مصادَق عليه، بنفس شرط [fnCreateCompany]/
  // [fnSoftDeleteTenant] أعلاه)؛ الأخيرتان كانتا معرَّفتين هنا منذ
  // Prompt 04/07 لكن بلا أي طبقة `data/`/`domain/` تستدعيهما فعلياً —
  // `PlatformAdminRepositoryImpl` (هذه الخطوة) أول مستهلك حقيقي لكل
  // الثلاث معاً.
  static const String fnExportTenantData = 'export-tenant-data';

  // ── إعدادات شبكة عامة ─────────────────────────────────────────────
  static const int defaultRetryCount = 3;
  static const Duration defaultRetryBackoff = Duration(seconds: 2);
  static const int maxPageSize = 100;
}
