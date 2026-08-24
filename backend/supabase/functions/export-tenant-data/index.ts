// ============================================================
// export-tenant-data/index.ts
// 🆕 (Prompt 28) — يصدّر كامل بيانات مستأجر (شركة) واحد كأرشيف JSON
// واحد لأغراض الأرشفة/الامتثال، ويرفعه إلى مخزن خاص
// (`ApiConstants.bucketTenantExports` — `tenant-exports` في Flutter)
// ثم يعيد رابطاً موقّتاً موقَّعاً (Signed URL) صالحاً لمدة ساعة واحدة
// فقط. محصور بصلاحية platformOwner فقط (نفس نمط التحقق تماماً في
// create-company/index.ts و soft-delete-tenant/index.ts).
//
// لا يُصدَّر المحتوى الثنائي الفعلي للملفات (صور/مستندات) نفسه —
// فقط بيانات الصفوف الوصفية (metadata) لكل الجداول، بما فيها روابط
// `storage_path` الأصلية لكل صورة/مستند (تبقى قابلة للوصول لاحقاً عبر
// نفس آلية `photo_storage_service.dart`/`document_storage_service.dart`
// العادية إن احتاج الأرشيف نفسه لاحقاً) — تفادياً لأرشيف ضخم قد يبلغ
// عشرات الجيجابايت لمستأجر واحد كبير.
//
// POST body:
// {
//   "company_id": "uuid"
// }
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

const EXPORT_BUCKET = "tenant-exports";
const SIGNED_URL_TTL_SECONDS = 60 * 60; // ساعة واحدة

/// أسماء كل الجداول المُصدَّرة، مرتبطة بالشركة عبر عمود `company_id`
/// مباشرة — بنفس الترتيب الزمني لإنشائها ضمن `backend/supabase/migrations/`
/// (Prompt 03، 001 حتى 020). `audit_logs` نفسها مُضمَّنة أيضاً (سجل
/// تدقيق هذا المستأجر وحده، لا كل المنصّة).
const EXPORTED_TABLES: readonly string[] = [
  "company_members",
  "projects",
  "project_members",
  "project_milestones",
  "tasks",
  "attendance",
  "field_reports",
  "punch_items",
  "photos",
  "documents",
  "equipment",
  "notifications",
  "leave_requests",
  "audit_logs",
];

interface ExportTenantDataPayload {
  company_id: string;
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
      return forbiddenResponse("تصدير بيانات مستأجر متاح فقط لمالكي المنصة (platformOwner).");
    }

    // ── 2) التحقق من صحة المدخلات ─────────────────────────────
    let payload: ExportTenantDataPayload;
    try {
      payload = await req.json();
    } catch {
      return errorResponse("جسم الطلب يجب أن يكون JSON صالحاً.");
    }

    if (!payload.company_id?.trim()) {
      return errorResponse("حقل company_id مطلوب.");
    }

    const companyId = payload.company_id.trim();

    const { data: company, error: companyError } = await supabaseAdmin
      .from("companies")
      .select("*")
      .eq("id", companyId)
      .maybeSingle();

    if (companyError) throw companyError;
    if (!company) return notFoundResponse("لا يوجد مستأجر بهذا المعرّف.");

    // ── 3) جمع بيانات كل جدول مرتبط بهذه الشركة ────────────────
    const exportedTables: Record<string, unknown[]> = {};
    for (const table of EXPORTED_TABLES) {
      const { data: rows, error: tableError } = await supabaseAdmin
        .from(table)
        .select("*")
        .eq("company_id", companyId);

      if (tableError) {
        // لا نفشل التصدير كاملاً بسبب جدول واحد (مثال: عمود مُعاد
        // تسميته لاحقاً) — نسجّل الجدول فارغاً مع تحذير في السجلات،
        // بدل حجب بقية البيانات المُصدَّرة بنجاح.
        console.error(`[export-tenant-data] فشل تصدير جدول ${table}:`, tableError.message);
        exportedTables[table] = [];
        continue;
      }
      exportedTables[table] = rows ?? [];
    }

    const exportPayload = {
      exported_at: new Date().toISOString(),
      exported_by: user.id,
      company,
      tables: exportedTables,
    };

    // ── 4) رفع الأرشيف إلى المخزن الخاص ─────────────────────────
    const fileName = `${companyId}/${Date.now()}-export.json`;
    const fileBody = new TextEncoder().encode(JSON.stringify(exportPayload, null, 2));

    const { error: uploadError } = await supabaseAdmin.storage
      .from(EXPORT_BUCKET)
      .upload(fileName, fileBody, {
        contentType: "application/json",
        upsert: false,
      });

    if (uploadError) throw uploadError;

    // ── 5) توليد رابط تنزيل موقّت موقَّع ─────────────────────────
    const { data: signedUrlData, error: signedUrlError } = await supabaseAdmin.storage
      .from(EXPORT_BUCKET)
      .createSignedUrl(fileName, SIGNED_URL_TTL_SECONDS);

    if (signedUrlError || !signedUrlData) {
      throw signedUrlError ?? new Error("تعذّر توليد رابط تنزيل موقَّع للأرشيف.");
    }

    // ── 6) سجل تدقيق للعملية نفسها ────────────────────────────
    // ⚠️ عمود `action` مقيّد بقيد CHECK صارم (`audit_logs_action_check`
    // في 011_create_audit_logs.sql) يقبل فقط 'INSERT'/'UPDATE'/'DELETE'
    // — لا قيمة رابعة مثل 'EXPORT' متاحة. نسجّل هذه العملية كـ
    // 'UPDATE' على `companies` (`new_data` يحمل مسار الملف الفعلي)
    // بدل تعديل القيد نفسه (خارج نطاق Prompt 28، يقتصر على
    // `lib/features/platform_admin/` وهذه الدالة وحدها).
    await supabaseAdmin.from("audit_logs").insert({
      company_id: companyId,
      user_id: user.id,
      action: "UPDATE",
      table_name: "companies",
      record_id: companyId,
      new_data: { export_file: fileName, event: "tenant_data_exported" },
    });

    return successResponse({
      download_url: signedUrlData.signedUrl,
      expires_in_seconds: SIGNED_URL_TTL_SECONDS,
      file_name: fileName,
    });
  } catch (err) {
    return serverErrorResponse(err);
  }
});
