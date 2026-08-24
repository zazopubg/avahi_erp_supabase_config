-- ============================================================
-- 004_create_project_members.sql
-- إسناد أعضاء الشركة (company_members) إلى مشاريع محددة. عضو
-- الشركة قد يُسند لعدة مشاريع في آن واحد.
-- ============================================================

create table if not exists public.project_members (
  id                uuid primary key default gen_random_uuid(),
  project_id        uuid not null references public.projects (id) on delete cascade,
  company_id        uuid not null references public.companies (id) on delete cascade,
  user_id           uuid not null references public.users (id) on delete cascade,
  is_active         boolean not null default true,
  assigned_at       timestamptz not null default now(),
  created_at        timestamptz not null default now(),

  constraint project_members_unique_assignment unique (project_id, user_id)
);

comment on table public.project_members is 'ربط عضو الشركة بمشروع معين لتحديد نطاق رؤيته وعمله.';

alter table public.project_members enable row level security;
