-- ============================================================
-- 006_create_attendance.sql
-- تسجيل الحضور والانصراف مع دعم:
--  • idempotency عبر client_mutation_id (UUID فريد من الجهاز
--    نفسه) لضمان عدم تكرار السجل عند إعادة المزامنة (retry).
--  • التحقق من الموقع الجغرافي (geofence_valid) الذي يُحسب
--    غالباً في طبقة الخدمة (Backend Function) عبر معادلة Haversine.
--  • طريقتان لتسجيل الحضور: gps أو qr.
-- ============================================================

create table if not exists public.attendance (
  id                    uuid primary key default gen_random_uuid(),
  company_id            uuid not null references public.companies (id) on delete cascade,
  project_id            uuid not null references public.projects (id) on delete cascade,
  user_id               uuid not null references public.users (id) on delete cascade,

  -- معرّف التزامن الفريد المُنشأ من جهاز العميل (offline-first)
  client_mutation_id    uuid not null,

  check_in_at           timestamptz not null default now(),
  check_out_at          timestamptz,

  check_in_latitude     double precision,
  check_in_longitude    double precision,
  check_out_latitude    double precision,
  check_out_longitude   double precision,

  -- نتيجة التحقق الجغرافي (محسوبة عبر Haversine في Edge Function)
  geofence_valid        boolean not null default false,
  distance_meters        numeric,

  check_method           text not null default 'gps',
  qr_code_id              text,

  status                text not null default 'pending',
  notes                 text,
  approved_by           uuid references public.users (id),
  approved_at           timestamptz,

  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),

  constraint attendance_check_method_check check (check_method in ('gps', 'qr')),
  constraint attendance_status_check check (
    status in ('pending', 'approved', 'rejected')
  ),
  -- ⚠️ عمود المزامنة الأهم: يمنع قاعدة البيانات من إنشاء سجل مكرر عند
  -- إعادة إرسال نفس الطفرة (upsert on-conflict-do-nothing).
  constraint attendance_client_mutation_id_unique unique (client_mutation_id)
);

comment on table public.attendance is 'سجلات الحضور والانصراف؛ client_mutation_id يضمن idempotency عند المزامنة من العمل دون اتصال.';
comment on column public.attendance.client_mutation_id is 'UUID يُولَّد على الجهاز محلياً قبل الإرسال؛ يُستخدم مع upsert on-conflict-do-nothing لمنع التكرار.';

create trigger trg_attendance_updated_at
  before update on public.attendance
  for each row
  execute function public.set_updated_at();

alter table public.attendance enable row level security;
