-- ============================================================
-- 005_create_tasks.sql
-- المهام ضمن المشروع (لوحة Kanban لاحقاً في Prompt 16).
-- ============================================================

create table if not exists public.tasks (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references public.companies (id) on delete cascade,
  project_id      uuid not null references public.projects (id) on delete cascade,
  title           text not null,
  description     text,
  status          text not null default 'todo',
  priority        text not null default 'medium',
  assigned_to     uuid references public.users (id),
  created_by      uuid references public.users (id),
  due_date        date,
  kanban_order    integer not null default 0,
  completed_at    timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint tasks_status_check check (
    status in ('todo', 'in_progress', 'review', 'done', 'blocked')
  ),
  constraint tasks_priority_check check (
    priority in ('low', 'medium', 'high', 'urgent')
  )
);

comment on table public.tasks is 'مهام المشروع مع دعم ترتيب لوحة Kanban عبر kanban_order.';

create trigger trg_tasks_updated_at
  before update on public.tasks
  for each row
  execute function public.set_updated_at();

alter table public.tasks enable row level security;
