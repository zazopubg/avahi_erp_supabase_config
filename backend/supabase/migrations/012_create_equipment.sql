-- ============================================================
-- 012_create_equipment.sql 🆕
-- إدارة المعدات: تتبّع حالتها، من يستخدمها حالياً، وساعات
-- التشغيل التراكمية، وتاريخ آخر صيانة.
-- ============================================================

create table if not exists public.equipment (
  id                     uuid primary key default gen_random_uuid(),
  company_id             uuid not null references public.companies (id) on delete cascade,
  project_id             uuid references public.projects (id) on delete set null,

  name                   text not null,
  name_ar                text,
  type                   text not null,
  serial_number          text,

  status                 text not null default 'available',
  assigned_to            uuid references public.users (id),

  usage_hours            numeric not null default 0,
  purchase_date          date,
  last_maintenance_date  date,
  next_maintenance_due   date,

  notes                  text,
  created_by             uuid references public.users (id),
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),

  constraint equipment_status_check check (
    status in ('available', 'in_use', 'maintenance', 'retired')
  )
);

comment on table public.equipment is 'المعدات الميدانية للشركة: حالتها، من أُسندت إليه، وساعات تشغيلها.';

create trigger trg_equipment_updated_at
  before update on public.equipment
  for each row
  execute function public.set_updated_at();

alter table public.equipment enable row level security;
