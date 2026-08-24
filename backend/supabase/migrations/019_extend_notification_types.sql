-- ============================================================
-- 019_extend_notification_types.sql
-- (Prompt 04) توسيع القيم المسموحة في notifications.type لدعم
-- الإشعارات التي تُنشئها Edge Functions الجديدة:
--   • field_report_submitted   → report-notifications عند التقديم
--   • equipment_maintenance_due → equipment-alert عند استحقاق صيانة
--   • leave_request_submitted  → leave-request-notify عند تقديم طلب جديد
--
-- ⚠️ لا نعدّل جدول 013_create_notifications.sql الأصلي مباشرة لأنه
-- قد يكون طُبِّق فعلياً على بيئات سابقة؛ التعديل على قيود CHECK
-- الموجودة يتم دوماً عبر migration جديدة (drop + add) حفاظاً على
-- سجل الهجرات (migration history) قابلاً لإعادة التشغيل بأمان.
-- ============================================================

alter table public.notifications
  drop constraint if exists notifications_type_check;

alter table public.notifications
  add constraint notifications_type_check check (
    type in (
      'general',
      'task_assigned',
      'attendance_approved',
      'attendance_rejected',
      'field_report_submitted',
      'field_report_reviewed',
      'leave_request_submitted',
      'leave_request_reviewed',
      'punch_item_assigned',
      'equipment_assigned',
      'equipment_maintenance_due',
      'document_uploaded'
    )
  );

comment on constraint notifications_type_check on public.notifications is
  'محدَّث في Prompt 04: يضيف field_report_submitted / equipment_maintenance_due / leave_request_submitted لدعم Edge Functions.';
