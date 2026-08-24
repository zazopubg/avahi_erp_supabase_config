-- ============================================================
-- 014_create_leave_requests.sql 🆕
-- طلبات الإجازة: يقدّمها الموظف ويعتمدها/يرفضها المسؤول المباشر.
-- ============================================================

create table if not exists public.leave_requests (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references public.companies (id) on delete cascade,
  user_id         uuid not null references public.users (id) on delete cascade,

  leave_type      text not null default 'annual',
  start_date      date not null,
  end_date        date not null,
  reason          text,

  status          text not null default 'pending',
  reviewed_by     uuid references public.users (id),
  reviewed_at     timestamptz,
  review_note     text,

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint leave_requests_status_check check (
    status in ('pending', 'approved', 'rejected', 'cancelled')
  ),
  constraint leave_requests_type_check check (
    leave_type in ('annual', 'sick', 'emergency', 'unpaid', 'other')
  ),
  constraint leave_requests_date_order_check check (end_date >= start_date)
);

comment on table public.leave_requests is 'طلبات إجازة الموظفين بدورة اعتماد (pending→approved/rejected/cancelled).';

create trigger trg_leave_requests_updated_at
  before update on public.leave_requests
  for each row
  execute function public.set_updated_at();

alter table public.leave_requests enable row level security;
