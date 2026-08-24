// ============================================================
// _shared/auth.ts
// أدوات مساعدة للتحقق من هوية المستخدم ودوره قبل تنفيذ أي منطق
// حساس داخل Edge Functions. تعتمد على عميل service_role للتحقق
// من الـ JWT المُرسَل من العميل (Flutter) عبر رأس Authorization،
// وعلى جداول company_members / platform_admins لتحديد الصلاحيات.
// ============================================================

import type { SupabaseClient, User } from "https://esm.sh/@supabase/supabase-js@2.45.4";

/** يستخرج JWT من رأس Authorization بصيغة "Bearer <token>". */
export function extractBearerToken(req: Request): string | null {
  const header = req.headers.get("Authorization") ?? req.headers.get("authorization");
  if (!header) return null;
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : null;
}

/**
 * يتحقق من JWT المُرسَل ويعيد المستخدم المصادَق عليه، أو null إن كان
 * الرمز مفقوداً أو غير صالح. يعتمد على admin.getUser(jwt) وهو آمن
 * لأنه يتحقق من توقيع الرمز عبر GoTrue مباشرة.
 */
export async function getAuthenticatedUser(
  req: Request,
  supabaseAdmin: SupabaseClient,
): Promise<User | null> {
  const token = extractBearerToken(req);
  if (!token) return null;

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data?.user) return null;

  return data.user;
}

export interface CompanyMembership {
  companyId: string;
  role: string;
  isActive: boolean;
}

/** يعيد عضوية المستخدم النشطة (شركة + دور) إن وُجدت. */
export async function getActiveCompanyMembership(
  supabaseAdmin: SupabaseClient,
  userId: string,
): Promise<CompanyMembership | null> {
  const { data, error } = await supabaseAdmin
    .from("company_members")
    .select("company_id, role, is_active")
    .eq("user_id", userId)
    .eq("is_active", true)
    .limit(1)
    .maybeSingle();

  if (error || !data) return null;

  return { companyId: data.company_id, role: data.role, isActive: data.is_active };
}

/** يتحقق مما إذا كان المستخدم مسجّلاً كمالك منصة (platform_admins). */
export async function isPlatformOwner(
  supabaseAdmin: SupabaseClient,
  userId: string,
): Promise<boolean> {
  const { data, error } = await supabaseAdmin
    .from("platform_admins")
    .select("user_id")
    .eq("user_id", userId)
    .maybeSingle();

  return !error && !!data;
}

// ⚠️ يجب أن يطابق هذا الترتيب auth.role_rank() في 015_rls_helper_functions.sql
// وكذلك UserRole.rank في lib/core/constants/roles.dart.
const ROLE_RANK: Record<string, number> = {
  worker: 0,
  foreman: 1,
  engineer: 2,
  projectManager: 3,
  admin: 4,
  platformOwner: 5,
};

export function roleRank(role: string | null | undefined): number {
  if (!role) return -1;
  return ROLE_RANK[role] ?? -1;
}

/** يتحقق من أن دور المستخدم (أو كونه مالك منصة) يبلغ الحد الأدنى المطلوب. */
export function hasMinRole(
  role: string | null | undefined,
  minRole: string,
  isOwner: boolean,
): boolean {
  if (isOwner) return true;
  return roleRank(role) >= roleRank(minRole);
}

/**
 * يتحقق من رأس سرّي مشترك (x-webhook-secret) لتأمين استدعاءات Database
 * Webhooks القادمة من Supabase نفسها (Postgres pg_net triggers)، بما أن
 * هذه الاستدعاءات لا تحمل JWT مستخدم حقيقي.
 */
export function verifySharedSecret(req: Request, headerName: string, envVarName: string): boolean {
  const expected = Deno.env.get(envVarName);
  if (!expected) {
    // في حال عدم ضبط السرّ (مثلاً بيئة تطوير محلية)، لا نمنع الاستدعاء
    // لكن نُحذّر في السجلات لتفادي نشر هذا السلوك في الإنتاج.
    console.warn(`[auth] ${envVarName} غير مضبوط — تخطي التحقق من السرّ المشترك.`);
    return true;
  }
  const provided = req.headers.get(headerName) ?? req.headers.get(headerName.toLowerCase());
  return provided === expected;
}
