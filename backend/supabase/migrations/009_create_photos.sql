-- ============================================================
-- 009_create_photos.sql
-- الصور المرفقة بأي كيان في النظام (تقرير ميداني، عنصر ملاحظات،
-- مهمة...) عبر نمط polymorphic خفيف (related_entity_type/id).
-- ============================================================

create table if not exists public.photos (
  id                     uuid primary key default gen_random_uuid(),
  company_id             uuid not null references public.companies (id) on delete cascade,
  project_id             uuid references public.projects (id) on delete cascade,

  related_entity_type    text not null,
  related_entity_id      uuid not null,

  storage_path           text not null,
  thumbnail_path         text,
  caption                text,
  file_size_bytes        bigint,

  taken_at               timestamptz not null default now(),
  latitude               double precision,
  longitude              double precision,

  uploaded_by            uuid references public.users (id),
  created_at             timestamptz not null default now(),

  constraint photos_related_entity_type_check check (
    related_entity_type in (
      'field_report', 'punch_item', 'task', 'attendance', 'equipment', 'project'
    )
  )
);

comment on table public.photos is 'صور مرفقة بأي كيان عبر related_entity_type/related_entity_id (polymorphic association).';

alter table public.photos enable row level security;
