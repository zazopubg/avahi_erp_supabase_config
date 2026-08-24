import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/attendance_dao.dart';
import 'daos/equipment_dao.dart';
import 'daos/leave_dao.dart';
import 'daos/notification_dao.dart';
import 'daos/outbox_dao.dart';
import 'daos/photo_dao.dart';
import 'daos/report_dao.dart';
import 'daos/task_dao.dart';
import 'migrations/database_migrations.dart';
import 'tables/attendance_table.dart';
import 'tables/equipment_table.dart';
import 'tables/leave_request_table.dart';
import 'tables/notification_table.dart';
import 'tables/outbox_table.dart';
import 'tables/photo_queue_table.dart';
import 'tables/report_table.dart';
import 'tables/task_table.dart';

part 'local_database.g.dart';

/// اسم ملف/قاعدة بيانات Drift المحلية على القرص (Native) أو
/// IndexedDB (Web). لا صلة له بأسماء قاعدة بيانات Supabase السحابية —
/// هذه القاعدة مستقلة تماماً عن Supabase (انظر توثيق كل جدول ضمن
/// `data/local/tables/`).
const String _kLocalDatabaseName = 'avahi_local';

/// قاعدة البيانات المحلية الموحّدة للتطبيق (Drift)، تعمل على كل
/// المنصات المستهدفة بما فيها الويب عبر `sqlite3.wasm`/IndexedDB
/// (حزمة `drift_flutter`، انظر `pubspec.yaml`).
///
/// هذه الطبقة بأكملها (`lib/data/local/`) **مستقلة تماماً عن
/// Supabase**: لا تستورد أي شيء من `data/cloud/` أو `data/dto/`. دمج
/// المصدرين (محلي + سحابي) ضمن مستودع واحد يطبّق واجهات
/// `domain/repositories/` سيتم لاحقاً في `data/repositories_impl/`
/// (Prompt 10)، وسياسات المزامنة نفسها (متى/كيف تُرسَل بيانات
/// [OutboxTable] للسحابة) في `data/sync/` (Prompt 09).
@DriftDatabase(
  tables: <Type>[
    TaskTable,
    AttendanceTable,
    ReportTable,
    PhotoQueueTable,
    OutboxTable,
    EquipmentTable,
    NotificationTable,
    LeaveRequestTable,
  ],
  daos: <Type>[
    TaskDao,
    AttendanceDao,
    ReportDao,
    PhotoDao,
    OutboxDao,
    EquipmentDao,
    NotificationDao,
    LeaveDao,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  /// المُنشئ الافتراضي المستخدم فعلياً في التطبيق — يفتح اتصالاً حقيقياً
  /// (ملف SQLite على الجوال/سطح المكتب، أو WASM+IndexedDB على الويب).
  LocalDatabase() : super(_openConnection());

  /// منشئ بديل لحقن اتصال جاهز مباشرة (مثال: `NativeDatabase.memory()`
  /// داخل اختبارات الوحدة في `test/`، Prompt 29؛ أو لإعادة استخدام
  /// اتصال مُهيَّأ مسبقاً من `core/di/`، Prompt 11).
  LocalDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => DatabaseMigrations.strategyFor(this);
}

/// يفتح اتصال Drift المناسب للمنصة الحالية عبر `drift_flutter`:
/// - الويب: `sqlite3.wasm` + IndexedDB (يتطلب نسخ `sqlite3.wasm` و
///   `drift_worker.js.js` إلى `web/` — انظر ملاحظة أسفل الملف).
/// - الجوال/سطح المكتب: ملف SQLite ضمن مجلد بيانات التطبيق (تُحدَّد
///   تلقائياً داخلياً عبر `path_provider`، بلا حاجة لتمرير مسار يدوي
///   هنا).
QueryExecutor _openConnection() {
  return driftDatabase(
    name: _kLocalDatabaseName,
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js.js'),
    ),
  );
}

// ⚠️ ملاحظة بناء (Web فقط): يتطلب هذا الإعداد وجود ملفي
// `sqlite3.wasm` و `drift_worker.js.js` داخل مجلد `web/` عند البناء
// لمنصة الويب (يُنسخان عادة عبر `dart run drift_dev make-web-assets`
// أو يدوياً من `sqlite3` الموزّعة). هذا خارج نطاق هذه الخطوة (Prompt
// 08) ويجب توثيقه لاحقاً في `docs/` (Prompt 30) أو `Makefile`
// (Prompt 00، يمكن ترقيعه عند الحاجة).
