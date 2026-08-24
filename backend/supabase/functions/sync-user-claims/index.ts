// ============================================================
// sync-user-claims/index.ts
// يُحدّث app_metadata على مستخدم Supabase Auth (company_id, role,
// is_platform_owner) بعد أي تغيير في عضويته/دوره ضمن company_members.
// هذا يسمح بقراءة الدور مباشرة من الـ JWT في العميل (Flutter) دون
// استعلام إضافي، ويُستخدم أيضاً كطبقة دفاع إضافية خلف سياسات RLS
// (التي تبقى المصدر الحقيقي للصلاحية دائماً عبر company_members).
//
// طريقتا الاستدعاء المدعومتان:
//
// 1) Database Webhook (يُضبط في Supabase Studio على company_members
//    لأحداث INSERT/UPDATE): يُرسل الحمولة القياسية التالية، ويجب أن
//    يحمل رأس x-webhook-secret المطابق لسرّ DB_WEBHOOK_SECRET:
//    { "type": "INSERT" | "UPDATE", "table": "company_members",
//      "record": { "user_id": "uuid", ... }, "old_record": {...}|null }
//
// 2) استدعاء يدوي/مباشر من دالة أخرى أو من لوحة الإدارة:
//    { "user_id": "uuid" }
// ============================================================

import { getSupabaseAdmin } from "../_shared/supabase-admin.ts";
import { isPlatformOwner, verifySharedSecret } from "../_shared/auth.ts";
import { successResponse, errorResponse, unauthorizedResponse, serverErrorResponse } from "../_shared/response.ts";
import { handlePreflight } from "../_shared/cors.ts";

interface WebhookPayload {
  type?: "INSERT" | "UPDATE" | "DELETE";
  table?: string;
  record?: { user_id?: string };
  old_record?: { user_id?: string } | null;
  user_id?: string; // يدعم أيضاً الاستدعاء المباشر البسيط
}

Deno.serve(async (req: Request) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return errorResponse("هذه الدالة تقبل طلبات POST فقط.", 405, "method_not_allowed");
  }

  try {
    // Database Webhooks من Supabase لا تحمل JWT مستخدم، لذا نتحقق من
    // سرّ مشترك بدلاً من ذلك.
    if (!verifySharedSecret(req, "x-webhook-secret", "DB_WEBHOOK_SECRET")) {
      return unauthorizedResponse("سرّ الـ Webhook غير صحيح.");
    }

    let payload: WebhookPayload;
    try {
      payload = await req.json();
    } catch {
      return errorResponse("جسم الطلب يجب أن يكون JSON صالحاً.");
    }

    const targetUserId = payload.record?.user_id ?? payload.user_id;
    if (!targetUserId) {
      return errorResponse("لم يتم تحديد user_id لمزامنة صلاحياته.");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // ── جلب العضوية النشطة الحالية (قد لا توجد إن أُلغيت) ─────
    const { data: membership } = await supabaseAdmin
      .from("company_members")
      .select("company_id, role, is_active")
      .eq("user_id", targetUserId)
      .eq("is_active", true)
      .limit(1)
      .maybeSingle();

    const isOwner = await isPlatformOwner(supabaseAdmin, targetUserId);

    const appMetadata = {
      company_id: membership?.company_id ?? null,
      role: membership?.role ?? null,
      is_platform_owner: isOwner,
      claims_synced_at: new Date().toISOString(),
    };

    const { data: updatedUser, error: updateError } =
      await supabaseAdmin.auth.admin.updateUserById(targetUserId, {
        app_metadata: appMetadata,
      });

    if (updateError) throw updateError;

    return successResponse({
      user_id: targetUserId,
      app_metadata: updatedUser.user?.app_metadata ?? appMetadata,
    });
  } catch (err) {
    return serverErrorResponse(err);
  }
});
