-- ============================================================
-- 002_demo_users.sql
-- 6 مستخدمين تجريبيين بأدوار مختلفة، جميعهم أعضاء نشطون في
-- الشركة التجريبية (Demo Construction Co.).
--
-- التوزيع: عاملان (worker) + رئيس عمال (foreman) + مهندس
-- (engineer) + مدير مشروع (projectManager) + مدير نظام (admin).
--
-- ⚠️ ملاحظة توافق: تماماً كما في 001_demo_company.sql، لم يعد هذا
-- الملف يُنشئ حسابات دخول فعلية عبر auth.users/auth.identities
-- الخاصة بـ Supabase Auth (ولا يُخزّن أي كلمة مرور)، بل يكتفي
-- بإدراج المستخدمين الستة في الجدول القياسي public.users مباشرة،
-- ثم ربطهم بالشركة التجريبية عبر company_members. إنشاء حسابات
-- دخول حقيقية بكلمات مرور يتم عبر طبقة المصادقة الخارجية المستخدمة
-- في بيئة النشر الفعلية (خارج نطاق هذه الهجرات).
-- ============================================================

do $$
declare
  v_ids uuid[] := array[
    '22222222-2222-2222-2222-222222222201', -- عامل 1
    '22222222-2222-2222-2222-222222222202', -- عامل 2
    '22222222-2222-2222-2222-222222222203', -- رئيس عمال
    '22222222-2222-2222-2222-222222222204', -- مهندس موقع
    '22222222-2222-2222-2222-222222222205', -- مدير مشروع
    '22222222-2222-2222-2222-222222222206'  -- مدير نظام (Tenant Admin)
  ];
  v_emails text[] := array[
    'worker1@avahi.dev',
    'worker2@avahi.dev',
    'foreman@avahi.dev',
    'engineer@avahi.dev',
    'pm@avahi.dev',
    'admin@avahi.dev'
  ];
  v_names text[] := array[
    'أحمد كريم (عامل)',
    'سالم جبار (عامل)',
    'محمد رزاق (رئيس عمال)',
    'نور حسين (مهندسة موقع)',
    'علي عبد الله (مدير مشروع)',
    'زينب صادق (مدير نظام)'
  ];
  v_roles text[] := array['worker', 'worker', 'foreman', 'engineer', 'projectManager', 'admin'];
  v_titles text[] := array['عامل بناء', 'عامل بناء', 'رئيس عمال موقع', 'مهندسة مدنية', 'مدير مشاريع', 'مدير نظام'];
  i int;
begin
  for i in 1 .. array_length(v_ids, 1) loop
    insert into public.users (id, email, full_name, is_active)
    values (v_ids[i], v_emails[i], v_names[i], true)
    on conflict (id) do nothing;

    insert into public.company_members (
      company_id, user_id, role, full_name, job_title, is_active
    ) values (
      '11111111-1111-1111-1111-111111111111',
      v_ids[i],
      v_roles[i],
      v_names[i],
      v_titles[i],
      true
    )
    on conflict (company_id, user_id) do nothing;
  end loop;
end $$;
