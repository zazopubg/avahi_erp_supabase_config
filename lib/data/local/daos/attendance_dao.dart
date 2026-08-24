import 'package:drift/drift.dart';

import '../local_database.dart';
import '../tables/attendance_table.dart';

part 'attendance_dao.g.dart';

/// عمليات الوصول لجدول [AttendanceTable] المحلي (`local_attendance`).
@DriftAccessor(tables: <Type>[AttendanceTable])
class AttendanceDao extends DatabaseAccessor<LocalDatabase>
    with _$AttendanceDaoMixin {
  AttendanceDao(super.db);

  /// سجل حضور اليوم الحالي لمستخدم معيّن، إن وُجد — الاستعلام الأكثر
  /// استخداماً في شاشة الحضور (Prompt 15): يُستدعى عند فتح الشاشة
  /// لتحديد ما إذا كان الزر المعروض "تسجيل حضور" أو "تسجيل انصراف".
  /// يعتمد على [AttendanceTable.checkInAt] ضمن حدود اليوم بالتوقيت
  /// المحلي للجهاز.
  Future<AttendanceRow?> getTodayRecordForUser(String userId) {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(attendanceTable)
          ..where((AttendanceTable t) => t.userId.equals(userId))
          ..where((AttendanceTable t) => t.isDeletedLocally.equals(false))
          ..where(
            (AttendanceTable t) =>
                t.checkInAt.isBiggerOrEqualValue(startOfDay) &
                t.checkInAt.isSmallerThanValue(endOfDay),
          )
          ..orderBy(<OrderingTerm Function(AttendanceTable)>[
            (AttendanceTable t) =>
                OrderingTerm(expression: t.checkInAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// بث حي لسجل حضور اليوم الحالي لمستخدم معيّن — لتحديث زر
  /// حضور/انصراف فور تغيّر الحالة محلياً (مثال: بعد استرداد الاتصال
  /// ومزامنة سجل مُعتمَد من مشرف آخر عبر Realtime).
  Stream<AttendanceRow?> watchTodayRecordForUser(String userId) {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(attendanceTable)
          ..where((AttendanceTable t) => t.userId.equals(userId))
          ..where((AttendanceTable t) => t.isDeletedLocally.equals(false))
          ..where(
            (AttendanceTable t) =>
                t.checkInAt.isBiggerOrEqualValue(startOfDay) &
                t.checkInAt.isSmallerThanValue(endOfDay),
          )
          ..orderBy(<OrderingTerm Function(AttendanceTable)>[
            (AttendanceTable t) =>
                OrderingTerm(expression: t.checkInAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// سجلات مستخدم ضمن مدى تاريخي (لتقرير الحضور الشهري مثلاً).
  Future<List<AttendanceRow>> getRecordsForUserInRange(
    String userId,
    DateTime from,
    DateTime to,
  ) {
    return (select(attendanceTable)
          ..where((AttendanceTable t) => t.userId.equals(userId))
          ..where(
            (AttendanceTable t) =>
                t.checkInAt.isBiggerOrEqualValue(from) &
                t.checkInAt.isSmallerOrEqualValue(to),
          )
          ..orderBy(<OrderingTerm Function(AttendanceTable)>[
            (AttendanceTable t) =>
                OrderingTerm(expression: t.checkInAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// سجلات مشروع كامل ضمن مدى تاريخي — نسخة مخبّأة (Best-effort) تُستخدم
  /// فقط عند انقطاع الاتصال كبديل احتياطي لاستعلام السحابة المباشر
  /// (`AttendanceSummaryQueries`/الاستعلام السحابي المباشر)، إذ لا
  /// يضمن التخزين المحلي وجود سجلات كل أعضاء المشروع (فقط ما زامنه
  /// هذا الجهاز فعلياً). 🆕
  Future<List<AttendanceRow>> getRecordsForProjectInRange(
    String projectId,
    DateTime from,
    DateTime to,
  ) {
    return (select(attendanceTable)
          ..where((AttendanceTable t) => t.projectId.equals(projectId))
          ..where(
            (AttendanceTable t) =>
                t.checkInAt.isBiggerOrEqualValue(from) &
                t.checkInAt.isSmallerOrEqualValue(to),
          )
          ..orderBy(<OrderingTerm Function(AttendanceTable)>[
            (AttendanceTable t) =>
                OrderingTerm(expression: t.checkInAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<AttendanceRow?> getById(String id) {
    return (select(attendanceTable)
          ..where((AttendanceTable t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<AttendanceRow>> getPendingSync() {
    return (select(attendanceTable)
          ..where((AttendanceTable t) => t.syncState.equals('synced').not()))
        .get();
  }

  Future<void> upsertAttendance(AttendanceTableCompanion entry) {
    return into(attendanceTable).insertOnConflictUpdate(entry);
  }

  /// يسجّل وقت الانصراف لسجل موجود مسبقاً ويعلّمه كمعلّق المزامنة.
  Future<void> checkOut(
    String id, {
    required DateTime checkOutAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
  }) {
    return (update(attendanceTable)
          ..where((AttendanceTable t) => t.id.equals(id)))
        .write(
      AttendanceTableCompanion(
        checkOutAt: Value<DateTime?>(checkOutAt),
        checkOutLatitude: Value<double?>(checkOutLatitude),
        checkOutLongitude: Value<double?>(checkOutLongitude),
        syncState: const Value<String>('pending'),
        updatedAt: Value<DateTime>(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markSyncState(String id, String syncState) {
    return (update(attendanceTable)
          ..where((AttendanceTable t) => t.id.equals(id)))
        .write(AttendanceTableCompanion(syncState: Value<String>(syncState)));
  }
}
