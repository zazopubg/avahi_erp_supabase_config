#!/usr/bin/env bash
# ============================================================
# 00-run-migrations-and-seed.sh
# يُنفَّذ تلقائياً من صورة postgres الرسمية عند أول تهيئة لقاعدة
# البيانات (docker-entrypoint-initdb.d). يطبّق كل ملفات
# backend/supabase/migrations/ بالترتيب الأبجدي (000..020)، ثم كل
# ملفات backend/supabase/seed/ (001..005)، عبر psql بنفس الاتصال
# المحلي (المستخدم postgres، من داخل الشبكة الداخلية لحاوية db فقط).
#
# ⚠️ لا يُشغَّل هذا الملف إطلاقاً إن كان مجلد بيانات Postgres (volume
# db-data) موجوداً مسبقاً من تشغيل سابق — تماماً كسلوك postgres
# الافتراضي لكل سكربتات initdb.d. لإعادة التطبيق من الصفر استخدم:
#   docker compose down -v && docker compose up
# ============================================================

set -euo pipefail

echo ">> [avahi] تطبيق الهجرات (migrations)..."
for f in /docker-entrypoint-initdb.d/migrations/*.sql; do
  echo "   - $(basename "$f")"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done

echo ">> [avahi] تطبيق البيانات التجريبية (seed)..."
for f in /docker-entrypoint-initdb.d/seed/*.sql; do
  echo "   - $(basename "$f")"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done

echo ">> [avahi] اكتملت تهيئة قاعدة البيانات بنجاح."
