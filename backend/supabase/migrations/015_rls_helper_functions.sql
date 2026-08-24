-- ============================================================
-- 015_rls_helper_functions.sql
-- دوال مساعدة تُستخدم داخل سياسات RLS (016_rls_policies.sql).
-- تُعرَّف كـ security definer لكي تستطيع قراءة company_members
-- بمعزل عن سياسات RLS الخاصة بذلك الجدول نفسه (تفادي التكرار
-- اللانهائي recursive RLS).
-- ============================================================

-- ── company_id الخاص بالمستخدم الحالي ─────────────────────────
create or replace function public.current_user_company_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select cm.company_id
  from public.company_members cm
  where cm.user_id = public.current_user_id()
    and cm.is_active = true
  limit 1;
$$;

comment on function public.current_user_company_id() is 'يعيد company_id للمستخدم الحالي المسجل دخوله (JWT)، أو NULL إن لم يكن عضواً نشطاً في أي شركة.';

-- ── دور المستخدم الحالي ضمن شركته ─────────────────────────────
create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select cm.role
  from public.company_members cm
  where cm.user_id = public.current_user_id()
    and cm.is_active = true
  limit 1;
$$;

comment on function public.current_user_role() is 'يعيد دور المستخدم الحالي (worker/foreman/engineer/projectManager/admin) أو NULL.';

-- ── هل المستخدم الحالي مالك منصة (Platform Owner)؟ ──────────
create or replace function public.is_platform_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.platform_admins pa where pa.user_id = public.current_user_id()
  );
$$;

comment on function public.is_platform_owner() is 'صحيح إذا كان المستخدم الحالي مسجّلاً في platform_admins (صلاحية عابرة لكل المستأجرين).';

-- ── ترتيب رقمي للدور، لمقارنات "الحد الأدنى من الصلاحية" ─────
-- ⚠️ يجب أن يطابق ترتيب UserRole.rank في lib/core/constants/roles.dart
create or replace function public.role_rank(role_name text)
returns integer
language sql
immutable
as $$
  select case role_name
    when 'worker'          then 0
    when 'foreman'         then 1
    when 'engineer'        then 2
    when 'projectManager'  then 3
    when 'admin'           then 4
    when 'platformOwner'   then 5
    else -1
  end;
$$;

comment on function public.role_rank(text) is 'يحوّل اسم الدور النصي إلى ترتيبه الرقمي (يطابق UserRole.rank في Flutter).';

-- ── هل يملك المستخدم الحالي رتبة >= الحد الأدنى المطلوب؟ ─────
create or replace function public.has_min_role(min_role text)
returns boolean
language sql
stable
as $$
  select coalesce(public.role_rank(public.current_user_role()) >= public.role_rank(min_role), false)
      or public.is_platform_owner();
$$;

comment on function public.has_min_role(text) is 'صحيح إذا كانت رتبة المستخدم الحالي أعلى أو تساوي min_role، أو إذا كان مالك منصة.';

-- ── هل المستخدم الحالي عضو نشط في مشروع محدد؟ ─────────────────
create or replace function public.is_project_member(target_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.project_members pm
    where pm.project_id = target_project_id
      and pm.user_id = public.current_user_id()
      and pm.is_active = true
  );
$$;

comment on function public.is_project_member(uuid) is 'صحيح إذا كان المستخدم الحالي عضواً نشطاً في المشروع target_project_id.';
