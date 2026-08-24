// ============================================================
// soft-delete-tenant/index.ts
// تعطيل منطقي (Soft Delete) كامل لمستأجر (شركة): يضبط
// companies.is_active = false ويُعطّل جميع عضويات أعضائها
// (company_members.is_active = false)، دون حذف أي صف من قاعدة
// البيانات — يبقى كل شيء قابلاً للاسترجاع (Prompt 28: يتضمن أيضاً
// تصدير بيانات المستأجر قبل أي تعطيل نهائي إن لزم).
//
// محصور بصلاحية platformOwner فقط.
//
// POST body:
// { "company_id": "uuid", "reason": "سبب التعطيل (اختياري)" }
// ============================================================

import { getSupabaseAdmin } from "../_shared/supabase-admin.ts";
import { getAuthenticatedUser, isPlatformOwner } from "../_shared/auth.ts";
import {
  successResponse,
  errorResponse,
  unauthorizedResponse,
  forbiddenResponse,
  notFoundResponse,
  serverErrorResponse,
} from "../_shared/response.ts";
import { handlePreflight } from "../_shared/cors.ts";

interface SoftDeletePayload {
  company_id: string;
  reason?: string;
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

    const owner = await isPlatformOwner(supabaseAdmin, user.id);
    if (!owner) {
      return forbiddenResponse("تعطيل مستأجر متاح فقط لمالكي المنصة (platformOwner).");
    }

    let payload: SoftDeletePayload;
    try {
      payload = await req.json();
    } catch {
      return errorResponse("جسم الطلب يجب أن يكون JSON صالحاً.");
    }

    if (!payload.company_id) return errorResponse("company_id مطلوب.");

    const { data: company, error: fetchError } = await supabaseAdmin
      .from("companies")
      .select("*")
      .eq("id", payload.company_id)
      .maybeSingle();

    if (fetchError) throw fetchError;
    if (!company) return notFoundResponse("الشركة غير موجودة.");

    if (!company.is_active) {
      return successResponse({ company, already_inactive: true });
    }

    // ── 1) تعطيل الشركة نفسها ──────────────────────────────────
    const { data: updatedCompany, error: updateError } = await supabaseAdmin
      .from("companies")
      .update({ is_active: false })
      .eq("id", payload.company_id)
      .select()
      .single();

    if (updateError) throw updateError;

    // ── 2) تعطيل جميع عضويات أعضاء هذه الشركة ────────────────────
    const { data: deactivatedMembers, error: membersError } = await supabaseAdmin
      .from("company_members")
      .update({ is_active: false })
      .eq("company_id", payload.company_id)
      .eq("is_active", true)
      .select("id, user_id");

    if (membersError) throw membersError;

    // ── 3) سجل تدقيق ────────────────────────────────────────────
    await supabaseAdmin.from("audit_logs").insert({
      company_id: payload.company_id,
      user_id: user.id,
      action: "UPDATE",
      table_name: "companies",
      record_id: payload.company_id,
      old_data: company,
      new_data: {
        ...updatedCompany,
        soft_delete_reason: payload.reason ?? null,
        deactivated_member_count: deactivatedMembers?.length ?? 0,
      },
    });

    return successResponse({
      company: updatedCompany,
      deactivated_members: deactivatedMembers ?? [],
      already_inactive: false,
    });
  } catch (err) {
    return serverErrorResponse(err);
  }
});
