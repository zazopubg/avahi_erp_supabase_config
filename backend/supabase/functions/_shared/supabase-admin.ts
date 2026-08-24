// ============================================================
// _shared/supabase-admin.ts
// إنشاء عميل Supabase بصلاحية service_role (تتجاوز RLS) لاستخدامه
// داخل Edge Functions فقط. لا يُستخدم هذا العميل أبداً في طبقة
// Flutter — يبقى حصراً في بيئة الخادم (Deno Runtime).
// ============================================================

import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

let cachedAdminClient: SupabaseClient | null = null;

/**
 * يعيد عميل Supabase موحّد بصلاحية service_role. يُستخدم متغيرا البيئة
 * SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY المُحقنان تلقائياً من قِبَل
 * منصة Supabase عند نشر الدالة (أو عبر docker-compose.yml محلياً).
 */
export function getSupabaseAdmin(): SupabaseClient {
  if (cachedAdminClient) return cachedAdminClient;

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error(
      "متغيرات البيئة SUPABASE_URL أو SUPABASE_SERVICE_ROLE_KEY غير مُعرّفة.",
    );
  }

  cachedAdminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  return cachedAdminClient;
}
