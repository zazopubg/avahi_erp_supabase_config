-- ============================================================
-- 013_create_notifications.sql 🆕
-- الإشعارات داخل التطبيق (In-app Notifications) لكل مستخدم،
-- مرتبطة اختيارياً بكيان محدد عبر related_entity_id.
-- ============================================================

create table if not exists public.notifications (
  id                     uuid primary key default gen_random_uuid(),
  company_id             uuid not null references public.companies (id) on delete cascade,
  user_id                uuid not null references public.users (id) on delete cascade,

  title                  text not null,
  body                   text,
  type                   text not null default 'general',

  related_entity_type    text,
  related_entity_id      uuid,

  is_read                boolean not null default false,
  read_at                timestamptz,

  created_at             timestamptz not null default now(),

  constraint notifications_type_check check (
    type in (
      'general', 'task_assigned', 'attendance_approved', 'attendance_rejected',
      'field_report_reviewed', 'leave_request_reviewed', 'punch_item_assigned',
      'equipment_assigned', 'document_uploaded'
    )
  )
);

comment on table public.notifications is 'إشعارات داخل التطبيق لكل مستخدم، مع نوع مصنّف وربط اختياري بكيان مصدر الإشعار.';

alter table public.notifications enable row level security;
