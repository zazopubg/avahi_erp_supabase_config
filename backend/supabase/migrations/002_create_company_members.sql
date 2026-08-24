-- ============================================================
-- 002_create_company_members.sql
-- ربط مستخدمي النظام (public.users) بالشركات مع تحديد الدور (role).
-- القيم النصية لعمود role يجب أن تطابق UserRole.name في
-- lib/core/constants/roles.dart (Flutter) تماماً.
-- ============================================================

create table if not exists public.company_members (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references public.companies (id) on delete cascade,
  user_id       uuid not null references public.users (id) on delete cascade,
  role          text not null,
  full_name     text not null,
  phone         text,
  avatar_url    text,
  job_title     text,
  is_active     boolean not null default true,
  joined_at     timestamptz not null default now(),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  -- ⚠️ يجب أن تطابق هذه القيم بالضبط أسماء UserRole في Flutter
  -- (platformOwner مستثنى عمداً؛ يُدار عبر platform_admins).
  constraint company_members_role_check check (
    role in ('worker', 'foreman', 'engineer', 'projectManager', 'admin')
  ),
  constraint company_members_unique_membership unique (company_id, user_id)
);

comment on table public.company_members is 'عضوية المستخدم في شركة محددة مع دوره ضمنها (Tenant-scoped role).';

create trigger trg_company_members_updated_at
  before update on public.company_members
  for each row
  execute function public.set_updated_at();

alter table public.company_members enable row level security;
