#!/usr/bin/env bash
# ============================================================
# tools/icons_generator/generate_icons.sh
# يولّد كل أيقونات الويب المطلوبة (favicon + أيقونات PWA بأحجامها
# القياسية) من صورة الشعار المصدر الواحدة assets/images/logo.png،
# ويضعها في web/icons/ و web/favicon.png (مسارات Flutter Web
# القياسية التي يقرأها web/manifest.json).
#
# يتطلب ImageMagick (أمر `convert` أو `magick`).
#
# الاستخدام:
#   ./tools/icons_generator/generate_icons.sh
#   ./tools/icons_generator/generate_icons.sh --source path/to/logo.png
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

info() { printf '\033[1;34m[icons]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[تحذير]\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m[خطأ]\033[0m %s\n' "$1"; exit 1; }

SOURCE_LOGO="assets/images/logo.png"

while [ $# -gt 0 ]; do
  case "$1" in
    --source)
      shift
      SOURCE_LOGO="$1"
      ;;
    *) fail "خيار غير معروف: $1" ;;
  esac
  shift
done

# اختر أداة ImageMagick المتاحة (v6: convert، v7: magick)
if command -v magick >/dev/null 2>&1; then
  CONVERT() { magick "$@"; }
elif command -v convert >/dev/null 2>&1; then
  CONVERT() { convert "$@"; }
else
  fail "ImageMagick غير مثبَّت (لا 'magick' ولا 'convert' متوفرين). ثبّته عبر: apt install imagemagick / brew install imagemagick"
fi

[ -f "${SOURCE_LOGO}" ] || fail "صورة الشعار المصدر غير موجودة: ${SOURCE_LOGO}"
[ -s "${SOURCE_LOGO}" ] || fail "صورة الشعار المصدر فارغة (0 بايت): ${SOURCE_LOGO} — استبدلها بشعار فعلي أولاً"

info "المصدر: ${SOURCE_LOGO}"

WEB_ICONS_DIR="web/icons"
mkdir -p "${WEB_ICONS_DIR}"

# ── Favicon ───────────────────────────────────────────────────
info "توليد favicon.png (32×32)..."
CONVERT "${SOURCE_LOGO}" -resize 32x32 web/favicon.png

# ── أيقونات PWA القياسية (تطابق web/manifest.json الافتراضي لـ Flutter) ──
declare -A PWA_ICONS=(
  ["Icon-192.png"]="192x192"
  ["Icon-512.png"]="512x512"
  ["Icon-maskable-192.png"]="192x192"
  ["Icon-maskable-512.png"]="512x512"
)

for name in "${!PWA_ICONS[@]}"; do
  size="${PWA_ICONS[${name}]}"
  info "توليد ${name} (${size})..."
  if [[ "${name}" == *maskable* ]]; then
    # الأيقونات القابلة للقص (Maskable) تحتاج هامش أمان ~10% حول
    # الشعار حتى لا يُقصّ محتواه عند تطبيق أشكال أنظمة تشغيل مختلفة
    # (دائرية/مربعة الزوايا/إلخ) فوقها.
    CONVERT "${SOURCE_LOGO}" \
      -resize "$(( ${size%%x*} * 80 / 100 ))x$(( ${size##*x} * 80 / 100 ))" \
      -gravity center -background none -extent "${size}" \
      "${WEB_ICONS_DIR}/${name}"
  else
    CONVERT "${SOURCE_LOGO}" -resize "${size}" "${WEB_ICONS_DIR}/${name}"
  fi
done

# ── أيقونات Apple Touch (iOS/iPadOS عند إضافة التطبيق للشاشة الرئيسية) ──
info "توليد apple-touch-icon.png (180×180)..."
CONVERT "${SOURCE_LOGO}" -resize 180x180 -background white -flatten \
  web/apple-touch-icon.png 2>/dev/null || \
  CONVERT "${SOURCE_LOGO}" -resize 180x180 web/apple-touch-icon.png

info "اكتمل توليد كل الأيقونات ✅"
info "الملفات المولَّدة:"
info "  - web/favicon.png"
info "  - web/apple-touch-icon.png"
for name in "${!PWA_ICONS[@]}"; do
  info "  - ${WEB_ICONS_DIR}/${name}"
done
info "تأكد من مطابقة أسماء هذه الملفات لما هو مُعرَّف في web/manifest.json و web/index.html."
