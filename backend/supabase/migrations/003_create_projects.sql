-- ============================================================
-- 003_create_projects.sql
-- المشاريع الإنشائية التابعة لكل شركة. تحتوي أيضاً على إحداثيات
-- الجيوفنسينغ الافتراضية (نصف قطر تسجيل الحضور) لموقع المشروع.
-- ============================================================

create table if not exists public.projects (
  id                      uuid primary key default gen_random_uuid(),
  company_id              uuid not null references public.companies (id) on delete cascade,
  name                    text not null,
  name_ar                 text,
  code                    text,
  client_name             text,
  address                 text,
  latitude                double precision,
  longitude               double precision,
  geofence_radius_meters  numeric not null default 150,
  start_date              date,
  end_date                date,
  status                  text not null default 'active',
  description             text,
  created_by              uuid references public.users (id),
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  constraint projects_status_check check (
    status in ('active', 'on_hold', 'completed', 'archived')
  ),
  constraint projects_company_code_unique unique (company_id, code)
);

comment on table public.projects is 'مشاريع الشركة، وتحمل مركز الجيوفنسينغ الافتراضي لتسجيل الحضور.';

create trigger trg_projects_updated_at
  before update on public.projects
  for each row
  execute function public.set_updated_at();

alter table public.projects enable row level security;
