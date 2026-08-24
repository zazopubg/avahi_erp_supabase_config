#!/usr/bin/env bash
# ============================================================
# tools/scripts/generate_l10n.sh
# يولّد أصناف الترجمة (AppLocalizations) من ملفات .arb الموجودة في
# assets/l10n/ (app_ar.arb الافتراضية بترميز @@locale: "ar"، وapp_en.arb)
# عبر أداة Flutter المدمجة `flutter gen-l10n`.
#
# شغّله بعد أي تعديل/إضافة مفتاح ترجمة جديد في أحد ملفي .arb.
#
# الاستخدام:
#   ./tools/scripts/generate_l10n.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

info() { printf '\033[1;34m[l10n]\033[0m %s\n' "$1"; }

L10N_CONFIG="l10n.yaml"

# ينشئ l10n.yaml افتراضياً إن لم يكن موجوداً — يطابق بنية assets/l10n/
# الحالية (app_ar.arb هي الملف القالبي الأساسي حسب @@locale: "ar").
if [ ! -f "${L10N_CONFIG}" ]; then
  info "لا يوجد ${L10N_CONFIG} — إنشاء إعداد افتراضي يطابق assets/l10n/..."
  cat > "${L10N_CONFIG}" <<'EOF'
# إعداد توليد الترجمة — تُدار تلقائياً عبر
# tools/scripts/generate_l10n.sh، عدّله يدوياً بحذر.
arb-dir: assets/l10n
template-arb-file: app_ar.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/ui/l10n/generated
synthetic-package: false
nullable-getter: false
EOF
fi

info "التحقق من ملفات .arb..."
for f in assets/l10n/app_ar.arb assets/l10n/app_en.arb; do
  if [ ! -f "${f}" ]; then
    info "تحذير: ${f} غير موجود"
  fi
done

info "توليد أصناف AppLocalizations عبر flutter gen-l10n..."
flutter gen-l10n

info "اكتمل التوليد ✅ — الملفات في lib/ui/l10n/generated/"
info "تذكّر: أي مفتاح جديد يُضاف إلى app_ar.arb (الملف القالبي) أولاً، ثم app_en.arb بنفس المفتاح."
