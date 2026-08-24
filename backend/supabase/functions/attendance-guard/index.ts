// ============================================================
// attendance-guard/index.ts
// نقطة الدخول الوحيدة المعتمدة لتسجيل الحضور والانصراف. تُستدعى
// من التطبيق (بدلاً من الكتابة المباشرة على جدول attendance) لأنها
// تضمن ثلاث قواعد لا يمكن فرضها بالكامل عبر RLS وحدها:
//
//  1) Idempotency: إعادة إرسال نفس client_mutation_id (بعد انقطاع
//     شبكة أثناء المزامنة offline-first) لا يُنشئ سجلاً مكرراً، بل
//     يعيد السجل الموجود كما هو.
//  2) Geofence: حساب المسافة الفعلية بين نقطة تسجيل الحضور ومركز
//     المشروع عبر Haversine، وتخزين geofence_valid + distance_meters.
//  3) لا تاريخ مستقبلي: أي وقت تسجيل (check-in/out) في المستقبل
//     (بهامش سماح بسيط لفروقات ساعة الجهاز) يُرفض فوراً.
//
// POST body لتسجيل الحضور (check_in):
// {
//   "action": "check_in",
//   "project_id": "uuid",
//   "client_mutation_id": "uuid",   // يُولَّد على الجهاز، فريد لكل محاولة
//   "latitude": 33.3128,
//   "longitude": 44.3615,
//   "check_method": "gps" | "qr",
//   "qr_code_id": "...",             // مطلوب إن كانت check_method = qr
//   "occurred_at": "2026-08-11T08:00:00Z"  // اختياري، افتراضياً الآن
// }
//
// POST body لتسجيل الانصراف (check_out):
// {
//   "action": "check_out",
//   "attendance_id": "uuid",
//   "latitude": 33.3128,
//   "longitude": 44.3615,
//   "occurred_at": "2026-08-11T17:00:00Z"  // اختياري
// }
// ============================================================

import { getSupabaseAdmin } from "../_shared/supabase-admin.ts";
import { getAuthenticatedUser, getActiveCompanyMembership, isPlatformOwner } from "../_shared/auth.ts";
import { checkGeofence } from "../_shared/geo.ts";
import {
  successResponse,
  errorResponse,
  unauthorizedResponse,
  forbiddenResponse,
  notFoundResponse,
  serverErrorResponse,
} from "../_shared/response.ts";
import { handlePreflight } from "../_shared/cors.ts";

// هامش سماح لفروقات ساعة الجهاز عن الخادم (لا نرفض وقتاً "مستقبلياً"
// بفارق بسيط جداً بسبب عدم تزامن الساعات).
const FUTURE_TOLERANCE_MS = 5 * 60 * 1000; // 5 دقائق

interface CheckInPayload {
  action: "check_in";
  project_id: string;
  client_mutation_id: string;
  latitude: number;
  longitude: number;
  check_method?: "gps" | "qr";
  qr_code_id?: string;
  occurred_at?: string;
}

interface CheckOutPayload {
  action: "check_out";
  attendance_id: string;
  latitude: number;
  longitude: number;
  occurred_at?: string;
}

type RequestPayload = CheckInPayload | CheckOutPayload;

function isFutureTimestamp(iso: string): boolean {
  const t = new Date(iso).getTime();
  if (Number.isNaN(t)) return false;
  return t - Date.now() > FUTURE_TOLERANCE_MS;
}

Deno.serve(async (req: Request) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return errorResponse("هذه الدالة تقبل طلبات POST فقط.", 405, "method_not_allowed");
  }

  try {
    const supabaseAdmin = getSupabaseAdmin();

    const user = await getAuthenticatedUser(req, supabaseAdmin);
    if (!user) return unauthorizedResponse();

    const membership = await getActiveCompanyMembership(supabaseAdmin, user.id);
    const owner = await isPlatformOwner(supabaseAdmin, user.id);
    if (!membership && !owner) {
      return forbiddenResponse("يجب أن تكون عضواً نشطاً في شركة لتسجيل الحضور.");
    }

    let payload: RequestPayload;
    try {
      payload = await req.json();
    } catch {
      return errorResponse("جسم الطلب يجب أن يكون JSON صالحاً.");
    }

    if (payload.action === "check_in") {
      return await handleCheckIn(supabaseAdmin, user.id, membership?.companyId, payload);
    }

    if (payload.action === "check_out") {
      return await handleCheckOut(supabaseAdmin, user.id, payload);
    }

    return errorResponse("قيمة action يجب أن تكون check_in أو check_out.");
  } catch (err) {
    return serverErrorResponse(err);
  }
});

// deno-lint-ignore no-explicit-any
async function handleCheckIn(
  supabaseAdmin: any,
  userId: string,
  membershipCompanyId: string | undefined,
  payload: CheckInPayload,
): Promise<Response> {
  if (!payload.project_id) return errorResponse("project_id مطلوب.");
  if (!payload.client_mutation_id) return errorResponse("client_mutation_id مطلوب لضمان idempotency.");
  if (typeof payload.latitude !== "number" || typeof payload.longitude !== "number") {
    return errorResponse("latitude و longitude مطلوبان كأرقام صحيحة.");
  }

  const checkMethod = payload.check_method ?? "gps";
  if (checkMethod === "qr" && !payload.qr_code_id) {
    return errorResponse("qr_code_id مطلوب عند check_method = qr.");
  }

  const occurredAt = payload.occurred_at ?? new Date().toISOString();
  if (isFutureTimestamp(occurredAt)) {
    return errorResponse("لا يمكن تسجيل حضور بتاريخ/وقت مستقبلي.", 422, "future_timestamp");
  }

  // ── 1) Idempotency: هل هذا الطلب أُرسل ونُفّذ من قبل؟ ─────────
  const { data: existing } = await supabaseAdmin
    .from("attendance")
    .select("*")
    .eq("client_mutation_id", payload.client_mutation_id)
    .maybeSingle();

  if (existing) {
    return successResponse({ attendance: existing, idempotent_replay: true }, 200);
  }

  // ── 2) جلب بيانات المشروع للتحقق من الجيوفنسينغ والشركة ────────
  const { data: project, error: projectError } = await supabaseAdmin
    .from("projects")
    .select("id, company_id, latitude, longitude, geofence_radius_meters")
    .eq("id", payload.project_id)
    .maybeSingle();

  if (projectError) throw projectError;
  if (!project) return notFoundResponse("المشروع غير موجود.");

  if (membershipCompanyId && project.company_id !== membershipCompanyId) {
    return forbiddenResponse("هذا المشروع لا يتبع شركتك.");
  }

  // ── 3) حساب الجيوفنسينغ (فقط عند gps ووجود إحداثيات للمشروع) ──
  let geofenceValid = false;
  let distanceMeters: number | null = null;

  if (checkMethod === "gps" && project.latitude != null && project.longitude != null) {
    const result = checkGeofence(
      payload.latitude,
      payload.longitude,
      project.latitude,
      project.longitude,
      Number(project.geofence_radius_meters ?? 150),
    );
    geofenceValid = result.isValid;
    distanceMeters = result.distanceMeters;
  } else if (checkMethod === "qr") {
    // تسجيل عبر QR يُعتبر تحققاً بديلاً عن GPS (الكود مرتبط فعلياً
    // بموقع فعلي عبر لوحة عرض ثابتة في الموقع)، لذا يُعتبر صالحاً.
    geofenceValid = true;
  }

  // ── 4) الإدراج (upsert لحماية إضافية من سباق الطلبات المتزامنة) ─
  const { data: attendance, error: insertError } = await supabaseAdmin
    .from("attendance")
    .upsert(
      {
        company_id: project.company_id,
        project_id: project.id,
        user_id: userId,
        client_mutation_id: payload.client_mutation_id,
        check_in_at: occurredAt,
        check_in_latitude: payload.latitude,
        check_in_longitude: payload.longitude,
        geofence_valid: geofenceValid,
        distance_meters: distanceMeters,
        check_method: checkMethod,
        qr_code_id: payload.qr_code_id ?? null,
        status: "pending",
      },
      { onConflict: "client_mutation_id", ignoreDuplicates: true },
    )
    .select()
    .maybeSingle();

  if (insertError) throw insertError;

  if (!attendance) {
    // حدث تعارض متزامن (ignoreDuplicates) — أعد جلب السجل الأصلي.
    const { data: raceWinner } = await supabaseAdmin
      .from("attendance")
      .select("*")
      .eq("client_mutation_id", payload.client_mutation_id)
      .maybeSingle();
    return successResponse({ attendance: raceWinner, idempotent_replay: true });
  }

  return successResponse({ attendance, idempotent_replay: false }, 201);
}

// deno-lint-ignore no-explicit-any
async function handleCheckOut(
  supabaseAdmin: any,
  userId: string,
  payload: CheckOutPayload,
): Promise<Response> {
  if (!payload.attendance_id) return errorResponse("attendance_id مطلوب.");
  if (typeof payload.latitude !== "number" || typeof payload.longitude !== "number") {
    return errorResponse("latitude و longitude مطلوبان كأرقام صحيحة.");
  }

  const occurredAt = payload.occurred_at ?? new Date().toISOString();
  if (isFutureTimestamp(occurredAt)) {
    return errorResponse("لا يمكن تسجيل انصراف بتاريخ/وقت مستقبلي.", 422, "future_timestamp");
  }

  const { data: record, error: fetchError } = await supabaseAdmin
    .from("attendance")
    .select("*, projects!inner(latitude, longitude, geofence_radius_meters)")
    .eq("id", payload.attendance_id)
    .maybeSingle();

  if (fetchError) throw fetchError;
  if (!record) return notFoundResponse("سجل الحضور غير موجود.");
  if (record.user_id !== userId) {
    return forbiddenResponse("لا يمكنك تسجيل انصراف عن مستخدم آخر.");
  }

  // ── Idempotency: انصراف مُسجَّل مسبقاً؟ أعد نفس السجل دون خطأ ──
  if (record.check_out_at) {
    return successResponse({ attendance: record, idempotent_replay: true });
  }

  if (new Date(occurredAt).getTime() < new Date(record.check_in_at).getTime()) {
    return errorResponse("وقت الانصراف لا يمكن أن يسبق وقت الحضور.", 422, "invalid_checkout_time");
  }

  const project = record.projects;
  let checkoutGeofenceValid = record.geofence_valid;
  let distanceMeters = record.distance_meters;

  if (record.check_method === "gps" && project?.latitude != null && project?.longitude != null) {
    const result = checkGeofence(
      payload.latitude,
      payload.longitude,
      project.latitude,
      project.longitude,
      Number(project.geofence_radius_meters ?? 150),
    );
    // الحضور يبقى صالحاً فقط إذا كانت كل من نقطتي الحضور والانصراف
    // ضمن نطاق الجيوفنسينغ.
    checkoutGeofenceValid = record.geofence_valid && result.isValid;
    distanceMeters = result.distanceMeters;
  }

  const { data: updated, error: updateError } = await supabaseAdmin
    .from("attendance")
    .update({
      check_out_at: occurredAt,
      check_out_latitude: payload.latitude,
      check_out_longitude: payload.longitude,
      geofence_valid: checkoutGeofenceValid,
      distance_meters: distanceMeters,
    })
    .eq("id", payload.attendance_id)
    .select()
    .single();

  if (updateError) throw updateError;

  return successResponse({ attendance: updated, idempotent_replay: false });
}
