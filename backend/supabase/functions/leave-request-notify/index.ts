// ============================================================
// leave-request-notify/index.ts 🆕
// تُستدعى عبر Database Webhook مضبوط على جدول leave_requests
// لأحداث INSERT و UPDATE.
//
//  • INSERT (طلب إجازة جديد بحالة pending): إشعار لكل المسؤولين
//    عن اعتماد الإجازات في الشركة (أدوار foreman/projectManager/admin).
//  • UPDATE (تغيّر status إلى approved/rejected/cancelled): إشعار
//    لمقدّم الطلب (user_id) بنتيجة طلبه.
//
// يجب ضبط Webhook في Supabase Studio:
//   Table: leave_requests · Events: INSERT, UPDATE
//   Header: x-webhook-secret = DB_WEBHOOK_SECRET
// ============================================================

import { getSupabaseAdmin } from "../_shared/supabase-admin.ts";
import { verifySharedSecret } from "../_shared/auth.ts";
import { successResponse, errorResponse, unauthorizedResponse, serverErrorResponse } from "../_shared/response.ts";
import { handlePreflight } from "../_shared/cors.ts";

interface LeaveRequestRecord {
  id: string;
  company_id: string;
  user_id: string;
  leave_type: string;
  start_date: string;
  end_date: string;
  status: string;
  review_note: string | null;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: LeaveRequestRecord;
  old_record: LeaveRequestRecord | null;
}

const STATUS_LABELS_AR: Record<string, string> = {
  approved: "تمت الموافقة على",
  rejected: "تم رفض",
  cancelled: "تم إلغاء",
};

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
    const notifiedUserIds: string[] = [];

    // ── حالة 1: طلب إجازة جديد بانتظار الاعتماد ─────────────────
    if (payload.type === "INSERT" && record.status === "pending") {
      const approverIds = await getApproverIds(supabaseAdmin, record.company_id, record.user_id);

      if (approverIds.length > 0) {
        const rows = approverIds.map((approverId) => ({
          company_id: record.company_id,
          user_id: approverId,
          title: "طلب إجازة جديد بانتظار الاعتماد",
          body: `طلب إجازة (${record.leave_type}) من ${record.start_date} إلى ${record.end_date} بانتظار مراجعتك.`,
          type: "leave_request_submitted",
          related_entity_type: "leave_request",
          related_entity_id: record.id,
        }));

        const { error } = await supabaseAdmin.from("notifications").insert(rows);
        if (error) throw error;
        notifiedUserIds.push(...approverIds);
      }
    }

    // ── حالة 2: تغيّرت حالة الطلب (اعتماد/رفض/إلغاء) ────────────
    if (
      payload.type === "UPDATE" &&
      oldStatus !== record.status &&
      ["approved", "rejected", "cancelled"].includes(record.status)
    ) {
      const label = STATUS_LABELS_AR[record.status] ?? record.status;
      const { error } = await supabaseAdmin.from("notifications").insert({
        company_id: record.company_id,
        user_id: record.user_id,
        title: "تحديث حالة طلب الإجازة",
        body: `${label} طلب إجازتك من ${record.start_date} إلى ${record.end_date}.${record.review_note ? ` ملاحظة: ${record.review_note}` : ""}`,
        type: "leave_request_reviewed",
        related_entity_type: "leave_request",
        related_entity_id: record.id,
      });
      if (error) throw error;
      notifiedUserIds.push(record.user_id);
    }

    return successResponse({ notified_user_ids: notifiedUserIds });
  } catch (err) {
    return serverErrorResponse(err);
  }
});

/** المسؤولون عن اعتماد إجازات موظف معيّن: foreman/projectManager/admin النشطون في نفس الشركة. */
// deno-lint-ignore no-explicit-any
async function getApproverIds(
  supabaseAdmin: any,
  companyId: string,
  requesterUserId: string,
): Promise<string[]> {
  const { data, error } = await supabaseAdmin
    .from("company_members")
    .select("user_id")
    .eq("company_id", companyId)
    .eq("is_active", true)
    .in("role", ["foreman", "projectManager", "admin"])
    .neq("user_id", requesterUserId);

  if (error) throw error;
  return (data ?? []).map((m: { user_id: string }) => m.user_id);
}
