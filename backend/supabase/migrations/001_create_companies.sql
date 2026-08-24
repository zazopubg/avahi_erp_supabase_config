-- ============================================================
-- 001_create_companies.sql
-- الجدول الجذري لكل مستأجر (Tenant) في النظام. كل الجداول
-- اللاحقة تُشير إلى company_id لعزل بيانات كل شركة عن غيرها.
-- ============================================================

-- ملاحظة: امتداد pgcrypto ودالة public.set_updated_at() و public.users
-- تم تعريفها مسبقاً في 000_portable_identity_foundation.sql (طبقة
-- التجريد القياسية). لا حاجة لإعادة تعريفها هنا.

create table if not exists public.companies (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  name_ar       text,
  slug          text not null unique,
  logo_url      text,
  address       text,
  phone         text,
  timezone      text not null default 'Asia/Baghdad',
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  constraint companies_slug_format check (slug ~ '^[a-z0-9-]+$')
);

comment on table public.companies is 'الشركات/المستأجرون (Tenants) في نظام Avahi متعدد المستأجرين.';

-- تحديث updated_at تلقائياً عند أي تعديل (الدالة معرّفة في 000)
create trigger trg_companies_updated_at
  before update on public.companies
  for each row
  execute function public.set_updated_at();

-- ============================================================
-- سجل مالكي المنصة (Platform Owners) — منفصل عمداً عن
-- company_members لأن مالك المنصة ليس عضواً في شركة واحدة بل
-- يملك صلاحية عابرة لكل المستأجرين (Prompt 28: platform_admin).
-- ============================================================
create table if not exists public.platform_admins (
  user_id     uuid primary key references public.users (id) on delete cascade,
  full_name   text,
  created_at  timestamptz not null default now()
);

comment on table public.platform_admins is 'قائمة المستخدمين الذين يملكون صلاحية platformOwner العابرة لكل الشركات.';

alter table public.companies enable row level security;
alter table public.platform_admins enable row level security;
