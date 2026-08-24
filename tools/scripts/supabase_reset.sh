#!/usr/bin/env bash
# ============================================================
# tools/scripts/supabase_reset.sh
# يعيد ضبط قاعدة بيانات Supabase المحلية بالكامل من الصفر: يطبّق كل
# مهاجرات backend/supabase/migrations/ (001..020) بالترتيب، ثم كل
# بيانات backend/supabase/seed/ (001..005) التجريبية.
#
# يدعم مساري تشغيل Supabase المحليَين المذكورين في
# docs/onboarding/setup_guide.md:
#   1) عبر Supabase CLI (`supabase start`) — يُستخدَم `supabase db reset`.
#   2) عبر docker-compose مباشرة (backend/docker-compose.yml) — يُعاد
#      إنشاء حاوية/جزء بيانات (volume) قاعدة البيانات من الصفر ليُعاد
#      تشغيل backend/docker/00-run-migrations-and-seed.sh تلقائياً.
#
# ⚠️ هذا يحذف كل البيانات المحلية الحالية في قاعدة البيانات المحلية —
# لا صلة له بأي بيانات إنتاج حقيقية.
#
# الاستخدام:
#   ./tools/scripts/supabase_reset.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}/backend"

info() { printf '\033[1;34m[db-reset]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[تحذير]\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m[خطأ]\033[0m %s\n' "$1"; exit 1; }

if command -v supabase >/dev/null 2>&1 && supabase status >/dev/null 2>&1; then
  info "اكتُشف Supabase CLI نشطاً — استخدام 'supabase db reset'..."
  supabase db reset
  info "اكتمل إعادة الضبط عبر Supabase CLI ✅"
  exit 0
fi

info "لا Supabase CLI نشط — استخدام docker-compose مباشرة..."

if docker compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE="docker-compose"
else
  fail "لا Docker Compose (v2 أو v1) متوفر ولا Supabase CLI نشط"
fi

warn "سيُعاد إنشاء حاوية قاعدة البيانات المحلية بالكامل (كل البيانات الحالية ستُحذَف)."
read -r -p "متابعة؟ [y/N] " CONFIRM
case "${CONFIRM}" in
  [yY]|[yY][eE][sS]) ;;
  *) info "أُلغيَت العملية."; exit 0 ;;
esac

info "إيقاف الخدمات وحذف جزء بيانات (volume) قاعدة البيانات..."
${DOCKER_COMPOSE} down -v

info "إعادة تشغيل الخدمات (سيُعاد تطبيق المهاجرات + البيانات التجريبية تلقائياً عبر docker-entrypoint-initdb.d)..."
${DOCKER_COMPOSE} up -d

info "انتظار جاهزية Postgres..."
ATTEMPTS=0
until ${DOCKER_COMPOSE} exec -T db pg_isready -U postgres >/dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "${ATTEMPTS}" -ge 30 ]; then
    fail "Postgres لم يصبح جاهزاً بعد 60 ثانية"
  fi
  sleep 2
done

info "اكتمل إعادة الضبط ✅ — راجع السجلات للتأكد من نجاح كل خطوة:"
info "  ${DOCKER_COMPOSE} logs db | grep '\\[avahi\\]'"
