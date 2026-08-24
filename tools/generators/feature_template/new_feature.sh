#!/usr/bin/env bash
# ============================================================
# tools/generators/feature_template/new_feature.sh
# يولّد هيكل ميزة جديدة كاملة تحت lib/features/<feature_name>/
# بنفس النمط المعماري المستخدَم فعلياً في كل الميزات الـ 17 الحالية
# (Cubit + Sealed State بثلاث حالات + Barrel File + شاشات
# mobile/desktop اختيارية) — انظر
# docs/architecture/01_overview.md#إدارة-الحالة-عبر-cubit قبل الاستخدام.
#
# الاستخدام:
#   ./tools/generators/feature_template/new_feature.sh <feature_name>
#
# مثال:
#   ./tools/generators/feature_template/new_feature.sh inspections
#   → ينشئ lib/features/inspections/ بكل الملفات، بأسماء الأصناف
#     InspectionsCubit / InspectionsState / InspectionsData ... إلخ.
#
# <feature_name> يجب أن يكون snake_case (أحرف صغيرة + شرطة سفلية فقط).
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

info() { printf '\033[1;34m[generator]\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m[خطأ]\033[0m %s\n' "$1"; exit 1; }

if [ $# -ne 1 ]; then
  fail "الاستخدام: $0 <feature_name>  (مثال: $0 inspections)"
fi

FEATURE_NAME="$1"

if ! [[ "${FEATURE_NAME}" =~ ^[a-z][a-z0-9_]*$ ]]; then
  fail "اسم الميزة يجب أن يكون snake_case صحيح (أحرف صغيرة/أرقام/شرطة سفلية، يبدأ بحرف): ${FEATURE_NAME}"
fi

DEST_DIR="${ROOT_DIR}/lib/features/${FEATURE_NAME}"

if [ -d "${DEST_DIR}" ]; then
  fail "المجلد ${DEST_DIR} موجود مسبقاً — اختر اسماً آخر أو احذفه يدوياً أولاً"
fi

# تحويل snake_case → PascalCase (مثال: field_reports → FieldReports)
PASCAL_NAME="$(echo "${FEATURE_NAME}" | awk -F'_' '{
  out = "";
  for (i = 1; i <= NF; i++) {
    part = $i;
    first = toupper(substr(part, 1, 1));
    rest = substr(part, 2);
    out = out first rest;
  }
  print out;
}')"

info "إنشاء ميزة جديدة: ${FEATURE_NAME}  (الصنف: ${PASCAL_NAME}Cubit)"

TEMPLATE_DIR="${SCRIPT_DIR}/lib/features/__feature_name__"

# ينسخ كل ملفات .tpl من القالب إلى الوجهة، مستبدلاً:
#   __feature_name__  → اسم الميزة (snake_case)
#   __FeatureName__    → اسم الصنف (PascalCase)
# في كل من مسار الملف واسمه ومحتواه، ويحذف امتداد .tpl.
while IFS= read -r -d '' TPL_FILE; do
  REL_PATH="${TPL_FILE#"${TEMPLATE_DIR}"/}"
  REL_PATH="${REL_PATH%.tpl}"
  REL_PATH="${REL_PATH//__feature_name__/${FEATURE_NAME}}"

  DEST_FILE="${DEST_DIR}/${REL_PATH}"
  mkdir -p "$(dirname "${DEST_FILE}")"

  sed \
    -e "s/__FeatureName__/${PASCAL_NAME}/g" \
    -e "s/__feature_name__/${FEATURE_NAME}/g" \
    "${TPL_FILE}" > "${DEST_FILE}"

  info "  + lib/features/${FEATURE_NAME}/${REL_PATH}"
done < <(find "${TEMPLATE_DIR}" -name '*.tpl' -print0)

echo
info "اكتمل التوليد ✅"
echo
info "الخطوات التالية اليدوية المطلوبة:"
echo "  1) أنشئ الكيانات/عقود Repository/UseCases الفعلية في domain/ إن لم تكن موجودة."
echo "  2) نفّذ Repository في data/repositories_impl/${FEATURE_NAME}_repository_impl.dart"
echo "     (محلي أولاً ← Outbox ← مزامنة — انظر docs/architecture/06_offline_first.md)."
echo "  3) استبدل كل تعليقات TODO في الملفات المولَّدة تحت"
echo "     lib/features/${FEATURE_NAME}/ ببيانات/منطق ميزتك الفعلية."
echo "  4) سجّل ${PASCAL_NAME}Cubit في core/di/features_module.dart —"
echo "     استخدم tools/generators/feature_template/di_snippet.dart.tpl كنقطة بداية."
echo "  5) أضف مساراً (Route) للميزة في navigation/app_router.dart، مع"
echo "     أي حراسة (Guard) صلاحية مناسبة."
echo "  6) أضف سياسة RLS مطابقة في backend/supabase/migrations/ لأي"
echo "     صلاحية جديدة (انظر docs/security/rls_policies.md)."
echo "  7) أضف اختبارات تحت test/unit/ و test/widget/features/${FEATURE_NAME}/."
