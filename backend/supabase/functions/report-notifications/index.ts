// ============================================================
// report-notifications/index.ts
// تُستدعى عبر Database Webhook مضبوط على جدول field_reports لأحداث
// UPDATE (وأيضاً INSERT إن كان التقرير يُنشأ مباشرة بحالة submitted).
// عند رصد انتقال status → 'submitted'، تُنشئ سجل إشعار في جدول
// notifications لكل "مراجع مخوّل": أعضاء الشركة بدور engineer فما
// فوق (engineer/projectManager/admin) وضمن أحدهما:
//   • مسؤول إداري على مستوى الشركة (projectManager/admin)، أو
//   • عضو نشط في نفس المشروع (project_members).
//
// كما تُنشئ إشعاراً لمُنشئ التقرير (created_by) عند اعتماده
// (reviewed) أو رفضه (rejected).
//
// يجب ضبط Webhook في Supabase Studio:
//   Table: field_reports · Events: INSERT, UPDATE
//   Header: x-webhook-secret = DB_WEBHOOK_SECRET
// ============================================================

import { getSupabaseAdmin } from "../_shared/supabase-admin.ts";
import { verifySharedSecret } from "../_shared/auth.ts";
import { successResponse, errorResponse, unauthorizedResponse, serverErrorResponse } from "../_shared/response.ts";
import { handlePreflight } from "../_shared/cors.ts";

interface FieldReportRecord {
  id: string;
  company_id: string;
  project_id: string;
  created_by: string | null;
  status: string;
  report_date: string;
  rejection_reason: string | null;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: FieldReportRecord;
  old_record: FieldReportRecord | null;
}

Deno.serve(async (req: Request) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return errorResponse("هذه الدالة تقبل طلبات POST فقط.", 405, "method_not_allowed");
  }

  try {
    if (!verifySharedSecret(req, "x-webhook-secret", "DB_WEBHOOK_SECRET")) {
      return unauthorizedResponse("سرّ الـ Webhook غير صحيح.");
    }

    let payload: WebhookPayload;
    try {
      payload = await req.json();
    } catch {
      return errorResponse("جسم الطلب يجب أن يكون JSON صالحاً.");
    }

    const record = payload.record;
    const oldStatus = payload.old_record?.status ?? null;

    if (!record) return errorResponse("لا يوجد record في حمولة الـ Webhook.");

    const supabaseAdmin = getSupabaseAdmin();
    const notificationsCreated: string[] = [];

    // ── حالة 1: التقرير أصبح submitted الآن ولم يكن كذلك سابقاً ──
    if (record.status === "submitted" && oldStatus !== "submitted") {
      const reviewerIds = await getAuthorizedReviewerIds(
        supabaseAdmin,
        record.company_id,
        record.project_id,
      );

      if (reviewerIds.length > 0) {
        const rows = reviewerIds.map((reviewerId) => ({
          company_id: record.company_id,
          user_id: reviewerId,
          title: "تقرير ميداني بانتظار المراجعة",
          body: `تم تقديم تقرير ميداني جديد بتاريخ ${record.report_date} بانتظار مراجعتك.`,
          type: "field_report_submitted",
          related_entity_type: "field_report",
          related_entity_id: record.id,
        }));

        const { error } = await supabaseAdmin.from("notifications").insert(rows);
        if (error) throw error;
        notificationsCreated.push(...reviewerIds);
      }
    }

    // ── حالة 2: التقرير اعتُمد أو رُفض (تغيّرت الحالة) ─────────
    if (
      record.created_by &&
      (record.status === "reviewed" || record.status === "rejected") &&
      oldStatus !== record.status
    ) {
      const isRejected = record.status === "rejected";
      const { error } = await supabaseAdmin.from("notifications").insert({
        company_id: record.company_id,
        user_id: record.created_by,
        title: isRejected ? "تم رفض التقرير الميداني" : "تم اعتماد التقرير الميداني",
        body: isRejected
          ? `تم رفض تقريرك الميداني بتاريخ ${record.report_date}.${record.rejection_reason ? ` السبب: ${record.rejection_reason}` : ""}`
          : `تم اعتماد تقريرك الميداني بتاريخ ${record.report_date}.`,
        type: "field_report_reviewed",
        related_entity_type: "field_report",
        related_entity_id: record.id,
      });
      if (error) throw error;
      notificationsCreated.push(record.created_by);
    }

    return successResponse({ notified_user_ids: notificationsCreated });
  } catch (err) {
    return serverErrorResponse(err);
  }
});

/**
 * يحدد قائمة معرّفات المستخدمين المخوّلين بمراجعة تقارير مشروع معيّن:
 * أي عضو شركة نشط بدور engineer فأعلى، شريطة أن يكون إما مسؤولاً
 * إدارياً (projectManager/admin) أو عضواً نشطاً في نفس المشروع.
 */
// deno-lint-ignore no-explicit-any
async function getAuthorizedReviewerIds(
  supabaseAdmin: any,
  companyId: string,
  projectId: string,
): Promise<string[]> {
  const { data: members, error: membersError } = await supabaseAdmin
    .from("company_members")
    .select("user_id, role")
    .eq("company_id", companyId)
    .eq("is_active", true)
    .in("role", ["engineer", "projectManager", "admin"]);

  if (membersError) throw membersError;
  if (!members || members.length === 0) return [];

  const managementUserIds = members
    .filter((m: { role: string }) => m.role === "projectManager" || m.role === "admin")
    .map((m: { user_id: string }) => m.user_id);

  const engineerUserIds = members
    .filter((m: { role: string }) => m.role === "engineer")
    .map((m: { user_id: string }) => m.user_id);

  let projectEngineerIds: string[] = [];
  if (engineerUserIds.length > 0) {
    const { data: projectMembers, error: pmError } = await supabaseAdmin
      .from("project_members")
      .select("user_id")
      .eq("project_id", projectId)
      .eq("is_active", true)
      .in("user_id", engineerUserIds);

    if (pmError) throw pmError;
    projectEngineerIds = (projectMembers ?? []).map((pm: { user_id: string }) => pm.user_id);
  }

  return Array.from(new Set([...managementUserIds, ...projectEngineerIds]));
}
