import 'roles.dart';

/// الصلاحيات الدقيقة (Fine-grained Permissions) المتحكمة بواجهات
/// وإجراءات التطبيق. هذا التعداد أوسع من [UserRole] عمداً؛ الدور
/// يحدد "من هو المستخدم"، بينما الصلاحية تحدد "ماذا يمكنه أن يفعل"،
/// مما يسمح لاحقاً بصلاحيات استثنائية مُخصّصة دون تعديل الأدوار نفسها.
enum Permission {
  // ── الحضور Attendance ────────────────────────────────────
  attendanceCheckInSelf,
  attendanceApproveTeam,
  attendanceViewAll,
  attendanceEditRecords,

  // ── المهام Tasks ──────────────────────────────────────────
  tasksViewAssigned,
  tasksCreate,
  tasksAssign,
  tasksEditAny,
  tasksDeleteAny,

  // ── التقارير الميدانية Field Reports ────────────────────────
  fieldReportsCreate,
  fieldReportsViewTeam,
  fieldReportsViewAll,
  fieldReportsApprove,

  // ── الصور Photos ──────────────────────────────────────────
  photosUpload,
  photosViewAll,
  photosDeleteAny,

  // ── قوائم الملاحظات Punch List ───────────────────────────
  punchListCreate,
  punchListResolve,
  punchListCloseOut,

  // ── المشاريع Projects ─────────────────────────────────────
  projectsView,
  projectsCreate,
  projectsEdit,
  projectsArchive,

  // ── المستندات Documents ───────────────────────────────────
  documentsView,
  documentsUpload,
  documentsDeleteAny,

  // ── المعدات Equipment ──────────────────────────────────────
  equipmentView,
  equipmentAssign,
  equipmentManage,

  // ── طلبات الإجازة Leave Requests ────────────────────────────
  leaveRequestSubmit,
  leaveRequestApproveTeam,
  leaveRequestViewAll,

  // ── التحليلات Analytics ─────────────────────────────────────
  analyticsViewTeam,
  analyticsViewProject,
  analyticsViewTenantWide,

  // ── المستخدمون Users ─────────────────────────────────────────
  usersView,
  usersInvite,
  usersEditRoles,
  usersDeactivate,

  // ── الإعدادات Settings ────────────────────────────────────────
  settingsEditTenant,
  settingsManageBranding,

  // ── إدارة المنصة Platform Admin ─────────────────────────────
  platformManageTenants,
  platformViewAllData,
  platformExportTenantData,
}

/// خريطة ربط كل [UserRole] بمجموعة [Permission] الممنوحة له.
///
/// ⚠️ هذه هي الخريطة المرجعية على مستوى واجهة Flutter فقط (لإخفاء/
/// إظهار عناصر الواجهة بشكل استباقي). التحقق الملزم الفعلي يبقى دائماً
/// على مستوى قاعدة البيانات عبر سياسات RLS في Supabase (Prompt 03)،
/// ولا يجب الاعتماد على هذه الخريطة وحدها كخط دفاع أمني.
abstract final class RolePermissions {
  static final Map<UserRole, Set<Permission>> map = <UserRole, Set<Permission>>{
    UserRole.worker: <Permission>{
      Permission.attendanceCheckInSelf,
      Permission.tasksViewAssigned,
      Permission.fieldReportsCreate,
      Permission.photosUpload,
      Permission.punchListCreate,
      Permission.projectsView,
      Permission.documentsView,
      Permission.equipmentView,
      Permission.leaveRequestSubmit,
    },
    UserRole.foreman: <Permission>{
      Permission.attendanceCheckInSelf,
      Permission.attendanceApproveTeam,
      Permission.attendanceViewAll,
      Permission.tasksViewAssigned,
      Permission.tasksAssign,
      Permission.fieldReportsCreate,
      Permission.fieldReportsViewTeam,
      Permission.photosUpload,
      Permission.photosViewAll,
      Permission.punchListCreate,
      Permission.punchListResolve,
      Permission.projectsView,
      Permission.documentsView,
      Permission.equipmentView,
      Permission.equipmentAssign,
      Permission.leaveRequestSubmit,
      Permission.leaveRequestApproveTeam,
      Permission.analyticsViewTeam,
      Permission.usersView,
    },
    UserRole.engineer: <Permission>{
      Permission.attendanceCheckInSelf,
      Permission.attendanceViewAll,
      Permission.tasksViewAssigned,
      Permission.tasksCreate,
      Permission.tasksAssign,
      Permission.tasksEditAny,
      Permission.fieldReportsCreate,
      Permission.fieldReportsViewTeam,
      Permission.fieldReportsViewAll,
      Permission.fieldReportsApprove,
      Permission.photosUpload,
      Permission.photosViewAll,
      Permission.punchListCreate,
      Permission.punchListResolve,
      Permission.punchListCloseOut,
      Permission.projectsView,
      Permission.documentsView,
      Permission.documentsUpload,
      Permission.equipmentView,
      Permission.equipmentAssign,
      Permission.leaveRequestSubmit,
      Permission.analyticsViewTeam,
      Permission.analyticsViewProject,
      Permission.usersView,
    },
    UserRole.projectManager: <Permission>{
      Permission.attendanceCheckInSelf,
      Permission.attendanceApproveTeam,
      Permission.attendanceViewAll,
      Permission.attendanceEditRecords,
      Permission.tasksViewAssigned,
      Permission.tasksCreate,
      Permission.tasksAssign,
      Permission.tasksEditAny,
      Permission.tasksDeleteAny,
      Permission.fieldReportsCreate,
      Permission.fieldReportsViewTeam,
      Permission.fieldReportsViewAll,
      Permission.fieldReportsApprove,
      Permission.photosUpload,
      Permission.photosViewAll,
      Permission.photosDeleteAny,
      Permission.punchListCreate,
      Permission.punchListResolve,
      Permission.punchListCloseOut,
      Permission.projectsView,
      Permission.projectsCreate,
      Permission.projectsEdit,
      Permission.projectsArchive,
      Permission.documentsView,
      Permission.documentsUpload,
      Permission.documentsDeleteAny,
      Permission.equipmentView,
      Permission.equipmentAssign,
      Permission.equipmentManage,
      Permission.leaveRequestSubmit,
      Permission.leaveRequestApproveTeam,
      Permission.leaveRequestViewAll,
      Permission.analyticsViewTeam,
      Permission.analyticsViewProject,
      Permission.usersView,
      Permission.usersInvite,
    },
    UserRole.admin: <Permission>{
      // مدير النظام (Tenant Admin) يمتلك كل الصلاحيات ضمن حدود
      // مستأجره، باستثناء صلاحيات إدارة المنصة العابرة للمستأجرين.
      ...Permission.values.where(
        (Permission p) =>
            p != Permission.platformManageTenants &&
            p != Permission.platformViewAllData &&
            p != Permission.platformExportTenantData,
      ),
    },
    UserRole.platformOwner: <Permission>{
      // مالك المنصة يمتلك كل الصلاحيات دون استثناء.
      ...Permission.values,
    },
  };

  /// يتحقق مما إذا كان [role] يملك [permission] محددة.
  static bool has(UserRole role, Permission permission) {
    return map[role]?.contains(permission) ?? false;
  }

  /// يتحقق مما إذا كان [role] يملك أياً من [permissions].
  static bool hasAny(UserRole role, Set<Permission> permissions) {
    final Set<Permission> granted = map[role] ?? const <Permission>{};
    return permissions.any(granted.contains);
  }

  /// يتحقق مما إذا كان [role] يملك كل [permissions] المطلوبة.
  static bool hasAll(UserRole role, Set<Permission> permissions) {
    final Set<Permission> granted = map[role] ?? const <Permission>{};
    return permissions.every(granted.contains);
  }
}
