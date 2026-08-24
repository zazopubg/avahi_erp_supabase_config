// ============================================================
// create-company/index.ts
// إنشاء شركة (مستأجر) جديدة في النظام. محصور بصلاحية
// platformOwner فقط (مُتحقَّق عبر جدول platform_admins).
//
// يدعم اختيارياً إسناد أول مستخدم "admin" للشركة الجديدة مباشرة
// (initial_admin_user_id) لتفادي وجود شركة بلا أي عضو إداري.
//
// POST body:
// {
//   "name": "شركة الإعمار الحديثة",
//   "name_ar": "شركة الإعمار الحديثة",
//   "slug": "modern-construction",
//   "timezone": "Asia/Baghdad",
//   "address": "...",
//   "phone": "...",
//   "logo_url": "...",
//   "initial_admin_user_id": "uuid",      // اختياري
//   "initial_admin_full_name": "اسم"      // اختياري (مطلوب إن أُرسل initial_admin_user_id)
// }
// ============================================================

import { getSupabaseAdmin } from "../_shared/supabase-admin.ts";
import { getAuthenticatedUser, isPlatformOwner } from "../_shared/auth.ts";
import {
  successResponse,
  errorResponse,
  unauthorizedResponse,
  forbiddenResponse,
  serverErrorResponse,
} from "../_shared/response.ts";
import { handlePreflight } from "../_shared/cors.ts";

const SLUG_PATTERN = /^[a-z0-9-]+$/;

interface CreateCompanyPayload {
  name: string;
  name_ar?: string;
  slug: string;
  timezone?: string;
  address?: string;
  phone?: string;
  logo_url?: string;
  initial_admin_user_id?: string;
  initial_admin_full_name?: string;
}

Deno.serve(async (req: Request) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return errorResponse("هذه الدالة تقبل طلبات POST فقط.", 405, "method_not_allowed");
  }

  try {
    const supabaseAdmin = getSupabaseAdmin();

    // ── 1) التحقق من الهوية والصلاحية ─────────────────────────
    const user = await getAuthenticatedUser(req, supabaseAdmin);
    if (!user) return unauthorizedResponse();

    const isOwner = await isPlatformOwner(supabaseAdmin, user.id);
    if (!isOwner) {
      return forbiddenResponse("إنشاء شركة جديدة متاح فقط لمالكي المنصة (platformOwner).");
    }

    // ── 2) التحقق من صحة المدخلات ─────────────────────────────
    let payload: CreateCompanyPayload;
    try {
      payload = await req.json();
    } catch {
      return errorResponse("جسم الطلب يجب أن يكون JSON صالحاً.");
    }

    if (!payload.name?.trim()) {
      return errorResponse("حقل name مطلوب.");
    }
    if (!payload.slug?.trim() || !SLUG_PATTERN.test(payload.slug.trim())) {
      return errorResponse("حقل slug مطلوب ويجب أن يحتوي فقط على أحرف لاتينية صغيرة وأرقام وشرطات (-).");
    }
    if (payload.initial_admin_user_id && !payload.initial_admin_full_name?.trim()) {
      return errorResponse("initial_admin_full_name مطلوب عند إرسال initial_admin_user_id.");
    }

    // ── 3) التأكد من عدم تكرار الـ slug ───────────────────────
    const { data: existingCompany } = await supabaseAdmin
      .from("companies")
      .select("id")
      .eq("slug", payload.slug.trim())
      .maybeSingle();

    if (existingCompany) {
      return errorResponse("يوجد مستأجر آخر يستخدم نفس الـ slug بالفعل.", 409, "conflict");
    }

    // ── 4) إنشاء الشركة ────────────────────────────────────────
    const { data: company, error: insertError } = await supabaseAdmin
      .from("companies")
      .insert({
        name: payload.name.trim(),
        name_ar: payload.name_ar?.trim() ?? null,
        slug: payload.slug.trim(),
        timezone: payload.timezone?.trim() || "Asia/Baghdad",
        address: payload.address?.trim() ?? null,
        phone: payload.phone?.trim() ?? null,
        logo_url: payload.logo_url?.trim() ?? null,
        is_active: true,
      })
      .select()
      .single();

    if (insertError) throw insertError;

    // ── 5) إسناد أول مدير للشركة (اختياري) ────────────────────
    let adminMembership = null;
    if (payload.initial_admin_user_id) {
      const { data: membership, error: memberError } = await supabaseAdmin
        .from("company_members")
        .insert({
          company_id: company.id,
          user_id: payload.initial_admin_user_id,
          role: "admin",
          full_name: payload.initial_admin_full_name!.trim(),
          is_active: true,
        })
        .select()
        .single();

      if (memberError) {
        // لا نفشل العملية كاملة إن فشل إسناد المدير — الشركة أُنشئت بنجاح
        // بالفعل ويمكن إسناد مدير لها لاحقاً يدوياً.
        console.error("[create-company] فشل إسناد المدير الأولي:", memberError.message);
      } else {
        adminMembership = membership;
      }
    }

    // ── 6) سجل تدقيق ────────────────────────────────────────────
    await supabaseAdmin.from("audit_logs").insert({
      company_id: company.id,
      user_id: user.id,
      action: "INSERT",
      table_name: "companies",
      record_id: company.id,
      new_data: company,
    });

    return successResponse({ company, admin_membership: adminMembership }, 201);
  } catch (err) {
    return serverErrorResponse(err);
  }
});
