#!/usr/bin/env bash
# ============================================================
# tools/scripts/run_web.sh
# يشغّل تطبيق Avahi على Chrome — المنصة الوحيدة المستهدَفة حالياً.
# غلاف بسيط فوق `flutter run -d chrome` مع تحقق مسبق من توفر Chrome
# وتوليد الأكواد إن كانت الملفات المولَّدة (*.g.dart) مفقودة، ويحقن
# قيم Supabase (SUPABASE_URL/SUPABASE_ANON_KEY) تلقائياً من
# dart_define.json إن وُجد في جذر المشروع.
#
# الاستخدام:
#   ./tools/scripts/run_web.sh              # وضع تطوير عادي (debug)
#   ./tools/scripts/run_web.sh --release    # وضع إنتاج محلي (release)
#   ./tools/scripts/run_web.sh --port 8080  # منفذ مخصص
#
# الإعداد الأول (مرة واحدة):
#   cp dart_define.example.json dart_define.json
#   # ثم عدّل SUPABASE_URL/SUPABASE_ANON_KEY داخل dart_define.json
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

info() { printf '\033[1;34m[run]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[تحذير]\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m[خطأ]\033[0m %s\n' "$1"; exit 1; }

MODE="debug"
PORT=""
DART_DEFINE_FILE="dart_define.json"

while [ $# -gt 0 ]; do
  case "$1" in
    --release) MODE="release" ;;
    --port)
      shift
      PORT="$1"
      ;;
    *) fail "خيار غير معروف: $1" ;;
  esac
  shift
done

command -v flutter >/dev/null 2>&1 || fail "Flutter SDK غير مثبَّت"

info "التحقق من توفر Chrome كجهاز هدف..."
if ! flutter devices | grep -qi "chrome"; then
  warn "لم يُعثَر على Chrome ضمن أجهزة Flutter المتاحة."
  warn "تأكد من تثبيت Google Chrome، أو حدّد مساره عبر متغيّر البيئة CHROME_EXECUTABLE."
fi

# تحقق سريع من وجود ملفات مولَّدة أساسية؛ إن غابت، ذكّر المستخدم
if ! find lib -name "*.g.dart" -print -quit | grep -q .; then
  warn "لا توجد ملفات .g.dart مولَّدة — شغّل 'make gen' أولاً إن واجهت أخطاء بناء"
fi

FLUTTER_ARGS=(run -d chrome)

if [ -f "${DART_DEFINE_FILE}" ]; then
  FLUTTER_ARGS+=(--dart-define-from-file="${DART_DEFINE_FILE}")
  info "تحميل قيم Supabase من ${DART_DEFINE_FILE}..."
else
  warn "${DART_DEFINE_FILE} غير موجود — سيفشل الإقلاع عند تهيئة Supabase."
  warn "نفّذ: cp dart_define.example.json ${DART_DEFINE_FILE} ثم عدّل القيم."
fi

if [ "${MODE}" = "release" ]; then
  FLUTTER_ARGS+=(--release)
  info "تشغيل بوضع الإنتاج المحلي (release)..."
else
  info "تشغيل بوضع التطوير (debug، مع Hot Reload)..."
fi

if [ -n "${PORT}" ]; then
  FLUTTER_ARGS+=(--web-port "${PORT}")
  info "المنفذ: ${PORT}"
fi

exec flutter "${FLUTTER_ARGS[@]}"
