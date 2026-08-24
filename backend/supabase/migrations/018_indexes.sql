-- ============================================================
-- 018_indexes.sql
-- فهارس أداء لكل الاستعلامات المتوقعة (عزل tenant، شاشات القوائم
-- والفلترة، والمزامنة من العمل دون اتصال).
-- ============================================================

-- company_members
create index if not exists idx_company_members_company on public.company_members (company_id);
create index if not exists idx_company_members_user on public.company_members (user_id);
create index if not exists idx_company_members_role on public.company_members (company_id, role);

-- projects
create index if not exists idx_projects_company on public.projects (company_id);
create index if not exists idx_projects_status on public.projects (company_id, status);

-- project_members
create index if not exists idx_project_members_project on public.project_members (project_id);
create index if not exists idx_project_members_user on public.project_members (user_id);
create index if not exists idx_project_members_company on public.project_members (company_id);

-- tasks
create index if not exists idx_tasks_company on public.tasks (company_id);
create index if not exists idx_tasks_project on public.tasks (project_id);
create index if not exists idx_tasks_assigned_to on public.tasks (assigned_to);
create index if not exists idx_tasks_status on public.tasks (project_id, status);

-- attendance
create index if not exists idx_attendance_company on public.attendance (company_id);
create index if not exists idx_attendance_project on public.attendance (project_id);
create index if not exists idx_attendance_user on public.attendance (user_id);
create index if not exists idx_attendance_user_date on public.attendance (user_id, check_in_at);
create index if not exists idx_attendance_status on public.attendance (company_id, status);
-- ⚠️ فهرس فريد للمزامنة الآمنة (idempotency) — client_mutation_id
create unique index if not exists idx_attendance_client_mutation_id
  on public.attendance (client_mutation_id);

-- field_reports
create index if not exists idx_field_reports_company on public.field_reports (company_id);
create index if not exists idx_field_reports_project on public.field_reports (project_id);
create index if not exists idx_field_reports_created_by on public.field_reports (created_by);
create index if not exists idx_field_reports_status on public.field_reports (project_id, status);
create index if not exists idx_field_reports_date on public.field_reports (project_id, report_date);

-- punch_items
create index if not exists idx_punch_items_company on public.punch_items (company_id);
create index if not exists idx_punch_items_project on public.punch_items (project_id);
create index if not exists idx_punch_items_assigned_to on public.punch_items (assigned_to);
create index if not exists idx_punch_items_status on public.punch_items (project_id, status);
create index if not exists idx_punch_items_field_report on public.punch_items (field_report_id);

-- photos
create index if not exists idx_photos_company on public.photos (company_id);
create index if not exists idx_photos_project on public.photos (project_id);
create index if not exists idx_photos_related_entity on public.photos (related_entity_type, related_entity_id);

-- documents
create index if not exists idx_documents_company on public.documents (company_id);
create index if not exists idx_documents_project on public.documents (project_id);
create index if not exists idx_documents_category on public.documents (company_id, category);
create index if not exists idx_documents_archived on public.documents (company_id, is_archived);

-- audit_logs
create index if not exists idx_audit_logs_company on public.audit_logs (company_id);
create index if not exists idx_audit_logs_record on public.audit_logs (table_name, record_id);
create index if not exists idx_audit_logs_created_at on public.audit_logs (created_at desc);

-- equipment
create index if not exists idx_equipment_company on public.equipment (company_id);
create index if not exists idx_equipment_project on public.equipment (project_id);
create index if not exists idx_equipment_status on public.equipment (company_id, status);
create index if not exists idx_equipment_assigned_to on public.equipment (assigned_to);

-- notifications
create index if not exists idx_notifications_user_unread
  on public.notifications (user_id, is_read, created_at desc);
create index if not exists idx_notifications_company on public.notifications (company_id);

-- leave_requests
create index if not exists idx_leave_requests_company on public.leave_requests (company_id);
create index if not exists idx_leave_requests_user on public.leave_requests (user_id);
create index if not exists idx_leave_requests_status on public.leave_requests (company_id, status);
