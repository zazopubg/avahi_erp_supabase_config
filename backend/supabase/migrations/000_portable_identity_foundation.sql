-- ============================================================
-- 000_portable_identity_foundation.sql
-- طبقة تجريد قياسية (Standard Abstraction Layer) — الهدف منها
-- فصل سلسلة الهجرات 001→020 عن أي مزود سحابي محدد (مثل Supabase)
-- وجعلها قابلة للتنفيذ بنجاح على أي PostgreSQL حديث (RDS، Cloud
-- SQL، Neon، Azure Database for PostgreSQL، أو خادم مُدار ذاتياً).
--
-- لماذا هذا الملف ضروري:
--  • كانت الهجرات الأصلية تُشير مباشرة إلى auth.users وتستدعي
--    دوال داخلية عبر auth.uid()، وهذان الكائنان يُنشئان ويُديران
--    تلقائياً بواسطة خدمة Supabase Auth تحديداً، وغير موجودين على
--    أي PostgreSQL قياسي آخر.
--  • الأخطر: مخطط (schema) باسم auth محجوز ومملوك لحساب خدمة
--    Supabase الداخلي؛ محاولة إنشاء جداول أو دوال بداخله من
--    مستخدم تطبيق عادي تفشل عادةً بخطأ صلاحيات (permission denied
--    for schema auth) — وهو بالضبط نوع "أخطاء الصلاحيات" المطلوب
--    إزالتها لضمان تنفيذ مباشر وناجح على أي مزود.
--
-- الحل المعتمد:
--  1) استبدال كل إشارة إلى auth.users بجدول public.users مملوك
--     بالكامل لتطبيق Avahi، فتُنشأ الهجرة بلا أي صلاحيات خاصة.
--  2) استبدال auth.uid() بدالة public.current_user_id() التي تقرأ
--     هوية المستخدم الحالي من متغيّر جلسة (Session GUC) قياسي:
--       - request.jwt.claim.sub  → الاصطلاح الذي يعتمده PostgREST
--         (تستخدمه Supabase ومزودون آخرون متوافقون مع PostgREST)
--       - app.current_user_id    → متغيّر بديل عام يمكن لأي طبقة
--         تطبيق (Node/NestJS، Django، إلخ) ضبطه يدوياً عبر
--         set_config('app.current_user_id', '<uuid>', true)
--     هذا يجعل نفس منطق RLS يعمل سواء خلف PostgREST/Supabase أو
--     خلف أي خادم تطبيق مخصص يضبط متغيّر الجلسة بنفسه.
--  3) عند النشر الفعلي على Supabase، يبقى بالإمكان مزامنة
--     auth.users → public.users عبر Trigger اختياري في طبقة
--     Supabase نفسها (خارج نطاق هذه الهجرات القياسية)، أو الاستمرار
--     في إدارة الهوية محلياً في public.users مباشرة إن لم تُستخدم
--     خدمة Supabase Auth إطلاقاً.
-- ============================================================

create extension if not exists "pgcrypto";

-- ── جدول الهوية القياسي (Identity) ─────────────────────────────
-- يحل محل auth.users كمرجع أساسي (Foreign Key target) لكل بقية
-- الجداول. لا يفترض وجود أي خدمة مصادقة محددة.
create table if not exists public.users (
  id                  uuid primary key default gen_random_uuid(),
  email               text unique,
  full_name           text,
  is_active           boolean not null default true,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on table public.users is
  'جدول الهوية القياسي (Identity) لمستخدمي Avahi، مستقل عن أي مزود مصادقة محدد. يُستخدم كمرجع (FK) موحّد بدل الاعتماد على مخطط auth الداخلي لأي خدمة سحابية.';

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_users_updated_at
  before update on public.users
  for each row
  execute function public.set_updated_at();

-- ── دالة الحصول على هوية المستخدم الحالي (بديل قياسي لـ auth.uid()) ─
-- تُعرَّف داخل public لتفادي أي حاجة لصلاحيات على مخطط auth
-- المحجوز. تقرأ القيمة من متغيّر جلسة (GUC) قياسي في PostgreSQL،
-- وليس من امتداد أو دالة خاصة بمزود واحد.
create or replace function public.current_user_id()
returns uuid
language plpgsql
stable
as $$
declare
  v_claim text;
begin
  -- الأولوية لاصطلاح PostgREST القياسي (تعتمده Supabase وغيرها)
  v_claim := nullif(current_setting('request.jwt.claim.sub', true), '');

  -- بديل عام لأي طبقة تطبيق تضبط متغيّر الجلسة يدوياً
  if v_claim is null then
    v_claim := nullif(current_setting('app.current_user_id', true), '');
  end if;

  if v_claim is null then
    return null;
  end if;

  return v_claim::uuid;
exception
  when others then
    return null;
end;
$$;

comment on function public.current_user_id() is
  'بديل قياسي لدالة auth.uid() الخاصة بـ Supabase. يعيد UUID المستخدم الحالي من متغيّر جلسة قياسي (request.jwt.claim.sub أو app.current_user_id)، ويعمل على أي PostgreSQL دون أي امتداد خاص بمزود.';

alter table public.users enable row level security;

-- سياسة قراءة أساسية: كل مستخدم يرى سجل نفسه فقط بشكل افتراضي.
-- (سياسات أوسع نطاقاً على الشركات/الأعضاء تُضاف لاحقاً في
-- 016_rls_policies.sql بعد تعريف دوال الأدوار في 015).
create policy users_select_self on public.users
  for select using (id = public.current_user_id());

create policy users_update_self on public.users
  for update using (id = public.current_user_id());
