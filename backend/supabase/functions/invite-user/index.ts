// ============================================================
// invite-user/index.ts
// 🆕 (Prompt 26) يدعو مستخدماً جديداً بالبريد الإلكتروني إلى شركة
// (مستأجر) بدور محدد: ينشئ/يدعو مستخدم Supabase Auth عبر
// auth.admin.inviteUserByEmail (يرسل بريد دعوة يحدّد كلمة مرور)، ثم
// يُنشئ صف عضوية `company_members` مرتبطاً به مباشرة. كلا الإجراءين
// يتطلبان صلاحية service_role — غير متاحين إطلاقاً من عميل Flutter
// مباشرة، بنفس منطق create-company/soft-delete-tenant.
//
// محصور بصلاحية Permission.usersInvite على مستوى Flutter (admin/
// projectManager)، ومُتحقَّق منه هنا أيضاً على الخادم (لا يجوز
// الاعتماد على تحقق العميل وحده لإجراء حساس كهذا).
//
// POST body:
// {
//   "company_id": "uuid",
//   "email": "user@example.com",
//   "full_name": "اسم المستخدم",
//   "role": "worker" | "foreman" | "engineer" | "projectManager" | "admin",
//   "job_title": "...",   // اختياري
//   "phone": "..."        // اختياري
// }
// ============================================================

import { getSupabaseAdmin } from "../_shared/supabase-admin.ts";
import {
  getAuthenticatedUser,
  getActiveCompanyMembership,
  isPlatformOwner,
  hasMinRole,
  roleRank,
} from "../_shared/auth.ts";
import {
  successResponse,
  errorResponse,
  unauthorizedResponse,
  forbiddenResponse,
  serverErrorResponse,
} from "../_shared/response.ts";
import { handlePreflight } from "../_shared/cors.ts";

const VALID_ROLES = [
  "worker",
  "foreman",
  "engineer",
  "projectManager",
  "admin",
] as const;

interface InviteUserPayload {
  company_id: string;
  email: string;
  full_name: string;
  role: string;
  job_title?: string;
  phone?: string;
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
    const actor = await getAuthenticatedUser(req, supabaseAdmin);
    if (!actor) return unauthorizedResponse();

    const actorIsOwner = await isPlatformOwner(supabaseAdmin, actor.id);
    const actorMembership = await getActiveCompanyMembership(supabaseAdmin, actor.id);

    if (!actorIsOwner && !hasMinRole(actorMembership?.role, "projectManager", false)) {
      return forbiddenResponse("دعوة مستخدمين جدد متاحة فقط لمدير مشروع فأعلى (Permission.usersInvite).");
    }

    // ── 2) التحقق من صحة المدخلات ─────────────────────────────
    let payload: InviteUserPayload;
    try {
      payload = await req.json();
    } catch {
      return errorResponse("جسم الطلب يجب أن يكون JSON صالحاً.");
    }

    if (!payload.company_id?.trim()) {
      return errorResponse("حقل company_id مطلوب.");
    }
    if (!payload.email?.trim()) {
      return errorResponse("حقل email مطلوب.");
    }
    if (!payload.full_name?.trim()) {
      return errorResponse("حقل full_name مطلوب.");
    }
    if (!VALID_ROLES.includes(payload.role as (typeof VALID_ROLES)[number])) {
      return errorResponse(`حقل role يجب أن يكون أحد: ${VALID_ROLES.join(", ")}.`);
    }

    // مستخدم عادي (غير مالك منصة) لا يمكنه دعوة أحد إلى شركة أخرى غير
    // شركته، ولا بدور أعلى من دوره هو (منع تصعيد صلاحيات ذاتي عبر
    // دعوة "زميل" بدور admin من حساب projectManager).
    if (!actorIsOwner) {
      if (actorMembership?.companyId !== payload.company_id.trim()) {
        return forbiddenResponse("لا يمكنك دعوة مستخدمين إلى شركة أخرى غير شركتك.");
      }
      if (roleRank(payload.role) > roleRank(actorMembership?.role)) {
        return forbiddenResponse("لا يمكنك دعوة مستخدم بدور أعلى من دورك الحالي.");
      }
    }

    const email = payload.email.trim().toLowerCase();

    // ── 3) التأكد من عدم وجود عضوية سابقة بنفس البريد ضمن الشركة ──
    const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
    const existingAuthUser = existingUsers?.users?.find(
      (u) => u.email?.toLowerCase() === email,
    );

    if (existingAuthUser) {
      const { data: existingMembership } = await supabaseAdmin
        .from("company_members")
        .select("id")
        .eq("company_id", payload.company_id.trim())
        .eq("user_id", existingAuthUser.id)
        .maybeSingle();

      if (existingMembership) {
        return errorResponse("يوجد عضو بهذا البريد الإلكتروني في الشركة بالفعل.", 409, "conflict");
      }
    }

    // ── 4) دعوة/إنشاء مستخدم Supabase Auth ─────────────────────
    // inviteUserByEmail تُنشئ المستخدم إن لم يكن موجوداً وترسل بريد
    // دعوة لتحديد كلمة مرور؛ إن كان موجوداً بالفعل (auth.users) نتابع
    // مباشرة لإنشاء عضويته الجديدة في هذه الشركة دون خطأ.
    let targetUserId = existingAuthUser?.id ?? null;
    if (!targetUserId) {
      const { data: invited, error: inviteError } =
        await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
          data: { full_name: payload.full_name.trim() },
        });
      if (inviteError) throw inviteError;
      targetUserId = invited.user?.id ?? null;
    }

    if (!targetUserId) {
      return serverErrorResponse(new Error("تعذّر تحديد معرّف المستخدم بعد الدعوة."));
    }

    // ── 5) إنشاء عضوية company_members ──────────────────────────
    const { data: membership, error: memberError } = await supabaseAdmin
      .from("company_members")
      .insert({
        company_id: payload.company_id.trim(),
        user_id: targetUserId,
        role: payload.role,
        full_name: payload.full_name.trim(),
        phone: payload.phone?.trim() ?? null,
        job_title: payload.job_title?.trim() ?? null,
        is_active: true,
      })
      .select()
      .single();

    if (memberError) throw memberError;

    // ⚠️ بلا سجل تدقيق يدوي هنا (بخلاف `create-company`/`soft-delete-tenant`
    // لجدول `companies` الذي لا يملك مُشغّل تدقيق تلقائي) — `company_members`
    // مُدرَجة أصلاً ضمن `trg_audit_company_members`
    // (`017_audit_triggers.sql`)، فتُسجَّل هذه العضوية الجديدة تلقائياً
    // عبر ذلك المُشغّل عند تنفيذ الإدراج أعلاه مباشرة؛ إدراج يدوي هنا
    // كان سيُكرِّر نفس الحدث مرتين في `audit_logs`.

    return successResponse({ membership }, 201);
  } catch (err) {
    return serverErrorResponse(err);
  }
});
