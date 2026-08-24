-- ============================================================
-- 010_create_documents.sql
-- المستندات الرسمية (عقود، مخططات، تصاريح...) التابعة للشركة
-- أو لمشروع محدد اختيارياً، مع دعم الأرشفة والإصدارات البسيطة.
-- ============================================================

create table if not exists public.documents (
  id                  uuid primary key default gen_random_uuid(),
  company_id          uuid not null references public.companies (id) on delete cascade,
  project_id          uuid references public.projects (id) on delete cascade,

  title               text not null,
  description         text,
  category            text,

  storage_path        text not null,
  file_type           text,
  file_size_bytes     bigint,
  version             integer not null default 1,
  previous_version_id uuid references public.documents (id),

  is_archived         boolean not null default false,
  uploaded_by         uuid references public.users (id),

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on table public.documents is 'مستندات الشركة/المشروع مع دعم أرشفة وربط الإصدارات (previous_version_id).';

create trigger trg_documents_updated_at
  before update on public.documents
  for each row
  execute function public.set_updated_at();

alter table public.documents enable row level security;
