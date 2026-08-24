import 'package:drift/drift.dart';

import '../local_database.dart';

/// منطق ترقية مخطط قاعدة البيانات المحلية (Drift) بأمان عبر إصدارات
/// التطبيق المتعاقبة.
///
/// ملاحظة تصميم: هذا الملف **مستقل تماماً عن هجرات Supabase**
/// (`backend/supabase/migrations/`) رغم تشابه الاسم — [schemaVersion]
/// هنا يخص فقط بنية جداول Drift المحلية على جهاز المستخدم، ولا علاقة
/// له بترقيم هجرات 001–019 السحابية.
///
/// كل ترقية جديدة يجب أن:
/// 1) تزيد [LocalDatabase.schemaVersion] بمقدار 1.
/// 2) تضيف حالة `else if (from == N)` جديدة هنا تصف بالضبط الفرق بين
///    الإصدار N والإصدار N+1 (أعمدة/جداول مضافة فقط — Drift المحلي لا
///    يحتاج التعامل مع حذف بيانات المستخدم الحالية دون داعٍ).
/// 3) لا تُعدَّل حالات الإصدارات السابقة بأثر رجعي أبداً.
abstract final class DatabaseMigrations {
  static MigrationStrategy strategyFor(LocalDatabase db) {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // مثال على الشكل المتوقع لترقية مستقبلية (لا يوجد إصدار > 1
        // بعد، فهذا الجسم فارغ فعلياً حالياً):
        //
        // if (from == 1) {
        //   await m.addColumn(db.taskTable, db.taskTable.someNewColumn);
        // }
        // if (from <= 2) {
        //   await m.createTable(db.someNewTable);
        // }
      },
      beforeOpen: (OpeningDetails details) async {
        // تفعيل قيود المفاتيح الأجنبية (تحسّب لأي علاقات تُضاف
        // مستقبلاً بين الجداول المحلية)، بلا أثر عملي حالياً لأن
        // الجداول الحالية مستقلة عن بعضها بالكامل عمداً.
        await db.customStatement('PRAGMA foreign_keys = ON;');

        if (details.wasCreated) {
          // لا شيء إضافي مطلوب عند الإنشاء الأول حالياً (لا بيانات
          // ابتدائية/Seed محلية).
        }
      },
    );
  }
}
