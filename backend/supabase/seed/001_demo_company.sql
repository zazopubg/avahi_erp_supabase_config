-- ============================================================
-- 001_demo_company.sql
-- بيانات تجريبية (Seed) — تعمل على أي PostgreSQL قياسي (وليست
-- مقيدة بـ `supabase db reset` بعد الآن). تُطبَّق محلياً فقط
-- عبر docker-compose.yml أو أي سكربت تهيئة تطوير، ولا تُطبَّق أبداً
-- على بيئة إنتاج حقيقية.
--
-- ينشئ:
--  • مستخدم مالك منصة (Platform Owner) واحد لاختبار /create-company
--    و /soft-delete-tenant.
--  • شركة تجريبية واحدة (Demo Construction Co.) لتُبنى عليها بقية
--    ملفات الـ seed (002..005).
--
-- ⚠️ ملاحظة توافق: بعد اعتماد طبقة التجريد القياسية
-- (000_portable_identity_foundation.sql)، لم تعد بيانات المستخدم
-- (بريد إلكتروني، كلمة مرور مشفّرة، هويات تسجيل الدخول...) تُدار
-- داخل قاعدة البيانات نفسها عبر auth.users/auth.identities الخاصة
-- بـ Supabase Auth. إدارة كلمات المرور والمصادقة الفعلية أصبحت
-- مسؤولية طبقة المصادقة الخارجية المستخدمة في كل بيئة (Supabase
-- Auth، Auth0، Keycloak، خدمة JWT مخصصة...)، وهذا الملف يكتفي بملء
-- الجدول المرآة المحلي public.users الذي تعتمد عليه كل الـ Foreign
-- Keys وسياسات RLS، بمعزل تام عن أي مزود مصادقة محدد.
--
-- لاختبار RLS محلياً مع هذا المستخدم التجريبي داخل معاملة (transaction):
--   begin;
--   set local app.current_user_id = '00000000-0000-0000-0000-000000000001';
--   -- ... استعلامات الاختبار هنا ...
--   commit;
-- ============================================================

-- ── مستخدم مالك المنصة في الجدول القياسي public.users ─────────
insert into public.users (id, email, full_name, is_active)
values (
  '00000000-0000-0000-0000-000000000001',
  'owner@avahi.dev',
  'مالك المنصة التجريبي',
  true
)
on conflict (id) do nothing;

insert into public.platform_admins (user_id, full_name)
values ('00000000-0000-0000-0000-000000000001', 'مالك المنصة التجريبي')
on conflict (user_id) do nothing;

-- ── الشركة التجريبية ────────────────────────────────────────
insert into public.companies (
  id, name, name_ar, slug, address, phone, timezone, is_active
) values (
  '11111111-1111-1111-1111-111111111111',
  'Demo Construction Co.',
  'شركة الإعمار التجريبية',
  'demo-construction',
  'بغداد، حي الجادرية، مبنى 12',
  '+9647700000000',
  'Asia/Baghdad',
  true
)
on conflict (id) do nothing;
