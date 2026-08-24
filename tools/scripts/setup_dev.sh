#!/usr/bin/env bash
# ============================================================
# tools/scripts/setup_dev.sh
# يجهّز بيئة تطوير Avahi كاملة من الصفر بضربة واحدة:
# تحقق من المتطلبات → تثبيت حزم Flutter → تشغيل Supabase محلياً
# عبر Docker Compose → تطبيق المهاجرات والبيانات التجريبية →
# توليد الأكواد (build_runner).
#
# الاستخدام:
#   ./tools/scripts/setup_dev.sh
#
# راجع docs/onboarding/setup_guide.md للتفاصيل الكاملة لكل خطوة.
# ============================================================
set -euo pipefail

# الانتقال لجذر المشروع بصرف النظر عن مكان استدعاء السكربت
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

info()  { printf '\033[1;34m[setup]\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m[تحذير]\033[0m %s\n' "$1"; }
fail()  { printf '\033[1;31m[خطأ]\033[0m %s\n' "$1"; exit 1; }

info "التحقق من المتطلبات الأساسية..."

command -v flutter >/dev/null 2>&1 || fail "Flutter SDK غير مثبَّت. راجع docs/onboarding/setup_guide.md"
command -v docker  >/dev/null 2>&1 || fail "Docker غير مثبَّت. مطلوب لتشغيل Supabase محلياً"

if docker compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE="docker-compose"
else
  fail "لا Docker Compose (v2 أو v1) متوفر"
fi

info "Flutter: $(flutter --version | head -n 1)"
info "Docker: $(docker --version)"

info "تفعيل دعم الويب في Flutter..."
flutter config --enable-web >/dev/null

info "تثبيت حزم Flutter (flutter pub get)..."
flutter pub get

if [ ! -f "backend/.env" ]; then
  info "إنشاء backend/.env من القالب backend/.env.example..."
  cp backend/.env.example backend/.env
  warn "استخدمت القيم الافتراضية للتطوير المحلي — لا تستخدمها في أي بيئة حقيقية"
else
  info "backend/.env موجود مسبقاً، لن يُستبدَل"
fi

info "تشغيل خدمات Supabase محلياً عبر Docker Compose..."
(cd backend && ${DOCKER_COMPOSE} up -d)

info "انتظار جاهزية Postgres..."
ATTEMPTS=0
until (cd backend && ${DOCKER_COMPOSE} exec -T db pg_isready -U postgres) >/dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "${ATTEMPTS}" -ge 30 ]; then
    fail "Postgres لم يصبح جاهزاً بعد 60 ثانية — تحقق من: docker compose logs (داخل backend/)"
  fi
  sleep 2
done
info "Postgres جاهز."

info "تطبيق المهاجرات والبيانات التجريبية..."
"${SCRIPT_DIR}/supabase_reset.sh"

info "توليد الأكواد (build_runner: freezed/injectable/drift)..."
dart run build_runner build --delete-conflicting-outputs

info "توليد ملفات الترجمة (l10n)..."
"${SCRIPT_DIR}/generate_l10n.sh"

echo
info "اكتمل الإعداد بنجاح ✅"
info "Supabase Studio:  http://localhost:54323"
info "البريد التجريبي:   http://localhost:54324"
info "لتشغيل التطبيق:    ./tools/scripts/run_web.sh   (أو make run)"
