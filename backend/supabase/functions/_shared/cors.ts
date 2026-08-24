// ============================================================
// _shared/cors.ts
// رؤوس CORS الموحّدة لكل Edge Functions. التطبيق يُستهلك من
// Flutter (ويب/موبايل/سطح مكتب)، لذا نسمح بأي أصل ونحدد الطرق
// والرؤوس المسموحة صراحةً.
// ============================================================

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-secret, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS, PATCH, PUT, DELETE",
};

/** يُعيد استجابة فارغة صحيحة لطلبات Preflight (OPTIONS). */
export function handlePreflight(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  return null;
}
