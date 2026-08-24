/// ملف تجميعي (Barrel File) لطبقة قاعدة البيانات المحلية
/// `data/local/`، لتسهيل الاستيراد عبر سطر واحد:
/// `import 'package:avahi/data/local/local.dart';`
///
/// يُصدِّر [LocalDatabase] فقط (وليس الجداول/DAOs الفردية بشكل مباشر
/// هنا) لأنها جميعاً أعضاء (`part`/mixins مولَّدة) داخل [LocalDatabase]
/// نفسها ويمكن الوصول إليها عبر خصائصها (مثال: `db.taskDao`،
/// `db.attendanceTable`). لاستيراد صفوف/جداول محدّدة مباشرة (مثال:
/// ضمن اختبارات الوحدة)، استورد ملفات `tables/tables.dart` أو
/// `daos/daos.dart` مباشرة.
library;

export 'local_database.dart';
export 'migrations/database_migrations.dart';
