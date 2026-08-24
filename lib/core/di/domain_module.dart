import 'package:get_it/get_it.dart';

import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/attendance/check_in_usecase.dart';
import '../../domain/usecases/attendance/check_out_usecase.dart';
import '../../domain/usecases/attendance/get_my_attendance_history_usecase.dart';
import '../../domain/usecases/attendance/get_project_attendance_usecase.dart';
import '../../domain/usecases/attendance/get_today_attendance_usecase.dart';
import '../../domain/usecases/attendance/qr_check_in_usecase.dart';
import '../../domain/usecases/attendance/review_attendance_usecase.dart';
import '../../domain/usecases/attendance/watch_project_attendance_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/get_user_memberships_usecase.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/send_password_reset_email_usecase.dart';
import '../../domain/usecases/company/get_company_by_id_usecase.dart';
import '../../domain/usecases/documents/archive_document_usecase.dart';
import '../../domain/usecases/documents/get_document_by_id_usecase.dart';
import '../../domain/usecases/documents/get_documents_usecase.dart';
import '../../domain/usecases/documents/upload_document_usecase.dart';
import '../../domain/usecases/equipment/assign_equipment_usecase.dart';
import '../../domain/usecases/equipment/get_company_equipment_usecase.dart';
import '../../domain/usecases/equipment/get_equipment_by_id_usecase.dart';
import '../../domain/usecases/equipment/log_usage_hours_usecase.dart';
import '../../domain/usecases/equipment/update_equipment_status_usecase.dart';
import '../../domain/usecases/leave/get_leave_requests_usecase.dart';
import '../../domain/usecases/leave/request_leave_usecase.dart';
import '../../domain/usecases/leave/review_leave_usecase.dart';
import '../../domain/usecases/notifications/get_notifications_usecase.dart';
import '../../domain/usecases/notifications/mark_as_read_usecase.dart';
import '../../domain/usecases/platform_admin/create_tenant_usecase.dart';
import '../../domain/usecases/platform_admin/export_tenant_data_usecase.dart';
import '../../domain/usecases/platform_admin/get_all_audit_logs_usecase.dart';
import '../../domain/usecases/platform_admin/get_all_companies_usecase.dart';
import '../../domain/usecases/platform_admin/get_platform_usage_snapshot_usecase.dart';
import '../../domain/usecases/platform_admin/get_recent_error_logs_usecase.dart';
import '../../domain/usecases/platform_admin/get_subscription_plans_usecase.dart';
import '../../domain/usecases/platform_admin/get_tenant_stats_usecase.dart';
import '../../domain/usecases/platform_admin/get_tenant_subscriptions_usecase.dart';
import '../../domain/usecases/platform_admin/soft_delete_tenant_usecase.dart';
import '../../domain/usecases/platform_admin/update_tenant_plan_usecase.dart';
import '../../domain/usecases/projects/add_project_member_usecase.dart';
import '../../domain/usecases/projects/create_milestone_usecase.dart';
import '../../domain/usecases/projects/create_project_usecase.dart';
import '../../domain/usecases/projects/delete_milestone_usecase.dart';
import '../../domain/usecases/projects/get_available_company_members_usecase.dart';
import '../../domain/usecases/projects/get_my_projects_usecase.dart';
import '../../domain/usecases/projects/get_project_by_id_usecase.dart';
import '../../domain/usecases/projects/get_project_dashboard_usecase.dart';
import '../../domain/usecases/projects/get_project_members_usecase.dart';
import '../../domain/usecases/projects/get_project_milestones_usecase.dart';
import '../../domain/usecases/projects/remove_project_member_usecase.dart';
import '../../domain/usecases/projects/update_milestone_usecase.dart';
import '../../domain/usecases/projects/update_project_usecase.dart';
import '../../domain/usecases/punch/close_punch_item_usecase.dart';
import '../../domain/usecases/punch/create_punch_item_usecase.dart';
import '../../domain/usecases/punch/get_project_punch_items_usecase.dart';
import '../../domain/usecases/reports/get_project_reports_usecase.dart';
import '../../domain/usecases/reports/get_report_by_id_usecase.dart';
import '../../domain/usecases/reports/review_report_usecase.dart';
import '../../domain/usecases/reports/save_draft_report_usecase.dart';
import '../../domain/usecases/reports/sign_report_usecase.dart';
import '../../domain/usecases/reports/submit_report_usecase.dart';
import '../../domain/usecases/reports/watch_project_reports_usecase.dart';
import '../../domain/usecases/tasks/assign_task_usecase.dart';
import '../../domain/usecases/tasks/get_my_tasks_usecase.dart';
import '../../domain/usecases/tasks/get_project_tasks_usecase.dart';
import '../../domain/usecases/tasks/update_task_status_usecase.dart';
import '../../domain/usecases/users/get_company_members_usecase.dart';
import '../../domain/usecases/users/invite_user_usecase.dart';
import '../../domain/usecases/users/update_member_role_usecase.dart';
import '../../domain/usecases/users/update_member_status_usecase.dart';

/// يسجّل كل `UseCases` طبقة `domain/` (Prompt 06) — [Factory] لكل شيء
/// هنا عمداً (`registerFactory`، وليس Singleton): كل `UseCase` كائن
/// بلا حالة (Stateless، `const` عند الإمكان أصلاً في تعريفاته) رخيص
/// الإنشاء يستقبل المستودع (`Singleton` أصلاً من `data_module.dart`)
/// عبر الحقن — إنشاء نسخة جديدة عند كل طلب أنظف من مشاركة نسخة واحدة
/// دون أي فائدة أداء فعلية، ويطابق تماماً كيف تستهلكها `Cubit`s طبقة
/// العرض لاحقاً (نسخة واحدة لكل `Cubit`، وليست مشتركة عبر التطبيق).
void registerDomainModule(GetIt sl) {
  // ── Attendance ───────────────────────────────────────────────────
  sl.registerFactory<CheckInUsecase>(
    () => CheckInUsecase(sl<IAttendanceRepository>()),
  );
  sl.registerFactory<CheckOutUsecase>(
    () => CheckOutUsecase(sl<IAttendanceRepository>()),
  );
  sl.registerFactory<GetTodayAttendanceUsecase>(
    () => GetTodayAttendanceUsecase(sl<IAttendanceRepository>()),
  );
  sl.registerFactory<QrCheckInUsecase>(
    () => QrCheckInUsecase(sl<IAttendanceRepository>()),
  );
  sl.registerFactory<ReviewAttendanceUsecase>(
    () => ReviewAttendanceUsecase(sl<IAttendanceRepository>()),
  );
  sl.registerFactory<GetMyAttendanceHistoryUsecase>(
    () => GetMyAttendanceHistoryUsecase(sl<IAttendanceRepository>()),
  );
  sl.registerFactory<GetProjectAttendanceUsecase>(
    () => GetProjectAttendanceUsecase(sl<IAttendanceRepository>()),
  );
  sl.registerFactory<WatchProjectAttendanceUsecase>(
    () => WatchProjectAttendanceUsecase(sl<IAttendanceRepository>()),
  );

  // ── Auth ────────────────────────────────────────────────────────
  sl.registerFactory<GetCurrentUserUsecase>(
    () => GetCurrentUserUsecase(sl<IAuthRepository>()),
  );
  sl.registerFactory<LoginUsecase>(() => LoginUsecase(sl<IAuthRepository>()));
  sl.registerFactory<LogoutUsecase>(
    () => LogoutUsecase(sl<IAuthRepository>()),
  );
  sl.registerFactory<GetUserMembershipsUsecase>(
    () => GetUserMembershipsUsecase(sl<IAuthRepository>()),
  );
  sl.registerFactory<SendPasswordResetEmailUsecase>(
    () => SendPasswordResetEmailUsecase(sl<IAuthRepository>()),
  );

  // ── Company ─────────────────────────────────────────────────────
  sl.registerFactory<GetCompanyByIdUsecase>(
    () => GetCompanyByIdUsecase(sl<ICompanyRepository>()),
  );

  // ── Documents 🆕 (Prompt 21) ──────────────────────────────────────
  sl.registerFactory<GetDocumentsUsecase>(
    () => GetDocumentsUsecase(sl<IDocumentRepository>()),
  );
  sl.registerFactory<GetDocumentByIdUsecase>(
    () => GetDocumentByIdUsecase(sl<IDocumentRepository>()),
  );
  sl.registerFactory<UploadDocumentUsecase>(
    () => UploadDocumentUsecase(sl<IDocumentRepository>()),
  );
  sl.registerFactory<ArchiveDocumentUsecase>(
    () => ArchiveDocumentUsecase(sl<IDocumentRepository>()),
  );

  // ── Equipment 🆕 ────────────────────────────────────────────────
  sl.registerFactory<AssignEquipmentUsecase>(
    () => AssignEquipmentUsecase(sl<IEquipmentRepository>()),
  );
  sl.registerFactory<LogUsageHoursUsecase>(
    () => LogUsageHoursUsecase(sl<IEquipmentRepository>()),
  );
  // 🆕 (Prompt 22) — استكمال أدوات القراءة/تحديث الحالة الناقصة التي
  // لم تُسجَّل بعد رغم وجود عقد [IEquipmentRepository] الكامل منذ
  // Prompt 06/10 — انظر توثيق القرار في `EquipmentCubit`/
  // `UpdateEquipmentStatusUsecase`.
  sl.registerFactory<GetCompanyEquipmentUsecase>(
    () => GetCompanyEquipmentUsecase(sl<IEquipmentRepository>()),
  );
  sl.registerFactory<GetEquipmentByIdUsecase>(
    () => GetEquipmentByIdUsecase(sl<IEquipmentRepository>()),
  );
  sl.registerFactory<UpdateEquipmentStatusUsecase>(
    () => UpdateEquipmentStatusUsecase(sl<IEquipmentRepository>()),
  );

  // ── Leave 🆕 ────────────────────────────────────────────────────
  sl.registerFactory<RequestLeaveUsecase>(
    () => RequestLeaveUsecase(sl<ILeaveRepository>()),
  );
  sl.registerFactory<ReviewLeaveUsecase>(
    () => ReviewLeaveUsecase(sl<ILeaveRepository>()),
  );
  // 🆕 (Prompt 24) — استكمال أداة القراءة الناقصة (طلبات مستخدم واحد)
  // رغم وجود عقد [ILeaveRepository] الكامل منذ Prompt 06/10، بنفس
  // نمط `GetCompanyEquipmentUsecase`/`GetEquipmentByIdUsecase` في
  // Prompt 22 أعلاه.
  sl.registerFactory<GetLeaveRequestsUsecase>(
    () => GetLeaveRequestsUsecase(sl<ILeaveRepository>()),
  );

  // ── Notifications 🆕 ─────────────────────────────────────────────
  sl.registerFactory<GetNotificationsUsecase>(
    () => GetNotificationsUsecase(sl<INotificationRepository>()),
  );
  sl.registerFactory<MarkAsReadUsecase>(
    () => MarkAsReadUsecase(sl<INotificationRepository>()),
  );

  // ── Projects ────────────────────────────────────────────────────
  sl.registerFactory<GetMyProjectsUsecase>(
    () => GetMyProjectsUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<GetProjectDashboardUsecase>(
    () => GetProjectDashboardUsecase(sl<IProjectRepository>()),
  );
  // 🆕 (Prompt 20) — `features/projects/` كاملة (ProjectsCubit).
  sl.registerFactory<GetProjectByIdUsecase>(
    () => GetProjectByIdUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<CreateProjectUsecase>(
    () => CreateProjectUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<UpdateProjectUsecase>(
    () => UpdateProjectUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<GetProjectMembersUsecase>(
    () => GetProjectMembersUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<GetAvailableCompanyMembersUsecase>(
    () => GetAvailableCompanyMembersUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<AddProjectMemberUsecase>(
    () => AddProjectMemberUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<RemoveProjectMemberUsecase>(
    () => RemoveProjectMemberUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<GetProjectMilestonesUsecase>(
    () => GetProjectMilestonesUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<CreateMilestoneUsecase>(
    () => CreateMilestoneUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<UpdateMilestoneUsecase>(
    () => UpdateMilestoneUsecase(sl<IProjectRepository>()),
  );
  sl.registerFactory<DeleteMilestoneUsecase>(
    () => DeleteMilestoneUsecase(sl<IProjectRepository>()),
  );

  // ── Punch List ──────────────────────────────────────────────────
  sl.registerFactory<ClosePunchItemUsecase>(
    () => ClosePunchItemUsecase(sl<IPunchRepository>()),
  );
  sl.registerFactory<CreatePunchItemUsecase>(
    () => CreatePunchItemUsecase(sl<IPunchRepository>()),
  );
  // 🆕 (Prompt 19) لم تكن مسجّلة رغم وجود [IPunchRepository.getProjectPunchItems]
  // نفسه منذ الأساس (Prompt 06/10) — أول استهلاك فعلي لها هو
  // `PunchCubit.loadInitial`/`loadDashboard` في هذه الخطوة.
  sl.registerFactory<GetProjectPunchItemsUsecase>(
    () => GetProjectPunchItemsUsecase(sl<IPunchRepository>()),
  );

  // ── Reports ─────────────────────────────────────────────────────
  sl.registerFactory<GetReportByIdUsecase>(
    () => GetReportByIdUsecase(sl<IReportRepository>()),
  );
  sl.registerFactory<GetProjectReportsUsecase>(
    () => GetProjectReportsUsecase(sl<IReportRepository>()),
  );
  sl.registerFactory<ReviewReportUsecase>(
    () => ReviewReportUsecase(sl<IReportRepository>()),
  );
  sl.registerFactory<SaveDraftReportUsecase>(
    () => SaveDraftReportUsecase(sl<IReportRepository>()),
  );
  sl.registerFactory<SignReportUsecase>(
    () => SignReportUsecase(sl<IReportRepository>()),
  );
  sl.registerFactory<SubmitReportUsecase>(
    () => SubmitReportUsecase(sl<IReportRepository>()),
  );
  sl.registerFactory<WatchProjectReportsUsecase>(
    () => WatchProjectReportsUsecase(sl<IReportRepository>()),
  );

  // ── Tasks ───────────────────────────────────────────────────────
  sl.registerFactory<AssignTaskUsecase>(
    () => AssignTaskUsecase(sl<ITaskRepository>()),
  );
  sl.registerFactory<GetMyTasksUsecase>(
    () => GetMyTasksUsecase(sl<ITaskRepository>()),
  );
  // ✅ Prompt 16: يغذّي لوحة Kanban (`tasks_board_screen.dart`) وجدول
  // سطح المكتب (`tasks_list_screen.dart`) بكل مهام المشروع، بخلاف
  // [GetMyTasksUsecase] المقتصر على مهام المستخدم الحالي وحدها.
  sl.registerFactory<GetProjectTasksUsecase>(
    () => GetProjectTasksUsecase(sl<ITaskRepository>()),
  );
  sl.registerFactory<UpdateTaskStatusUsecase>(
    () => UpdateTaskStatusUsecase(sl<ITaskRepository>()),
  );

  // ── Users 🆕 (Prompt 26) ───────────────────────────────────────
  sl.registerFactory<GetCompanyMembersUsecase>(
    () => GetCompanyMembersUsecase(sl<IUserRepository>()),
  );
  sl.registerFactory<UpdateMemberRoleUsecase>(
    () => UpdateMemberRoleUsecase(sl<IUserRepository>()),
  );
  sl.registerFactory<UpdateMemberStatusUsecase>(
    () => UpdateMemberStatusUsecase(sl<IUserRepository>()),
  );
  sl.registerFactory<InviteUserUsecase>(
    () => InviteUserUsecase(sl<IUserRepository>()),
  );

  // ── Platform Admin 🆕 (Prompt 28) ────────────────────────────────
  sl.registerFactory<GetAllCompaniesUsecase>(
    () => GetAllCompaniesUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<GetTenantStatsUsecase>(
    () => GetTenantStatsUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<CreateTenantUsecase>(
    () => CreateTenantUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<SoftDeleteTenantUsecase>(
    () => SoftDeleteTenantUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<ExportTenantDataUsecase>(
    () => ExportTenantDataUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<GetAllAuditLogsUsecase>(
    () => GetAllAuditLogsUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<GetSubscriptionPlansUsecase>(
    () => GetSubscriptionPlansUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<GetTenantSubscriptionsUsecase>(
    () => GetTenantSubscriptionsUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<UpdateTenantPlanUsecase>(
    () => UpdateTenantPlanUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<GetPlatformUsageSnapshotUsecase>(
    () => GetPlatformUsageSnapshotUsecase(sl<IPlatformAdminRepository>()),
  );
  sl.registerFactory<GetRecentErrorLogsUsecase>(
    () => GetRecentErrorLogsUsecase(sl<IPlatformAdminRepository>()),
  );
}
