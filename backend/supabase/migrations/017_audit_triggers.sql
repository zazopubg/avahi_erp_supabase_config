-- ============================================================
-- 017_audit_triggers.sql
-- دالة trigger عامة تُسجّل كل INSERT/UPDATE/DELETE في audit_logs
-- تلقائياً للجداول الحساسة، مع التقاط company_id وuser_id ديناميكياً.
-- ============================================================

create or replace function public.audit_log_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid;
  v_record_id  uuid;
begin
  -- استخلاص company_id من السجل (كل الجداول المستهدفة تملك هذا العمود)
  if tg_op = 'DELETE' then
    v_company_id := old.company_id;
    v_record_id  := old.id;
  else
    v_company_id := new.company_id;
    v_record_id  := new.id;
  end if;

  insert into public.audit_logs (
    company_id, user_id, action, table_name, record_id, old_data, new_data
  ) values (
    v_company_id,
    public.current_user_id(),
    tg_op,
    tg_table_name,
    v_record_id,
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('UPDATE', 'INSERT') then to_jsonb(new) else null end
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

comment on function public.audit_log_trigger() is 'دالة trigger عامة تُدرج نسخة من كل تغيير في audit_logs؛ security definer لتفادي حجب RLS للكتابة.';

-- ── ربط الدالة بالجداول الحساسة المطلوب تدقيقها ────────────────
create trigger trg_audit_attendance
  after insert or update or delete on public.attendance
  for each row execute function public.audit_log_trigger();

create trigger trg_audit_field_reports
  after insert or update or delete on public.field_reports
  for each row execute function public.audit_log_trigger();

create trigger trg_audit_tasks
  after insert or update or delete on public.tasks
  for each row execute function public.audit_log_trigger();

create trigger trg_audit_punch_items
  after insert or update or delete on public.punch_items
  for each row execute function public.audit_log_trigger();

create trigger trg_audit_equipment
  after insert or update or delete on public.equipment
  for each row execute function public.audit_log_trigger();

create trigger trg_audit_leave_requests
  after insert or update or delete on public.leave_requests
  for each row execute function public.audit_log_trigger();

create trigger trg_audit_documents
  after insert or update or delete on public.documents
  for each row execute function public.audit_log_trigger();

create trigger trg_audit_company_members
  after insert or update or delete on public.company_members
  for each row execute function public.audit_log_trigger();
