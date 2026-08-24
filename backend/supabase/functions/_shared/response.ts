// ============================================================
// _shared/response.ts
// أدوات مساعدة لبناء استجابات JSON موحّدة الشكل عبر كل الدوال،
// تسهّل على طبقة lib/data/cloud/supabase/ في Flutter (Prompt 07)
// التعامل مع نتائج/أخطاء الـ Edge Functions بشكل متوقع وثابت.
// ============================================================

import { corsHeaders } from "./cors.ts";

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function successResponse(data: unknown, status = 200): Response {
  return jsonResponse({ success: true, data }, status);
}

export function errorResponse(
  message: string,
  status = 400,
  code = "bad_request",
): Response {
  return jsonResponse({ success: false, error: { code, message } }, status);
}

export function unauthorizedResponse(message = "غير مصرّح لك بتنفيذ هذا الإجراء."): Response {
  return errorResponse(message, 401, "unauthorized");
}

export function forbiddenResponse(message = "لا تملك الصلاحية الكافية لهذا الإجراء."): Response {
  return errorResponse(message, 403, "forbidden");
}

export function notFoundResponse(message = "العنصر المطلوب غير موجود."): Response {
  return errorResponse(message, 404, "not_found");
}

export function serverErrorResponse(err: unknown): Response {
  const message = err instanceof Error ? err.message : String(err);
  console.error("[edge-function-error]", message);
  return errorResponse("حدث خطأ داخلي غير متوقع في الخادم.", 500, "internal_error");
}
