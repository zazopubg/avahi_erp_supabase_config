// ============================================================
// equipment-alert/index.ts 🆕
// يفحص جدول equipment ويُنشئ إشعار "صيانة مستحقة" عندما:
//   • usage_hours >= الحد الأقصى المسموح قبل الصيانة (افتراضياً 250
//     ساعة، يُضبط عبر EQUIPMENT_USAGE_HOURS_THRESHOLD)، أو
//   • next_maintenance_due خلال أيام قليلة قادمة أو تجاوزها فعلاً
//     (افتراضياً 7 أيام، يُضبط عبر EQUIPMENT_DUE_SOON_DAYS)، أو
//   • last_maintenance_date غير موجود إطلاقاً لمعدة نشطة (available/in_use).
//
// الإشعار يُرسَل إلى:
//   • assigned_to (إن وُجد، مستخدم المعدة الحالي)
//   • كل أعضاء الشركة بدور projectManager/admin (المسؤولون عن الصيانة)
//
// يمنع الإزعاج المتكرر (dedupe): لا يُنشئ إشعاراً جديداً لنفس
// المعدة إن وُجد إشعار "equipment_maintenance_due" غير مقروء لنفس
// related_entity_id خلال آخر EQUIPMENT_ALERT_DEDUPE_DAYS يوماً
// (افتراضياً 3 أيام).
//
// طريقة الاستدعاء: مُهيّأة لتُستدعى دورياً عبر جدولة (pg_cron أو
// Supabase Scheduled Functions) — انظر docker-compose.yml للتشغيل
// المحلي، وراجع دليل النشر لضبط الجدولة في بيئة الإنتاج.
// يتطلب رأس x-cron-secret مطابق لسرّ CRON_SECRET، أو مستخدم
// admin/platformOwner مصادَق عليه (لإتاحة تشغيل يدوي من لوحة الإدارة).
//
// POST body (اختياري بالكامل):
// { "company_id": "uuid" }   // لتضييق الفحص على شركة واحدة فقط
// ============================================================

import { getSupabaseAdmin } from "../_shared/supabase-admin.ts";
import { getAuthenticatedUser, hasMinRole, getActiveCompanyMembership, isPlatformOwner, verifySharedSecret } from "../_shared/auth.ts";
import { successResponse, errorResponse, unauthorizedResponse, forbiddenResponse, serverErrorResponse } from "../_shared/response.ts";
import { handlePreflight } from "../_shared/cors.ts";

const DEFAULT_USAGE_HOURS_THRESHOLD = 250;
const DEFAULT_DUE_SOON_DAYS = 7;
const DEFAULT_DEDUPE_DAYS = 3;

interface EquipmentRow {
  id: string;
  company_id: string;
  name: string;
  name_ar: string | null;
  status: string;
  assigned_to: string | null;
  usage_hours: number;
  last_maintenance_date: string | null;
  next_maintenance_due: string | null;
}

Deno.serve(async (req: Request) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return errorResponse("هذه الدالة تقبل طلبات POST فقط.", 405, "method_not_allowed");
  }

  try {
    const supabaseAdmin = getSupabaseAdmin();

    // ── التحقق من الاستدعاء: إما سرّ الجدولة (cron) أو مستخدم إداري ──
    const hasCronSecret = verifySharedSecret(req, "x-cron-secret", "CRON_SECRET") &&
      req.headers.has("x-cron-secret");

    if (!hasCronSecret) {
      const user = await getAuthenticatedUser(req, supabaseAdmin);
      if (!user) return unauthorizedResponse();

      const membership = await getActiveCompanyMembership(supabaseAdmin, user.id);
      const owner = await isPlatformOwner(supabaseAdmin, user.id);
      if (!hasMinRole(membership?.role, "projectManager", owner)) {
        return forbiddenResponse("فحص تنبيهات الصيانة متاح فقط لمدير المشروع فما فوق.");
      }
    }

    let companyId: string | undefined;
    try {
      const body = await req.json();
      companyId = body?.company_id;
    } catch {
      // body فارغ مقبول تماماً لهذه الدالة
    }

    const usageThreshold = Number(
      Deno.env.get("EQUIPMENT_USAGE_HOURS_THRESHOLD") ?? DEFAULT_USAGE_HOURS_THRESHOLD,
    );
    const dueSoonDays = Number(Deno.env.get("EQUIPMENT_DUE_SOON_DAYS") ?? DEFAULT_DUE_SOON_DAYS);
    const dedupeDays = Number(Deno.env.get("EQUIPMENT_ALERT_DEDUPE_DAYS") ?? DEFAULT_DEDUPE_DAYS);

    let query = supabaseAdmin
      .from("equipment")
      .select("id, company_id, name, name_ar, status, assigned_to, usage_hours, last_maintenance_date, next_maintenance_due")
      .in("status", ["available", "in_use"]);

    if (companyId) query = query.eq("company_id", companyId);

    const { data: equipmentList, error: equipmentError } = await query;
    if (equipmentError) throw equipmentError;

    const dueSoonThresholdDate = new Date();
    dueSoonThresholdDate.setDate(dueSoonThresholdDate.getDate() + dueSoonDays);

    const alerted: string[] = [];

    for (const eq of (equipmentList ?? []) as EquipmentRow[]) {
      const reasons: string[] = [];

      if (eq.usage_hours >= usageThreshold) {
        reasons.push(`تجاوزت ساعات التشغيل (${eq.usage_hours}) الحد المسموح (${usageThreshold} ساعة).`);
      }

      if (eq.next_maintenance_due && new Date(eq.next_maintenance_due) <= dueSoonThresholdDate) {
        reasons.push(`موعد الصيانة القادم (${eq.next_maintenance_due}) مستحق خلال ${dueSoonDays} أيام أو تجاوز.`);
      }

      if (!eq.last_maintenance_date && !eq.next_maintenance_due) {
        reasons.push("لا يوجد سجل صيانة سابق لهذه المعدة.");
      }

      if (reasons.length === 0) continue;

      const alreadyNotified = await hasRecentDuplicateAlert(supabaseAdmin, eq.id, dedupeDays);
      if (alreadyNotified) continue;

      const recipients = await getMaintenanceRecipients(supabaseAdmin, eq.company_id, eq.assigned_to);
      if (recipients.length === 0) continue;

      const displayName = eq.name_ar || eq.name;
      const rows = recipients.map((recipientId) => ({
        company_id: eq.company_id,
        user_id: recipientId,
        title: "صيانة مستحقة لمعدة",
        body: `المعدة "${displayName}" بحاجة لصيانة: ${reasons.join(" ")}`,
        type: "equipment_maintenance_due",
        related_entity_type: "equipment",
        related_entity_id: eq.id,
      }));

      const { error: insertError } = await supabaseAdmin.from("notifications").insert(rows);
      if (insertError) throw insertError;

      alerted.push(eq.id);
    }

    return successResponse({ checked: equipmentList?.length ?? 0, alerted_equipment_ids: alerted });
  } catch (err) {
    return serverErrorResponse(err);
  }
});

// deno-lint-ignore no-explicit-any
async function hasRecentDuplicateAlert(
  supabaseAdmin: any,
  equipmentId: string,
  dedupeDays: number,
): Promise<boolean> {
  const since = new Date();
  since.setDate(since.getDate() - dedupeDays);

  const { data, error } = await supabaseAdmin
    .from("notifications")
    .select("id")
    .eq("type", "equipment_maintenance_due")
    .eq("related_entity_id", equipmentId)
    .gte("created_at", since.toISOString())
    .limit(1);

  if (error) throw error;
  return (data?.length ?? 0) > 0;
}

// deno-lint-ignore no-explicit-any
async function getMaintenanceRecipients(
  supabaseAdmin: any,
  companyId: string,
  assignedTo: string | null,
): Promise<string[]> {
  const { data: managers, error } = await supabaseAdmin
    .from("company_members")
    .select("user_id")
    .eq("company_id", companyId)
    .eq("is_active", true)
    .in("role", ["projectManager", "admin"]);

  if (error) throw error;

  const ids = new Set<string>((managers ?? []).map((m: { user_id: string }) => m.user_id));
  if (assignedTo) ids.add(assignedTo);

  return Array.from(ids);
}
