import 'package:get_it/get_it.dart';

import '../../data/local/local_database.dart';
import '../../data/storage/document_storage_service.dart';
import '../../data/storage/photo_storage_service.dart';
import '../../data/storage/signature_storage_service.dart';
import '../../data/sync/outbox/photo_upload_processor.dart';
import '../../data/sync/sync_engine.dart';
import '../../data/sync/sync_scheduler.dart';
import '../../domain/repositories/i_leave_repository.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../../domain/repositories/i_photo_repository.dart';
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
import '../../features/analytics/presentation/state/analytics_cubit.dart';
import '../../features/attendance/presentation/state/attendance_cubit.dart';
import '../../features/auth/presentation/state/auth_cubit.dart';
import '../../features/documents/presentation/state/documents_cubit.dart';
import '../../features/equipment/presentation/state/equipment_cubit.dart';
import '../../features/field_reports/core/services/weather_api_service.dart';
import '../../features/field_reports/presentation/state/report_form_cubit.dart';
import '../../features/field_reports/presentation/state/reports_inbox_cubit.dart';
import '../../features/home/presentation/state/home_cubit.dart';
import '../../features/leave_requests/presentation/state/leave_cubit.dart';
import '../../features/notifications/presentation/state/notifications_cubit.dart';
import '../../features/photos/presentation/state/photos_cubit.dart';
import '../../features/platform_admin/presentation/state/platform_admin_cubit.dart';
import '../../features/projects/presentation/state/projects_cubit.dart';
import '../../features/punch_list/presentation/state/punch_cubit.dart';
import '../../features/settings/presentation/state/settings_cubit.dart';
import '../../features/tasks/presentation/state/tasks_cubit.dart';
import '../../features/users/presentation/state/users_cubit.dart';
import '../services/camera_service.dart';
import '../services/file_picker_service.dart';
import '../services/local_settings_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../utils/image_compressor.dart';

/// يسجّل كل `Cubit`/تبعيات خاصة بميزة واحدة من `lib/features/` — أول
/// ميزة فعلية مسجَّلة هنا كانت `features/auth/` (Prompt 13)، وأُضيفت
/// إليها الآن `features/home/` (Prompt 14) عبر [_registerHomeFeature].
/// سيُملأ تدريجياً بدالة تسجيل فرعية واحدة لكل ميزة إضافية عند بنائها،
/// تُستدعى من هنا مباشرة.
///
/// `Cubit`s تُسجَّل دائماً [Factory] (وليست [Singleton]): كل شاشة/ميزة
/// تحصل على نسخة جديدة عند دخولها (`BlocProvider(create: (_) => sl<...Cubit>())`)
/// بدل مشاركة حالة واجهة عبر كامل عمر التطبيق، بخلاف `UseCases`
/// (`domain_module.dart`) و`RepositoryImpl`s (`data_module.dart`) التي
/// تبقى [Singleton] لأنها بلا حالة عرض (UI State) تخصّها.
///
/// ⚠️ استثناء واحد متعمَّد: `AuthCubit` — رغم تسجيله [Factory] هنا مثل
/// أي `Cubit` آخر (اتساقاً مع القاعدة أعلاه) — يُقدَّم فعلياً عبر
/// `BlocProvider` **واحد على مستوى `AvahiApp` كاملاً** (`app.dart`)
/// وليس داخل `features/auth/` وحدها، لأن وجهات `AdaptiveShell` (زر
/// تسجيل الخروج، عرض المستخدم/الشركة الحاليين، والآن `features/home/`
/// نفسها) تحتاجه بقدر ما تحتاجه شاشات تدفّق الدخول نفسها — التسجيل
/// [Factory] هنا يبقى صحيحاً لأن `sl<AuthCubit>()` يُستدعى مرة واحدة
/// فقط فعلياً من `app.dart`.
///
/// `HomeCubit` بالمقابل **ليس** استثناءً: يُقدَّم محلياً داخل
/// `features/home/presentation/screens/home_screen.dart` عبر
/// `BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()..loadHome(user))`
/// فقط عند الدخول فعلياً لمسار `/home` — نفس القاعدة العامة تماماً،
/// إذ لا حاجة له خارج تلك الشاشة وشاشاتها الفرعية الثلاث.
void registerFeaturesModule(GetIt sl) {
  _registerAuthFeature(sl);
  _registerHomeFeature(sl);
  _registerAttendanceFeature(sl);
  _registerTasksFeature(sl);
  _registerFieldReportsFeature(sl);
  _registerPhotosFeature(sl);
  _registerPunchListFeature(sl);
  _registerProjectsFeature(sl);
  _registerDocumentsFeature(sl);
  _registerEquipmentFeature(sl);
  _registerNotificationsFeature(sl);
  _registerLeaveFeature(sl);
  _registerAnalyticsFeature(sl);
  _registerUsersFeature(sl);
  _registerSettingsFeature(sl);
  _registerPlatformAdminFeature(sl);
}



void _registerAuthFeature(GetIt sl) {
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(
      loginUsecase: sl<LoginUsecase>(),
      logoutUsecase: sl<LogoutUsecase>(),
      getCurrentUserUsecase: sl<GetCurrentUserUsecase>(),
      getUserMembershipsUsecase: sl<GetUserMembershipsUsecase>(),
      getCompanyByIdUsecase: sl<GetCompanyByIdUsecase>(),
      sendPasswordResetEmailUsecase: sl<SendPasswordResetEmailUsecase>(),
      sessionService: sl<SessionService>(),
    ),
  );
}

void _registerHomeFeature(GetIt sl) {
  sl.registerFactory<HomeCubit>(
    () => HomeCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      getTodayAttendanceUsecase: sl<GetTodayAttendanceUsecase>(),
      getMyTasksUsecase: sl<GetMyTasksUsecase>(),
      getNotificationsUsecase: sl<GetNotificationsUsecase>(),
      markAsReadUsecase: sl<MarkAsReadUsecase>(),
    ),
  );
}

/// `features/attendance/` (Prompt 15) — أول ميزة محورية كاملة تُبنى
/// فوق `navigation/`/`auth/`/`home/`. مثل `HomeCubit`، تُقدَّم محلياً
/// فقط عبر `BlocProvider<AttendanceCubit>(create: (_) => sl<AttendanceCubit>()..loadInitial(user))`
/// داخل `attendance_screen.dart` عند الدخول فعلياً لمسار `/attendance`.
void _registerAttendanceFeature(GetIt sl) {
  sl.registerFactory<AttendanceCubit>(
    () => AttendanceCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      getTodayAttendanceUsecase: sl<GetTodayAttendanceUsecase>(),
      checkInUsecase: sl<CheckInUsecase>(),
      qrCheckInUsecase: sl<QrCheckInUsecase>(),
      checkOutUsecase: sl<CheckOutUsecase>(),
      reviewAttendanceUsecase: sl<ReviewAttendanceUsecase>(),
      getMyAttendanceHistoryUsecase: sl<GetMyAttendanceHistoryUsecase>(),
      getProjectAttendanceUsecase: sl<GetProjectAttendanceUsecase>(),
      watchProjectAttendanceUsecase: sl<WatchProjectAttendanceUsecase>(),
      locationService: sl<LocationService>(),
    ),
  );
}

/// `features/tasks/` (Prompt 16) — نفس نمط `_registerAttendanceFeature`
/// تماماً: تُقدَّم محلياً فقط عبر `BlocProvider<TasksCubit>(create: (_)
/// => sl<TasksCubit>()..loadInitial(user))` داخل `tasks_screen.dart`/
/// `tasks_board_screen.dart` عند الدخول فعلياً لمسار `/tasks` أو
/// `/tasks/board` (كل مسار يحصل على نسخة `TasksCubit` مستقلة خاصة به).
void _registerTasksFeature(GetIt sl) {
  sl.registerFactory<TasksCubit>(
    () => TasksCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      getMyTasksUsecase: sl<GetMyTasksUsecase>(),
      getProjectTasksUsecase: sl<GetProjectTasksUsecase>(),
      updateTaskStatusUsecase: sl<UpdateTaskStatusUsecase>(),
      assignTaskUsecase: sl<AssignTaskUsecase>(),
    ),
  );
}

/// `features/field_reports/` (Prompt 17) — بخلاف الميزات السابقة، هذه
/// الميزة تُقسَّم على **`Cubit`ين** منفصلين وليس واحداً، لأن جانبيها
/// (العامل الميداني/الإدارة) لا يشتركان أي حالة عرض عملياً رغم اشتراك
/// نفس كيانات `domain/`: [ReportFormCubit] لكل شاشات `mobile/`
/// (`field_reports_screen.dart` عند الدخول بدور "منشئ تقارير")،
/// و[ReportsInboxCubit] لكل شاشات `desktop/` (نفس المسار عند الدخول
/// بدور إداري يملك صلاحية `Permission.fieldReportsViewTeam` فما فوق).
/// كلاهما [Factory] بنفس القاعدة العامة أعلاه.
///
/// [WeatherApiService] وحدها هنا [LazySingleton] لا [Factory] — خدمة
/// شبكة بلا حالة عرض تخصّها (تحمل فقط `http.Client` داخلي قابل لإعادة
/// الاستخدام عبر كل الاستدعاءات)، بنفس منطق تسجيل `RepositoryImpl`s في
/// `data_module.dart` تماماً رغم وجودها هنا لأنها محلية لهذه الميزة
/// حصراً (`lib/features/field_reports/core/services/`) وليست عامة.
void _registerFieldReportsFeature(GetIt sl) {
  sl.registerLazySingleton<WeatherApiService>(() => WeatherApiService());

  sl.registerFactory<ReportFormCubit>(
    () => ReportFormCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      saveDraftReportUsecase: sl<SaveDraftReportUsecase>(),
      submitReportUsecase: sl<SubmitReportUsecase>(),
      signReportUsecase: sl<SignReportUsecase>(),
      getProjectReportsUsecase: sl<GetProjectReportsUsecase>(),
      weatherApiService: sl<WeatherApiService>(),
      locationService: sl<LocationService>(),
      cameraService: sl<CameraService>(),
      signatureStorageService: sl<SignatureStorageService>(),
      photoStorageService: sl<PhotoStorageService>(),
      photoRepository: sl<IPhotoRepository>(),
    ),
  );

  sl.registerFactory<ReportsInboxCubit>(
    () => ReportsInboxCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      getProjectReportsUsecase: sl<GetProjectReportsUsecase>(),
      watchProjectReportsUsecase: sl<WatchProjectReportsUsecase>(),
      reviewReportUsecase: sl<ReviewReportUsecase>(),
    ),
  );
}

/// `features/photos/` (Prompt 18) — على عكس `_registerFieldReportsFeature`
/// أعلاه (مقسَّمة على `Cubit`ين لجانبين لا يشتركان حالة عرض)، هذه
/// الميزة تُدار بـ `Cubit` **واحد** [PhotosCubit] لكل من `mobile/*`
/// و`desktop/*` معاً (يُقدَّم محلياً في كل شاشة عبر
/// `BlocProvider<PhotosCubit>(create: (_) => sl<PhotosCubit>()..loadInitial(user, onlyMine: ...))`
/// بنفس القاعدة العامة)، لأن الحالتين (تصفّح الصور + طابور الرفع)
/// متطابقتان تماماً بين الجوال وسطح المكتب — الفرق بينهما بصري بحت
/// (شبكة صور مبسّطة في `my_photos_screen.dart` مقابل شبكة + لوحة
/// تفاصيل جانبية في `photo_gallery.dart`/`photo_details_panel.dart`).
void _registerPhotosFeature(GetIt sl) {
  sl.registerFactory<PhotosCubit>(
    () => PhotosCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      photoRepository: sl<IPhotoRepository>(),
      photoDao: sl<LocalDatabase>().photoDao,
      cameraService: sl<CameraService>(),
      imageCompressor: sl<ImageCompressor>(),
      syncEngine: sl<SyncEngine>(),
      photoUploadProcessor: sl<PhotoUploadProcessor>(),
      locationService: sl<LocationService>(),
    ),
  );
}

/// 🆕 `features/punch_list/` (Prompt 19) — `Cubit` **واحد** [PunchCubit]
/// لكل شاشات الميزة معاً (هاتف/سطح مكتب)، بنفس منطق
/// `_registerPhotosFeature` أعلاه تماماً: الفرق بين
/// `punch_list_screen.dart` (هاتف) و`punch_dashboard.dart`/
/// `punch_item_manage.dart` (سطح مكتب) بصري بحت — مصدر بيانات مختلف
/// ضمن نفس [PunchData] (`items` مقابل `dashboardItems`، انظر توثيق
/// `PunchCubit.loadDashboard`) وليس حالة عرض منفصلة تستدعي `Cubit`
/// ثانياً. يُقدَّم محلياً في كل نقطة دخول (`/punch-list`،
/// `/punch-list/create`) عبر
/// `BlocProvider<PunchCubit>(create: (_) => sl<PunchCubit>()..loadInitial(user))`
/// — كل مسار نسخته الخاصة، بنفس قيد `TasksBoardScreen`/`TasksScreen`
/// المقبول أصلاً (انظر توثيق `PunchItemCreateScreen`).
void _registerPunchListFeature(GetIt sl) {
  sl.registerFactory<PunchCubit>(
    () => PunchCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      getProjectPunchItemsUsecase: sl<GetProjectPunchItemsUsecase>(),
      createPunchItemUsecase: sl<CreatePunchItemUsecase>(),
      closePunchItemUsecase: sl<ClosePunchItemUsecase>(),
      cameraService: sl<CameraService>(),
      photoStorageService: sl<PhotoStorageService>(),
      photoRepository: sl<IPhotoRepository>(),
      locationService: sl<LocationService>(),
    ),
  );
}

/// 🆕 `features/projects/` (Prompt 20) — `Cubit` **واحد** [ProjectsCubit]
/// لكل شاشات الميزة معاً (قائمة الهاتف، جدول سطح المكتب، نظرة عامة/
/// تفاصيل/أعضاء/مراحل/إعدادات مشروع محدد)، بنفس منطق
/// `_registerPunchListFeature`/`_registerPhotosFeature` أعلاه: الفرق
/// بصري بحت حسب `ShellMode` والمسار الفرعي المفتوح ضمن نفس [ProjectsData]
/// المجمّعة. يُقدَّم محلياً في نقطة الدخول الوحيدة `/projects`
/// (`my_projects_screen.dart`) عبر
/// `BlocProvider<ProjectsCubit>(create: (_) => sl<ProjectsCubit>()..loadInitial(user))`
/// ثم يُمرَّر عبر `extra:` لبقية المسارات الفرعية (`/projects/:id`،
/// `/projects/:id/members`، `/projects/:id/milestones`) بنفس نمط
/// `PunchItemDetailsRouteArgs` — انظر توثيق القرار الكامل في
/// `app_router.dart`.
void _registerProjectsFeature(GetIt sl) {
  sl.registerFactory<ProjectsCubit>(
    () => ProjectsCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      getProjectByIdUsecase: sl<GetProjectByIdUsecase>(),
      getProjectDashboardUsecase: sl<GetProjectDashboardUsecase>(),
      createProjectUsecase: sl<CreateProjectUsecase>(),
      updateProjectUsecase: sl<UpdateProjectUsecase>(),
      getProjectMembersUsecase: sl<GetProjectMembersUsecase>(),
      getAvailableCompanyMembersUsecase: sl<GetAvailableCompanyMembersUsecase>(),
      addProjectMemberUsecase: sl<AddProjectMemberUsecase>(),
      removeProjectMemberUsecase: sl<RemoveProjectMemberUsecase>(),
      getProjectMilestonesUsecase: sl<GetProjectMilestonesUsecase>(),
      createMilestoneUsecase: sl<CreateMilestoneUsecase>(),
      updateMilestoneUsecase: sl<UpdateMilestoneUsecase>(),
      deleteMilestoneUsecase: sl<DeleteMilestoneUsecase>(),
    ),
  );
}

/// 🆕 `features/documents/` (Prompt 21) — `Cubit` **واحد** [DocumentsCubit]
/// لكل شاشات الميزة معاً (`documents_list.dart` هاتف — عرض فقط،
/// `documents_manager.dart`/`document_viewer.dart`/`document_categories.dart`
/// سطح مكتب)، بنفس منطق `_registerPunchListFeature`/`_registerProjectsFeature`
/// أعلاه تماماً: الفرق بصري بحت حسب `ShellMode` ضمن نفس [DocumentsData]
/// المجمّعة. يُقدَّم محلياً في نقطة الدخول الوحيدة `/documents`
/// (`documents_list.dart`) عبر
/// `BlocProvider<DocumentsCubit>(create: (_) => sl<DocumentsCubit>()..loadInitial(user))`
/// ثم يُمرَّر عبر `extra:` (ضمن [DocumentRouteArgs]) لمسار
/// `/documents/:id` الفرعي، بنفس نمط `PunchItemDetailsRouteArgs`.
void _registerDocumentsFeature(GetIt sl) {
  sl.registerFactory<DocumentsCubit>(
    () => DocumentsCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      getDocumentsUsecase: sl<GetDocumentsUsecase>(),
      getDocumentByIdUsecase: sl<GetDocumentByIdUsecase>(),
      uploadDocumentUsecase: sl<UploadDocumentUsecase>(),
      archiveDocumentUsecase: sl<ArchiveDocumentUsecase>(),
      documentStorageService: sl<DocumentStorageService>(),
      filePickerService: sl<FilePickerService>(),
    ),
  );
}

/// 🆕 (Prompt 22) — `EquipmentCubit` يقود كل شاشات ميزة `equipment/`
/// معاً (`my_equipment_screen.dart`/`log_usage_screen.dart` على
/// الهاتف، `equipment_registry.dart`/`equipment_details.dart`/
/// `maintenance_schedule.dart` على سطح المكتب)، بنفس منطق
/// `_registerDocumentsFeature`/`_registerPunchListFeature` أعلاه
/// تماماً: الفرق بصري بحت حسب `ShellMode` ضمن نفس [EquipmentData]
/// المجمّعة. يُقدَّم محلياً في نقطة الدخول الوحيدة `/equipment`
/// (`my_equipment_screen.dart`) عبر
/// `BlocProvider<EquipmentCubit>(create: (_) => sl<EquipmentCubit>()..loadInitial(user))`
/// ثم يُمرَّر عبر `extra:` (ضمن [LogUsageRouteArgs]) لمسار
/// `/equipment/log-usage` الفرعي، بنفس نمط `PunchItemDetailsRouteArgs`.
void _registerEquipmentFeature(GetIt sl) {
  sl.registerFactory<EquipmentCubit>(
    () => EquipmentCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      getCompanyEquipmentUsecase: sl<GetCompanyEquipmentUsecase>(),
      getEquipmentByIdUsecase: sl<GetEquipmentByIdUsecase>(),
      assignEquipmentUsecase: sl<AssignEquipmentUsecase>(),
      logUsageHoursUsecase: sl<LogUsageHoursUsecase>(),
      updateEquipmentStatusUsecase: sl<UpdateEquipmentStatusUsecase>(),
      getProjectMembersUsecase: sl<GetProjectMembersUsecase>(),
    ),
  );
}

/// 🆕 (Prompt 23) — `NotificationsCubit` يقود كل شاشات/مكونات ميزة
/// `notifications/` معاً (`notifications_screen.dart` الموحَّدة، و
/// `navigation/shells/desktop/notification_panel.dart` المنسدلة على
/// سطح المكتب)، بنفس منطق `_registerEquipmentFeature`/
/// `_registerDocumentsFeature` أعلاه: كل نقطة دخول تحصل على نسخة
/// `Cubit` خاصة بها عبر `sl<NotificationsCubit>()..loadInitial(user)`
/// — انظر توثيق القرار الكامل في `notifications_screen.dart`/
/// `notification_panel.dart`.
///
/// ⚠️ [INotificationRepository] مُحقَنة هنا مباشرة إلى جانب
/// `UseCases` (وليس عبر `UseCase` إضافية) لتغذية الاشتراك اللحظي —
/// انظر توثيق القرار الكامل في `NotificationsCubit` نفسها، بنفس
/// سابقة `photoRepository: sl<IPhotoRepository>()` في
/// `_registerPhotosFeature` أعلاه.
void _registerNotificationsFeature(GetIt sl) {
  sl.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(
      getNotificationsUsecase: sl<GetNotificationsUsecase>(),
      markAsReadUsecase: sl<MarkAsReadUsecase>(),
      notificationRepository: sl<INotificationRepository>(),
    ),
  );
}

/// 🆕 (Prompt 24) — `LeaveCubit` يقود كل شاشات ميزة `leave_requests/`
/// معاً (`my_leave_requests_screen.dart`/`create_leave_request_screen.dart`
/// على الهاتف، `leave_requests_inbox.dart`/`leave_request_review.dart`
/// على سطح المكتب)، بنفس منطق `_registerEquipmentFeature`/
/// `_registerDocumentsFeature` أعلاه: `Cubit` واحد مجمّع، الفرق بصري
/// بحت حسب `ShellMode` والصلاحية (`LeaveData.canApproveTeam`) ضمن نفس
/// [LeaveData]. يُقدَّم محلياً في نقطة الدخول الوحيدة
/// `/leave-requests` (`my_leave_requests_screen.dart`) عبر
/// `BlocProvider<LeaveCubit>(create: (_) => sl<LeaveCubit>()..loadInitial(user))`
/// — بنفس نمط `PunchListScreen`/`MyEquipmentScreen` تماماً.
///
/// ⚠️ [ILeaveRepository] مُحقَنة هنا مباشرة إلى جانب `UseCases`
/// (وليس عبر `UseCase` إضافية) لجلب طلبات إجازة الشركة الكاملة —
/// انظر توثيق القرار الكامل في `LeaveCubit` نفسها، بنفس سابقة
/// `notificationRepository: sl<INotificationRepository>()` أعلاه
/// مباشرة.
void _registerLeaveFeature(GetIt sl) {
  sl.registerFactory<LeaveCubit>(
    () => LeaveCubit(
      requestLeaveUsecase: sl<RequestLeaveUsecase>(),
      reviewLeaveUsecase: sl<ReviewLeaveUsecase>(),
      getLeaveRequestsUsecase: sl<GetLeaveRequestsUsecase>(),
      leaveRepository: sl<ILeaveRepository>(),
    ),
  );
}

/// 🆕 (Prompt 25) — `AnalyticsCubit` يقود كل شاشات/ألسنة ميزة
/// `analytics/` معاً (`analytics_dashboard.dart` والألسنة الداخلية
/// الثلاثة `project_analytics.dart`/`attendance_analytics.dart`/
/// `export_analytics_screen.dart` — انظر توثيق القرار الكامل في
/// `analytics_dashboard.dart` حول اعتماد ألسنة داخلية بدل مسارات
/// `go_router` منفصلة لكل منها)، بنفس منطق `_registerEquipmentFeature`/
/// `_registerLeaveFeature` أعلاه: `Cubit` واحد مجمّع يُقدَّم محلياً في
/// نقطة الدخول الوحيدة `/analytics` (`analytics_dashboard.dart`) عبر
/// `BlocProvider<AnalyticsCubit>(create: (_) => sl<AnalyticsCubit>()..loadInitial(user))`.
///
/// ⚠️ بخلاف كل تسجيل سابق أعلاه — الخمسة UseCases المُحقَنة هنا
/// (`GetMyProjectsUsecase`/`GetProjectDashboardUsecase`/
/// `GetProjectTasksUsecase`/`GetProjectAttendanceUsecase`/
/// `GetCompanyEquipmentUsecase`) **كلها مسجَّلة أصلاً** ضمن
/// `domain_module.dart` منذ خطوات سابقة (`features/home/`،
/// `features/tasks/`، `features/attendance/`، `features/equipment/`
/// على الترتيب) — هذه أول ميزة لا تحتاج أي `UseCase`/عقد مستودع جديد
/// خاص بها إطلاقاً، انظر توثيق القرار الكامل في `AnalyticsCubit` نفسها.
void _registerAnalyticsFeature(GetIt sl) {
  sl.registerFactory<AnalyticsCubit>(
    () => AnalyticsCubit(
      getMyProjectsUsecase: sl<GetMyProjectsUsecase>(),
      getProjectDashboardUsecase: sl<GetProjectDashboardUsecase>(),
      getProjectTasksUsecase: sl<GetProjectTasksUsecase>(),
      getProjectAttendanceUsecase: sl<GetProjectAttendanceUsecase>(),
      getCompanyEquipmentUsecase: sl<GetCompanyEquipmentUsecase>(),
    ),
  );
}

/// 🆕 (Prompt 26) — `UsersCubit` يقود شاشة `users_list.dart` الوحيدة
/// وكل ما تُظهره من لوحات فرعية (`user_details.dart`/
/// `user_roles_edit.dart`/`invite_user.dart`) معاً، بنفس منطق
/// `_registerAnalyticsFeature`/`_registerLeaveFeature` أعلاه: `Cubit`
/// واحد مجمّع يُقدَّم محلياً في نقطة الدخول الوحيدة `/users`
/// (`users_list.dart`) عبر
/// `BlocProvider<UsersCubit>(create: (_) => sl<UsersCubit>()..loadInitial(user))`.
void _registerUsersFeature(GetIt sl) {
  sl.registerFactory<UsersCubit>(
    () => UsersCubit(
      getCompanyMembersUsecase: sl<GetCompanyMembersUsecase>(),
      updateMemberRoleUsecase: sl<UpdateMemberRoleUsecase>(),
      updateMemberStatusUsecase: sl<UpdateMemberStatusUsecase>(),
      inviteUserUsecase: sl<InviteUserUsecase>(),
    ),
  );
}

/// 🆕 (Prompt 27) — `SettingsCubit` يقود فقط `sync_settings.dart`
/// و`notification_settings.dart` (البيانات الوحيدتان التفاعليتان ضمن
/// `features/settings/` — انظر توثيق توزيع المسؤولية الكامل في
/// `settings_screen.dart`)، لذا **كلتا** الشاشتين تُقدِّمان نسخته
/// الخاصتين محلياً بنفسهما (`BlocProvider<SettingsCubit>(create: (_) =>
/// sl<SettingsCubit>()..loadInitial())`)، وليس `settings_screen.dart`
/// نفسها — بخلاف `UsersCubit`/`AnalyticsCubit` أعلاه ذات نقطة دخول
/// واحدة فقط لكل منهما.
///
/// ⚠️ `LocalSettingsService`/`NotificationService` مُحقنتان هنا من
/// `core_module.dart` (وليس `Cubit` آخر) — [SettingsCubit] الطبقة
/// الوحيدة التي تربط بين `data/sync/sync_scheduler.dart` (حالة/تحكّم
/// بالمزامنة) وهاتين الخدمتين معاً لعرض واحد موحّد.
void _registerSettingsFeature(GetIt sl) {
  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      settingsService: sl<LocalSettingsService>(),
      syncScheduler: sl<SyncScheduler>(),
      notificationService: sl<NotificationService>(),
    ),
  );
}

/// 🆕 (Prompt 28) — `PlatformAdminCubit` يقود شاشة `admin_dashboard.dart`
/// الوحيدة وكل ألسنتها الست (نظرة عامة/المستأجرون/الاشتراكات/الفوترة/
/// المراقبة/الأخطاء/سجل التدقيق) معاً — بنفس منطق `_registerUsersFeature`/
/// `_registerAnalyticsFeature` أعلاه: `Cubit` واحد مجمّع يُقدَّم محلياً
/// في نقطة الدخول الوحيدة `RoutePaths.platformAdmin`
/// (`admin_dashboard.dart`) عبر
/// `BlocProvider<PlatformAdminCubit>(create: (_) => sl<PlatformAdminCubit>()..loadInitial(user))`.
void _registerPlatformAdminFeature(GetIt sl) {
  sl.registerFactory<PlatformAdminCubit>(
    () => PlatformAdminCubit(
      getAllCompaniesUsecase: sl<GetAllCompaniesUsecase>(),
      getTenantStatsUsecase: sl<GetTenantStatsUsecase>(),
      createTenantUsecase: sl<CreateTenantUsecase>(),
      softDeleteTenantUsecase: sl<SoftDeleteTenantUsecase>(),
      exportTenantDataUsecase: sl<ExportTenantDataUsecase>(),
      getAllAuditLogsUsecase: sl<GetAllAuditLogsUsecase>(),
      getSubscriptionPlansUsecase: sl<GetSubscriptionPlansUsecase>(),
      getTenantSubscriptionsUsecase: sl<GetTenantSubscriptionsUsecase>(),
      updateTenantPlanUsecase: sl<UpdateTenantPlanUsecase>(),
      getPlatformUsageSnapshotUsecase: sl<GetPlatformUsageSnapshotUsecase>(),
      getRecentErrorLogsUsecase: sl<GetRecentErrorLogsUsecase>(),
    ),
  );
}
