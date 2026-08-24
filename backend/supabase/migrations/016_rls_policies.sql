-- ============================================================
-- 016_rls_policies.sql
-- سياسات RLS لكل جدول. المبدأ العام:
--  • عزل صارم عبر company_id = public.current_user_company_id()، إلا لمالك
--    المنصة (public.is_platform_owner()) الذي يرى كل شيء.
--  • عمليات الكتابة الحساسة مقيّدة بحد أدنى من الدور عبر
--    public.has_min_role(...).
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- companies
-- ────────────────────────────────────────────────────────────
create policy companies_select on public.companies
  for select using (
    id = public.current_user_company_id() or public.is_platform_owner()
  );

create policy companies_update on public.companies
  for update using (
    (id = public.current_user_company_id() and public.has_min_role('admin'))
    or public.is_platform_owner()
  );

create policy companies_insert on public.companies
  for insert with check (public.is_platform_owner());

create policy companies_delete on public.companies
  for delete using (public.is_platform_owner());

-- ────────────────────────────────────────────────────────────
-- platform_admins — يُدار حصراً من مالكي المنصة أنفسهم
-- ────────────────────────────────────────────────────────────
create policy platform_admins_select on public.platform_admins
  for select using (public.is_platform_owner());

create policy platform_admins_write on public.platform_admins
  for all using (public.is_platform_owner())
  with check (public.is_platform_owner());

-- ────────────────────────────────────────────────────────────
-- company_members
-- ────────────────────────────────────────────────────────────
create policy company_members_select on public.company_members
  for select using (
    company_id = public.current_user_company_id() or public.is_platform_owner()
  );

create policy company_members_insert on public.company_members
  for insert with check (
    (company_id = public.current_user_company_id() and public.has_min_role('admin'))
    or public.is_platform_owner()
  );

create policy company_members_update on public.company_members
  for update using (
    (company_id = public.current_user_company_id() and public.has_min_role('admin'))
    or user_id = public.current_user_id()
    or public.is_platform_owner()
  );

create policy company_members_delete on public.company_members
  for delete using (
    (company_id = public.current_user_company_id() and public.has_min_role('admin'))
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- projects
-- ────────────────────────────────────────────────────────────
create policy projects_select on public.projects
  for select using (
    company_id = public.current_user_company_id() or public.is_platform_owner()
  );

create policy projects_insert on public.projects
  for insert with check (
    (company_id = public.current_user_company_id() and public.has_min_role('projectManager'))
    or public.is_platform_owner()
  );

create policy projects_update on public.projects
  for update using (
    (company_id = public.current_user_company_id() and public.has_min_role('projectManager'))
    or public.is_platform_owner()
  );

create policy projects_delete on public.projects
  for delete using (
    (company_id = public.current_user_company_id() and public.has_min_role('admin'))
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- project_members
-- ────────────────────────────────────────────────────────────
create policy project_members_select on public.project_members
  for select using (
    company_id = public.current_user_company_id() or public.is_platform_owner()
  );

create policy project_members_write on public.project_members
  for all using (
    (company_id = public.current_user_company_id() and public.has_min_role('projectManager'))
    or public.is_platform_owner()
  )
  with check (
    (company_id = public.current_user_company_id() and public.has_min_role('projectManager'))
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- tasks
-- ────────────────────────────────────────────────────────────
create policy tasks_select on public.tasks
  for select using (
    company_id = public.current_user_company_id() or public.is_platform_owner()
  );

-- أي عضو نشط في الشركة يمكنه إنشاء مهمة إسنادية لنفسه؛ الإنشاء
-- الحر لأي شخص يتطلب رتبة engineer فأعلى (permission: tasksCreate).
create policy tasks_insert on public.tasks
  for insert with check (
    (company_id = public.current_user_company_id() and public.has_min_role('engineer'))
    or public.is_platform_owner()
  );

create policy tasks_update on public.tasks
  for update using (
    (
      company_id = public.current_user_company_id()
      and (public.has_min_role('engineer') or assigned_to = public.current_user_id())
    )
    or public.is_platform_owner()
  );

create policy tasks_delete on public.tasks
  for delete using (
    (company_id = public.current_user_company_id() and public.has_min_role('projectManager'))
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- attendance
-- ────────────────────────────────────────────────────────────
-- الرؤية: صاحب السجل نفسه، أو foreman فأعلى (attendanceViewAll)
create policy attendance_select on public.attendance
  for select using (
    (
      company_id = public.current_user_company_id()
      and (user_id = public.current_user_id() or public.has_min_role('foreman'))
    )
    or public.is_platform_owner()
  );

-- تسجيل الحضور: كل عضو نشط يسجل حضوره الخاص فقط (attendanceCheckInSelf)
create policy attendance_insert on public.attendance
  for insert with check (
    (company_id = public.current_user_company_id() and user_id = public.current_user_id())
    or public.is_platform_owner()
  );

-- التعديل: صاحب السجل (تسجيل انصراف) أو foreman فأعلى لاعتماد/رفض
create policy attendance_update on public.attendance
  for update using (
    (
      company_id = public.current_user_company_id()
      and (user_id = public.current_user_id() or public.has_min_role('foreman'))
    )
    or public.is_platform_owner()
  );

create policy attendance_delete on public.attendance
  for delete using (
    (company_id = public.current_user_company_id() and public.has_min_role('admin'))
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- field_reports
-- ────────────────────────────────────────────────────────────
create policy field_reports_select on public.field_reports
  for select using (
    (
      company_id = public.current_user_company_id()
      and (created_by = public.current_user_id() or public.has_min_role('foreman'))
    )
    or public.is_platform_owner()
  );

create policy field_reports_insert on public.field_reports
  for insert with check (
    (company_id = public.current_user_company_id() and created_by = public.current_user_id())
    or public.is_platform_owner()
  );

-- التعديل: صاحب التقرير طالما لم يُعتمد بعد، أو engineer فأعلى للاعتماد/الرفض
create policy field_reports_update on public.field_reports
  for update using (
    (
      company_id = public.current_user_company_id()
      and (
        (created_by = public.current_user_id() and status = 'draft')
        or public.has_min_role('engineer')
      )
    )
    or public.is_platform_owner()
  );

create policy field_reports_delete on public.field_reports
  for delete using (
    (
      company_id = public.current_user_company_id()
      and (
        (created_by = public.current_user_id() and status = 'draft')
        or public.has_min_role('projectManager')
      )
    )
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- punch_items
-- ────────────────────────────────────────────────────────────
create policy punch_items_select on public.punch_items
  for select using (
    company_id = public.current_user_company_id() or public.is_platform_owner()
  );

create policy punch_items_insert on public.punch_items
  for insert with check (
    (company_id = public.current_user_company_id() and public.has_min_role('worker'))
    or public.is_platform_owner()
  );

create policy punch_items_update on public.punch_items
  for update using (
    (
      company_id = public.current_user_company_id()
      and (assigned_to = public.current_user_id() or created_by = public.current_user_id() or public.has_min_role('foreman'))
    )
    or public.is_platform_owner()
  );

create policy punch_items_delete on public.punch_items
  for delete using (
    (company_id = public.current_user_company_id() and public.has_min_role('engineer'))
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- photos
-- ────────────────────────────────────────────────────────────
create policy photos_select on public.photos
  for select using (
    company_id = public.current_user_company_id() or public.is_platform_owner()
  );

create policy photos_insert on public.photos
  for insert with check (
    (company_id = public.current_user_company_id() and uploaded_by = public.current_user_id())
    or public.is_platform_owner()
  );

create policy photos_delete on public.photos
  for delete using (
    (
      company_id = public.current_user_company_id()
      and (uploaded_by = public.current_user_id() or public.has_min_role('projectManager'))
    )
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- documents
-- ────────────────────────────────────────────────────────────
create policy documents_select on public.documents
  for select using (
    company_id = public.current_user_company_id() or public.is_platform_owner()
  );

create policy documents_insert on public.documents
  for insert with check (
    (company_id = public.current_user_company_id() and public.has_min_role('engineer'))
    or public.is_platform_owner()
  );

create policy documents_update on public.documents
  for update using (
    (company_id = public.current_user_company_id() and public.has_min_role('engineer'))
    or public.is_platform_owner()
  );

create policy documents_delete on public.documents
  for delete using (
    (company_id = public.current_user_company_id() and public.has_min_role('projectManager'))
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- audit_logs — للقراءة فقط من admin فأعلى؛ الكتابة عبر triggers فقط
-- ────────────────────────────────────────────────────────────
create policy audit_logs_select on public.audit_logs
  for select using (
    (company_id = public.current_user_company_id() and public.has_min_role('admin'))
    or public.is_platform_owner()
  );

-- لا توجد سياسة insert/update/delete صريحة: الكتابة تتم فقط عبر
-- دالة الـ trigger بصلاحية security definer (017_audit_triggers.sql)،
-- ما يمنع أي مستخدم عادي من التلاعب بسجل التدقيق مباشرة.

-- ────────────────────────────────────────────────────────────
-- equipment
-- ────────────────────────────────────────────────────────────
create policy equipment_select on public.equipment
  for select using (
    company_id = public.current_user_company_id() or public.is_platform_owner()
  );

create policy equipment_insert on public.equipment
  for insert with check (
    (company_id = public.current_user_company_id() and public.has_min_role('projectManager'))
    or public.is_platform_owner()
  );

create policy equipment_update on public.equipment
  for update using (
    (
      company_id = public.current_user_company_id()
      and (public.has_min_role('projectManager') or assigned_to = public.current_user_id())
    )
    or public.is_platform_owner()
  );

create policy equipment_delete on public.equipment
  for delete using (
    (company_id = public.current_user_company_id() and public.has_min_role('admin'))
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- notifications — كل مستخدم يرى ويدير إشعاراته الخاصة فقط
-- ────────────────────────────────────────────────────────────
create policy notifications_select on public.notifications
  for select using (
    (company_id = public.current_user_company_id() and user_id = public.current_user_id())
    or public.is_platform_owner()
  );

create policy notifications_insert on public.notifications
  for insert with check (
    (company_id = public.current_user_company_id() and public.has_min_role('foreman'))
    or public.is_platform_owner()
  );

create policy notifications_update on public.notifications
  for update using (
    (company_id = public.current_user_company_id() and user_id = public.current_user_id())
    or public.is_platform_owner()
  );

create policy notifications_delete on public.notifications
  for delete using (
    (company_id = public.current_user_company_id() and user_id = public.current_user_id())
    or public.is_platform_owner()
  );

-- ────────────────────────────────────────────────────────────
-- leave_requests
-- ────────────────────────────────────────────────────────────
create policy leave_requests_select on public.leave_requests
  for select using (
    (
      company_id = public.current_user_company_id()
      and (user_id = public.current_user_id() or public.has_min_role('foreman'))
    )
    or public.is_platform_owner()
  );

create policy leave_requests_insert on public.leave_requests
  for insert with check (
    (company_id = public.current_user_company_id() and user_id = public.current_user_id())
    or public.is_platform_owner()
  );

-- التعديل: صاحب الطلب طالما pending (مثلاً للإلغاء)، أو foreman
-- فأعلى للاعتماد/الرفض (leaveRequestApproveTeam)
create policy leave_requests_update on public.leave_requests
  for update using (
    (
      company_id = public.current_user_company_id()
      and (
        (user_id = public.current_user_id() and status = 'pending')
        or public.has_min_role('foreman')
      )
    )
    or public.is_platform_owner()
  );

create policy leave_requests_delete on public.leave_requests
  for delete using (
    (company_id = public.current_user_company_id() and public.has_min_role('admin'))
    or public.is_platform_owner()
  );
