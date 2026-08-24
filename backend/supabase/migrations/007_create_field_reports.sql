-- ============================================================
-- 007_create_field_reports.sql
-- التقارير الميدانية اليومية، مع دعم التوقيع الرقمي (مشرف
-- وعميل) وحقول الطقس التي تُملأ تلقائياً من Weather API لاحقاً
-- (Prompt 17).
-- ============================================================

create table if not exists public.field_reports (
  id                        uuid primary key default gen_random_uuid(),
  company_id                uuid not null references public.companies (id) on delete cascade,
  project_id                uuid not null references public.projects (id) on delete cascade,
  created_by                uuid references public.users (id),

  report_date               date not null default current_date,
  status                    text not null default 'draft',

  weather_condition         text,
  temperature_c             numeric,

  labor_count               integer not null default 0,
  work_performed            text,
  materials_used            text,
  equipment_used            text,
  issues                    text,
  notes                     text,

  supervisor_signature_url  text,
  supervisor_signed_at      timestamptz,
  client_signature_url      text,
  client_signed_at          timestamptz,

  reviewed_by               uuid references public.users (id),
  reviewed_at                timestamptz,
  rejection_reason           text,

  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),

  constraint field_reports_status_check check (
    status in ('draft', 'submitted', 'reviewed', 'rejected')
  )
);

comment on table public.field_reports is 'التقارير الميدانية اليومية بحالتها ودورة اعتمادها (draft→submitted→reviewed/rejected).';
comment on column public.field_reports.supervisor_signature_url is 'مسار توقيع المشرف الرقمي في خدمة تخزين الملفات (Object Storage).';
comment on column public.field_reports.client_signature_url is 'مسار توقيع العميل الرقمي في خدمة تخزين الملفات (Object Storage).';

create trigger trg_field_reports_updated_at
  before update on public.field_reports
  for each row
  execute function public.set_updated_at();

alter table public.field_reports enable row level security;
