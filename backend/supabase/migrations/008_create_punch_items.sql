-- ============================================================
-- 008_create_punch_items.sql
-- قوائم الملاحظات (Punch List) — عناصر تحتاج إصلاحاً/إغلاقاً
-- قبل تسليم المشروع، وقد ترتبط اختيارياً بتقرير ميداني.
-- ============================================================

create table if not exists public.punch_items (
  id                uuid primary key default gen_random_uuid(),
  company_id        uuid not null references public.companies (id) on delete cascade,
  project_id        uuid not null references public.projects (id) on delete cascade,
  field_report_id   uuid references public.field_reports (id) on delete set null,

  title             text not null,
  description       text,
  location_note     text,

  status            text not null default 'open',
  priority          text not null default 'medium',

  assigned_to       uuid references public.users (id),
  created_by        uuid references public.users (id),

  due_date          date,
  resolved_at       timestamptz,
  resolved_by       uuid references public.users (id),
  closed_at         timestamptz,
  closed_by         uuid references public.users (id),

  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint punch_items_status_check check (
    status in ('open', 'in_progress', 'resolved', 'closed')
  ),
  constraint punch_items_priority_check check (
    priority in ('low', 'medium', 'high', 'urgent')
  )
);

comment on table public.punch_items is 'عناصر قائمة الملاحظات (Punch List) لكل مشروع، بحالة تتبّع من الفتح حتى الإغلاق.';

create trigger trg_punch_items_updated_at
  before update on public.punch_items
  for each row
  execute function public.set_updated_at();

alter table public.punch_items enable row level security;
