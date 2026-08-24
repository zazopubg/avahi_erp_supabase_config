-- ============================================================
-- 020_create_project_milestones.sql
-- 🆕 (Prompt 20) المراحل الرئيسية (Milestones) لكل مشروع —
-- جدول جديد بالكامل يدعم `features/projects/` (project_milestones.dart،
-- project_overview.dart). بخلاف 019_extend_notification_types.sql
-- (تعديل قيد على جدول قائم)، هذه الهجرة تُنشئ جدولاً جديداً كاملاً
-- بنفس بنية 001-014 (جدول + RLS + Trigger مجمّعة في ملف واحد، لأن
-- الجدول لاحق لتجميع 016/017/018 المركزي الأصلي).
-- ============================================================

create table if not exists public.project_milestones (
  id                 uuid primary key default gen_random_uuid(),
  company_id         uuid not null references public.companies (id) on delete cascade,
  project_id         uuid not null references public.projects (id) on delete cascade,

  title              text not null,
  title_ar           text,
  description        text,

  due_date           date,
  completed_at       timestamptz,
  status             text not null default 'pending',
  progress_percent   integer not null default 0,

  created_by         uuid references public.users (id),
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),

  constraint project_milestones_status_check check (
    status in ('pending', 'in_progress', 'completed', 'delayed')
  ),
  constraint project_milestones_progress_check check (
    progress_percent >= 0 and progress_percent <= 100
  )
);

comment on table public.project_milestones is 'المراحل الرئيسية (Milestones) للجدول الزمني لكل مشروع، مع نسبة إنجاز وتاريخ استحقاق.';

create trigger trg_project_milestones_updated_at
  before update on public.project_milestones
  for each row
  execute function public.set_updated_at();

alter table public.project_milestones enable row level security;

-- ─────────────────────────────────────────────────────────────
-- سياسات RLS — بنفس نطاق project_members (016_rls_policies.sql):
-- القراءة لأي عضو شركة نشط، الكتابة (إنشاء/تعديل/حذف) لدور
-- projectManager فما فوق فقط.
-- ─────────────────────────────────────────────────────────────
create policy project_milestones_select on public.project_milestones
  for select using (
    company_id = public.current_user_company_id() or public.is_platform_owner()
  );

create policy project_milestones_write on public.project_milestones
  for all using (
    (company_id = public.current_user_company_id() and public.has_min_role('projectManager'))
    or public.is_platform_owner()
  )
  with check (
    (company_id = public.current_user_company_id() and public.has_min_role('projectManager'))
    or public.is_platform_owner()
  );

create index if not exists idx_project_milestones_project_id
  on public.project_milestones (project_id);

create index if not exists idx_project_milestones_due_date
  on public.project_milestones (due_date);
