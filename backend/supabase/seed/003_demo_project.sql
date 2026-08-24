-- ============================================================
-- 003_demo_project.sql
-- مشروع نشط واحد تابع للشركة التجريبية، بإحداثيات جغرافية حقيقية
-- (موقع تقريبي في بغداد) ونصف قطر جيوفنسينغ افتراضي 150 متراً،
-- مع إسناد كل المستخدمين الستة إليه كأعضاء مشروع نشطين.
-- ============================================================

insert into public.projects (
  id, company_id, name, name_ar, code, client_name, address,
  latitude, longitude, geofence_radius_meters,
  start_date, end_date, status, description, created_by
) values (
  '33333333-3333-3333-3333-333333333301',
  '11111111-1111-1111-1111-111111111111',
  'Al-Jadriya Tower Project',
  'مشروع برج الجادرية',
  'PRJ-2026-001',
  'شركة العقارات الحديثة',
  'بغداد، حي الجادرية، قرب جسر الجادرية',
  33.28960,
  44.38940,
  150,
  current_date - interval '45 days',
  current_date + interval '180 days',
  'active',
  'إنشاء برج سكني/تجاري من 12 طابقاً، يشمل أعمال هيكلية وتشطيبات وأنظمة كهروميكانيكية.',
  '22222222-2222-2222-2222-222222222205' -- مدير المشروع
)
on conflict (id) do nothing;

insert into public.project_members (project_id, company_id, user_id, is_active)
select
  '33333333-3333-3333-3333-333333333301',
  '11111111-1111-1111-1111-111111111111',
  user_id,
  true
from public.company_members
where company_id = '11111111-1111-1111-1111-111111111111'
on conflict (project_id, user_id) do nothing;
