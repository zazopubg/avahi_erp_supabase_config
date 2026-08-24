#!/usr/bin/env bash
# ============================================================
# tools/scripts/run_tests.sh
# يشغّل خط التحقق الكامل قبل أي Commit/Pull Request:
# تنسيق الكود → تحليله (lint صارم) → كل الاختبارات (unit/widget/
# golden/integration) — بنفس ترتيب `docs/onboarding/coding_standards.md`
# القسم 7.
#
# الاستخدام:
#   ./tools/scripts/run_tests.sh            # الخط الكامل
#   ./tools/scripts/run_tests.sh --unit      # اختبارات unit فقط
#   ./tools/scripts/run_tests.sh --widget    # اختبارات widget فقط
#   ./tools/scripts/run_tests.sh --golden    # اختبارات golden فقط
#   ./tools/scripts/run_tests.sh --integration  # اختبارات integration فقط
#   ./tools/scripts/run_tests.sh --no-analyze   # تخطي flutter analyze
#   ./tools/scripts/run_tests.sh --coverage     # مع تقرير تغطية
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

info() { printf '\033[1;34m[test]\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m[فشل]\033[0m %s\n' "$1"; exit 1; }

RUN_ANALYZE=true
COVERAGE=false
TEST_PATH="test/"

for arg in "$@"; do
  case "${arg}" in
    --unit)        TEST_PATH="test/unit/" ;;
    --widget)      TEST_PATH="test/widget/" ;;
    --golden)      TEST_PATH="test/golden/" ;;
    --integration) TEST_PATH="test/integration/" ;;
    --no-analyze)  RUN_ANALYZE=false ;;
    --coverage)    COVERAGE=true ;;
    *) fail "خيار غير معروف: ${arg}" ;;
  esac
done

info "تنسيق الكود (dart format)..."
dart format --set-exit-if-changed lib/ test/ || {
  fail "الكود غير منسَّق — شغّل: dart format lib/ test/ ثم أعد المحاولة"
}

if [ "${RUN_ANALYZE}" = true ]; then
  info "تحليل الكود (flutter analyze)..."
  flutter analyze || fail "flutter analyze فشل — أصلح كل الأخطاء والتحذيرات أولاً"
fi

info "تشغيل الاختبارات: ${TEST_PATH}"
if [ "${COVERAGE}" = true ]; then
  flutter test "${TEST_PATH}" --coverage
  info "تقرير التغطية في coverage/lcov.info"
  if command -v genhtml >/dev/null 2>&1; then
    genhtml coverage/lcov.info -o coverage/html >/dev/null
    info "تقرير HTML: coverage/html/index.html"
  fi
else
  flutter test "${TEST_PATH}"
fi

info "كل الفحوصات نجحت ✅"
