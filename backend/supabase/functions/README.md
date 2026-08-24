# backend/supabase/functions — Edge Functions (Prompt 04)

دوال Deno/TypeScript تعمل على Supabase Edge Runtime. كل دالة مستقلة
في مجلدها الخاص (`index.ts`)، وتشترك جميعها في أدوات `_shared/`:

| ملف                        | الغرض                                                              |
|-----------------------------|---------------------------------------------------------------------|
| `_shared/cors.ts`           | رؤوس CORS موحّدة + معالجة طلبات OPTIONS                              |
| `_shared/response.ts`       | أشكال استجابة JSON موحّدة (نجاح/خطأ) عبر كل الدوال                    |
| `_shared/supabase-admin.ts` | عميل Supabase بصلاحية `service_role` (يتجاوز RLS، للخادم فقط)         |
| `_shared/auth.ts`           | التحقق من JWT، الدور، `platform_admins`، والأسرار المشتركة (webhooks/cron) |
| `_shared/geo.ts`            | معادلة Haversine لحساب المسافة بالأمتار (الجيوفنسينغ)                 |

## جدول الدوال

| الدالة                    | من يستدعيها                              | المصادقة                              |
|----------------------------|-------------------------------------------|-----------------------------------------|
| `create-company`          | لوحة إدارة المنصة (platformOwner)         | JWT مستخدم + عضوية `platform_admins`   |
| `sync-user-claims`        | Database Webhook على `company_members`    | رأس `x-webhook-secret`                 |
| `attendance-guard`        | تطبيق Flutter (بدل الكتابة المباشرة)      | JWT مستخدم عضو نشط في شركة              |
| `report-notifications`    | Database Webhook على `field_reports`      | رأس `x-webhook-secret`                 |
| `equipment-alert`         | مهمة مجدولة (cron) أو استدعاء يدوي إداري  | رأس `x-cron-secret` أو JWT admin/PM+   |
| `leave-request-notify`    | Database Webhook على `leave_requests`     | رأس `x-webhook-secret`                 |
| `soft-delete-tenant`      | لوحة إدارة المنصة (platformOwner)         | JWT مستخدم + عضوية `platform_admins`   |

## إعداد Database Webhooks (Supabase Studio → Database → Webhooks)

لكل من `sync-user-claims`, `report-notifications`, `leave-request-notify`:

1. **Table**: `company_members` / `field_reports` / `leave_requests` على التوالي.
2. **Events**: `INSERT`, `UPDATE` (كما هو محدَّد في تعليق أعلى كل ملف).
3. **Type**: `HTTP Request` → `POST` إلى
   `https://<project-ref>.functions.supabase.co/<function-name>`
   (أو `http://kong:8000/functions/v1/<function-name>` محلياً عبر docker-compose).
4. **HTTP Headers**: أضف `x-webhook-secret: <قيمة DB_WEBHOOK_SECRET>`.

## إعداد المهمة المجدولة لـ `equipment-alert`

- **محلياً**: يمكن استدعاؤها يدوياً، أو جدولتها عبر `pg_cron` داخل حاوية
  `db` (imageless — تحتاج تفعيل الإضافة `pg_cron` إن رغبت بالجدولة من
  داخل قاعدة البيانات نفسها)، أو عبر أي مجدول خارجي (`cron`, GitHub
  Actions، إلخ) يستدعي الدالة يومياً مع رأس `x-cron-secret`.
- **في الإنتاج (Supabase Cloud)**: استخدم Supabase Scheduled Functions
  (Cron Jobs) من لوحة التحكم، بجدولة يومية (مثلاً `0 6 * * *`) مع
  تمرير نفس رأس `x-cron-secret`.

## المتغيرات البيئية المطلوبة

راجع `backend/.env.example` — أهمها: `SUPABASE_URL`,
`SUPABASE_SERVICE_ROLE_KEY` (تُحقنان تلقائياً من منصة Supabase أو من
`docker-compose.yml` محلياً)، `DB_WEBHOOK_SECRET`, `CRON_SECRET`،
وثلاثة متغيرات ضبط اختيارية لـ `equipment-alert`.

## اختبار محلي سريع (بعد `docker compose up`)

```bash
# تسجيل حضور تجريبي (استبدل <JWT> بتوكن أحد مستخدمي seed، مثال worker1@avahi.dev)
curl -X POST http://localhost:54321/functions/v1/attendance-guard \
  -H "Authorization: Bearer <JWT>" \
  -H "Content-Type: application/json" \
  -d '{
        "action": "check_in",
        "project_id": "33333333-3333-3333-3333-333333333301",
        "client_mutation_id": "aaaaaaaa-1111-2222-3333-444444444444",
        "latitude": 33.2896,
        "longitude": 44.3894,
        "check_method": "gps"
      }'

# فحص تنبيهات صيانة المعدات يدوياً (يتوقع تنبيهين من بيانات seed)
curl -X POST http://localhost:54321/functions/v1/equipment-alert \
  -H "x-cron-secret: <قيمة CRON_SECRET>" \
  -H "Content-Type: application/json" \
  -d '{}'
```
