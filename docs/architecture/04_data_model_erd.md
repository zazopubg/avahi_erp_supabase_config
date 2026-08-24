# 04 — نموذج البيانات (ERD نصي)

هذا الملف يوثّق مخطط قاعدة البيانات الكامل كما هو مُعرَّف في
`backend/supabase/migrations/001` → `020`. كل جدول مُعزول متعدد المستأجرين
عبر عمود `company_id` (باستثناء `platform_admins` و`audit_logs` الجزئي)،
ومحمي بسياسات RLS مطابقة تماماً — انظر
[docs/security/rls_policies.md](../security/rls_policies.md).

## مخطط العلاقات (نظرة مبسّطة)

```
auth.users (Supabase Auth، خارج تحكمنا المباشر)
    │
    ├──1:1── profiles (اسم كامل فقط، خفيف)
    ├──0:1── platform_admins (عابر لكل الشركات)
    │
    └──N:M── companies  (عبر company_members)
                 │
                 ├──1:N── projects
                 │           ├──1:N── project_members (N:M مع users)
                 │           ├──1:N── project_milestones
                 │           ├──1:N── tasks
                 │           ├──1:N── attendance
                 │           ├──1:N── field_reports ──1:N── punch_items (اختياري)
                 │           ├──0:N── punch_items (مباشرة أيضاً، بلا field_report)
                 │           ├──0:N── photos (عبر related_entity_type/id متعدد الأشكال)
                 │           ├──0:N── documents
                 │           └──0:N── equipment (تعيين اختياري لمشروع)
                 │
                 ├──1:N── equipment (على مستوى الشركة، تعيين اختياري لمشروع)
                 ├──1:N── notifications (لكل مستخدم)
                 ├──1:N── leave_requests (لكل مستخدم)
                 └──1:N── audit_logs (سجل تدقيق كل تغييرات الشركة)
```

## جدول: `companies`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | uuid PK | |
| `name`, `name_ar` | text | اسم بالإنجليزية (إلزامي) والعربية (اختياري) |
| `slug` | text UNIQUE | يطابق `^[a-z0-9-]+$` (تحقق CHECK) |
| `logo_url`, `address`, `phone` | text | |
| `timezone` | text | افتراضياً `'Asia/Baghdad'` |
| `is_active` | boolean | تعطيل ناعم للمستأجر بأكمله |
| `created_at`, `updated_at` | timestamptz | |

## جدول: `platform_admins`

| العمود | النوع | ملاحظات |
|---|---|---|
| `user_id` | uuid PK, FK → `auth.users` | |
| `full_name` | text | |
| `created_at` | timestamptz | |

مالك منصة عابر لكل المستأجرين — انظر `auth.is_platform_owner()` في
[015_rls_helper_functions.sql](../../backend/supabase/migrations/015_rls_helper_functions.sql).

## جدول: `company_members`

عضوية مستخدم واحد في شركة واحدة، بدور واحد.

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | uuid PK | |
| `company_id` | uuid FK → `companies` | CASCADE |
| `user_id` | uuid FK → `auth.users` | CASCADE |
| `role` | text | CHECK: `worker` / `foreman` / `engineer` / `projectManager` / `admin` |
| `full_name`, `phone`, `avatar_url`, `job_title` | text | |
| `is_active` | boolean | تعطيل ناعم لعضوية واحدة |
| `joined_at`, `created_at`, `updated_at` | timestamptz | |
| **UNIQUE** | `(company_id, user_id)` | عضوية واحدة فقط لكل مستخدم في كل شركة |

## جدول: `projects`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | uuid PK | |
| `company_id` | uuid FK → `companies` | CASCADE |
| `name`, `name_ar`, `code`, `client_name`, `address`, `description` | text | |
| `latitude`, `longitude` | double precision | مركز الموقع الجغرافي للـ Geofencing |
| `geofence_radius_meters` | numeric | افتراضياً `150` |
| `start_date`, `end_date` | date | |
| `status` | text | CHECK: `active`/`on_hold`/`completed`/`archived` |
| `created_by` | uuid FK → `auth.users` | |
| **UNIQUE** | `(company_id, code)` | |

## جدول: `project_members`

عضوية مستخدم في مشروع محدد (N:M بين `projects` و`auth.users`).

| العمود | النوع | ملاحظات |
|---|---|---|
| `project_id` | uuid FK → `projects` | CASCADE |
| `company_id` | uuid FK → `companies` | مكرَّر عمداً لتبسيط RLS (تفادي JOIN) |
| `user_id` | uuid FK → `auth.users` | CASCADE |
| `is_active` | boolean | |
| **UNIQUE** | `(project_id, user_id)` | |

## جدول: `project_milestones` 🆕

| العمود | النوع | ملاحظات |
|---|---|---|
| `project_id` | uuid FK → `projects` | CASCADE |
| `title`, `title_ar`, `description` | text | |
| `due_date` | date | |
| `completed_at` | timestamptz | |
| `status` | text | CHECK: `pending`/`in_progress`/`completed`/`delayed` |
| `progress_percent` | integer | CHECK: `0..100` |

## جدول: `tasks`

| العمود | النوع | ملاحظات |
|---|---|---|
| `project_id` | uuid FK → `projects` | CASCADE |
| `title`, `description` | text | |
| `status` | text | CHECK: `todo`/`in_progress`/`review`/`done`/`blocked` (لوحة Kanban) |
| `priority` | text | CHECK: `low`/`medium`/`high`/`urgent` |
| `assigned_to`, `created_by` | uuid FK → `auth.users` | |
| `due_date` | date | |
| `kanban_order` | integer | ترتيب العرض داخل عمود اللوحة |
| `completed_at` | timestamptz | |

## جدول: `attendance`

الجدول الأكثر حساسية للمزامنة (انظر `FirstWriteWinsResolver` في
[03_sync_strategy.md](./03_sync_strategy.md)).

| العمود | النوع | ملاحظات |
|---|---|---|
| `project_id`, `user_id` | uuid FK | |
| `client_mutation_id` | uuid **UNIQUE** | مفتاح Idempotency من الجهاز — يمنع تسجيل حضور مكرر عبر إعادة إرسال Outbox |
| `check_in_at`, `check_out_at` | timestamptz | |
| `check_in_latitude/longitude`, `check_out_latitude/longitude` | double precision | |
| `geofence_valid` | boolean | هل كان الموقع ضمن نطاق `geofence_radius_meters`؟ |
| `distance_meters` | numeric | المسافة الفعلية عن مركز المشروع |
| `check_method` | text | CHECK: `gps` / `qr` |
| `qr_code_id` | text | إن كان تسجيل الحضور عبر مسح QR |
| `status` | text | CHECK: `pending`/`approved`/`rejected` (اعتماد المشرف) |
| `approved_by`, `approved_at` | uuid / timestamptz | |

## جدول: `field_reports`

| العمود | النوع | ملاحظات |
|---|---|---|
| `project_id`, `created_by` | uuid FK | |
| `report_date` | date | افتراضياً `current_date` |
| `status` | text | CHECK: `draft`/`submitted`/`reviewed`/`rejected` |
| `weather_condition`, `temperature_c` | text/numeric | تُعبَّأ تلقائياً عبر Open-Meteo API (Prompt 17) |
| `labor_count`, `work_performed`, `materials_used`, `equipment_used`, `issues`, `notes` | text/int | |
| `supervisor_signature_url`, `supervisor_signed_at` | text/timestamptz | توقيع رقمي (`signature` package) |
| `client_signature_url`, `client_signed_at` | text/timestamptz | |
| `reviewed_by`, `reviewed_at`, `rejection_reason` | | مسار مراجعة/رفض |

## جدول: `punch_items`

قوائم الملاحظات (Punch List) — مرتبطة اختيارياً بتقرير ميداني.

| العمود | النوع | ملاحظات |
|---|---|---|
| `project_id` | uuid FK | إلزامي |
| `field_report_id` | uuid FK → `field_reports` | اختياري، `ON DELETE SET NULL` |
| `title`, `description`, `location_note` | text | |
| `status` | text | CHECK: `open`/`in_progress`/`resolved`/`closed` |
| `priority` | text | CHECK: `low`/`medium`/`high`/`urgent` |
| `assigned_to`, `created_by`, `resolved_by`, `closed_by` | uuid FK | |
| `due_date`, `resolved_at`, `closed_at` | date/timestamptz | |

## جدول: `photos`

| العمود | النوع | ملاحظات |
|---|---|---|
| `project_id` | uuid FK | اختياري |
| `related_entity_type`, `related_entity_id` | text / uuid | ربط متعدد الأشكال (Polymorphic) بأي كيان (تقرير، مهمة، معدة...) |
| `storage_path`, `thumbnail_path` | text | مسار Supabase Storage |
| `caption`, `file_size_bytes`, `taken_at` | | |
| `latitude`, `longitude` | double precision | بيانات EXIF الجغرافية إن توفرت |
| `uploaded_by` | uuid FK | |

## جدول: `documents`

| العمود | النوع | ملاحظات |
|---|---|---|
| `project_id` | uuid FK | اختياري (مستندات على مستوى الشركة أيضاً) |
| `title`, `description`, `category` | text | |
| `storage_path`, `file_type`, `file_size_bytes` | | |
| `version` | integer | يبدأ من `1` |
| `previous_version_id` | uuid FK → `documents` (ذاتي) | سلسلة إصدارات المستند |
| `is_archived` | boolean | أرشفة ناعمة |

## جدول: `equipment` 🆕

| العمود | النوع | ملاحظات |
|---|---|---|
| `project_id` | uuid FK | اختياري، `ON DELETE SET NULL` |
| `name`, `name_ar`, `type`, `serial_number` | text | |
| `status` | text | CHECK: `available`/`in_use`/`maintenance`/`retired` |
| `assigned_to` | uuid FK | |
| `usage_hours` | numeric | تراكمي |
| `purchase_date`, `last_maintenance_date`, `next_maintenance_due` | date | تُغذّي تنبيهات `equipment-alert` Edge Function |

## جدول: `notifications` 🆕

| العمود | النوع | ملاحظات |
|---|---|---|
| `user_id` | uuid FK | مستلم الإشعار |
| `title`, `body` | text | |
| `type` | text | CHECK موسَّع (انظر [019_extend_notification_types.sql](../../backend/supabase/migrations/019_extend_notification_types.sql)) |
| `related_entity_type`, `related_entity_id` | text / uuid | ربط متعدد الأشكال (فتح الشاشة الصحيحة عند الضغط) |
| `is_read`, `read_at` | boolean / timestamptz | |

## جدول: `leave_requests` 🆕

| العمود | النوع | ملاحظات |
|---|---|---|
| `user_id` | uuid FK | مقدّم الطلب |
| `leave_type` | text | CHECK: `annual`/`sick`/`emergency`/`unpaid`/`other` |
| `start_date`, `end_date` | date | CHECK: `end_date >= start_date` |
| `reason` | text | |
| `status` | text | CHECK: `pending`/`approved`/`rejected`/`cancelled` |
| `reviewed_by`, `reviewed_at`, `review_note` | | مسار الاعتماد |

## جدول: `audit_logs`

| العمود | النوع | ملاحظات |
|---|---|---|
| `company_id` | uuid FK، **قابل للـ NULL** | يُترك NULL لعمليات مالك المنصة العابرة للمستأجرين |
| `user_id` | uuid FK | من نفَّذ العملية |
| `action` | text | CHECK: `INSERT`/`UPDATE`/`DELETE` |
| `table_name`, `record_id` | text / uuid | الجدول والسجل المتأثر |
| `old_data`, `new_data` | jsonb | لقطة كاملة قبل/بعد (تُملأ تلقائياً عبر Triggers — [017_audit_triggers.sql](../../backend/supabase/migrations/017_audit_triggers.sql)) |

## الفهارس (`018_indexes.sql`)

فهارس مركّبة على `(company_id, project_id)` و`(company_id, user_id)` و
`(company_id, status)` لأكثر الجداول استعلاماً (`tasks`, `attendance`,
`field_reports`, `punch_items`, `notifications`) لضمان أداء استعلامات
القوائم المفلترة بحسب الشركة (RLS) والحالة معاً.
