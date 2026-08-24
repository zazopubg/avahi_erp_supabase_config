-- ============================================================
-- 011_create_audit_logs.sql
-- سجل تدقيق عام (Audit Trail) يُملأ تلقائياً عبر triggers لكل
-- الجداول الحساسة (انظر 017_audit_triggers.sql).
-- ============================================================

create table if not exists public.audit_logs (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid references public.companies (id) on delete cascade,
  user_id       uuid references public.users (id),

  action        text not null,
  table_name    text not null,
  record_id     uuid,

  old_data      jsonb,
  new_data      jsonb,

  created_at    timestamptz not null default now(),

  constraint audit_logs_action_check check (
    action in ('INSERT', 'UPDATE', 'DELETE')
  )
);

comment on table public.audit_logs is 'سجل تدقيق عام يُغذّى تلقائياً عبر triggers audit_triggers على الجداول الحساسة؛ للقراءة فقط.';

alter table public.audit_logs enable row level security;
