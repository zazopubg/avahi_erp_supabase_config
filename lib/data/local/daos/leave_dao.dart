import 'package:drift/drift.dart';

import '../local_database.dart';
import '../tables/leave_request_table.dart';

part 'leave_dao.g.dart';

/// عمليات الوصول لجدول [LeaveRequestTable] المحلي
/// (`local_leave_requests`). 🆕
@DriftAccessor(tables: <Type>[LeaveRequestTable])
class LeaveDao extends DatabaseAccessor<LocalDatabase>
    with _$LeaveDaoMixin {
  LeaveDao(super.db);

  Future<List<LeaveRequestRow>> getAllForUser(String userId) {
    return (select(leaveRequestTable)
          ..where((LeaveRequestTable t) => t.userId.equals(userId))
          ..where((LeaveRequestTable t) => t.isDeletedLocally.equals(false))
          ..orderBy(<OrderingTerm Function(LeaveRequestTable)>[
            (LeaveRequestTable t) =>
                OrderingTerm(expression: t.startDate, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Stream<List<LeaveRequestRow>> watchAllForUser(String userId) {
    return (select(leaveRequestTable)
          ..where((LeaveRequestTable t) => t.userId.equals(userId))
          ..where((LeaveRequestTable t) => t.isDeletedLocally.equals(false))
          ..orderBy(<OrderingTerm Function(LeaveRequestTable)>[
            (LeaveRequestTable t) =>
                OrderingTerm(expression: t.startDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// الطلبات بانتظار اعتماد مسؤول ضمن الشركة (`status = pending`) —
  /// لشاشة "طلبات بانتظار موافقتي".
  Future<List<LeaveRequestRow>> getPendingApprovalForCompany(
    String companyId,
  ) {
    return (select(leaveRequestTable)
          ..where((LeaveRequestTable t) => t.companyId.equals(companyId))
          ..where((LeaveRequestTable t) => t.status.equals('pending')))
        .get();
  }

  /// طلبات مستخدم تتداخل زمنياً مع مدى تاريخي معيّن، مستثنية الطلبات
  /// المرفوضة/الملغاة — تدعم [ILeaveRepository.getOverlappingLeaveRequests]
  /// (`domain/repositories/`، Prompt 06) المُستخدمة من [LeaveValidator]
  /// لمنع تقديم طلبين متداخلين. ⚠️ [Prompt 10] ترقيع: أُضيفت هذه
  /// الدالة هنا (بدل تصفية القائمة الكاملة في `data/repositories_impl/`)
  /// لأن هذا الفحص يُستدعى من UseCase التحقق قبل كل تقديم طلب، فمن
  /// الأنسب أداءً أن يبقى الاستعلام على مستوى SQL بدل تحميل كل طلبات
  /// المستخدم إلى الذاكرة في كل مرة.
  Future<List<LeaveRequestRow>> getOverlappingForUser({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return (select(leaveRequestTable)
          ..where((LeaveRequestTable t) => t.userId.equals(userId))
          ..where(
            (LeaveRequestTable t) =>
                t.status.equals('rejected').not() &
                t.status.equals('cancelled').not(),
          )
          ..where(
            (LeaveRequestTable t) =>
                t.startDate.isSmallerOrEqualValue(endDate) &
                t.endDate.isBiggerOrEqualValue(startDate),
          ))
        .get();
  }

  /// **كل** طلبات إجازة شركة معيّنة (كل الحالات معاً)، الأحدث أولاً
  /// حسب `createdAt` — تدعم [ILeaveRepository.getCompanyLeaveRequests]
  /// (`domain/repositories/`، Prompt 24) المستخدمة من
  /// `leave_requests_inbox.dart`. بخلاف [getPendingApprovalForCompany]
  /// أعلاه (تصفية `pending` فقط على مستوى SQL، مستخدَمة لأي عدّاد/
  /// شارة مستقبلية لا تحتاج التبديل بين الحالات)، هذه الدالة تجلب كل
  /// السجلات دفعة واحدة لأن الشاشة تحتاج التبديل بين تبويبات/فلاتر
  /// حالة متعددة محلياً دون إعادة استعلام SQL في كل مرة. 🆕
  Future<List<LeaveRequestRow>> getAllForCompany(String companyId) {
    return (select(leaveRequestTable)
          ..where((LeaveRequestTable t) => t.companyId.equals(companyId))
          ..orderBy(<OrderingTerm Function(LeaveRequestTable)>[
            (LeaveRequestTable t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<LeaveRequestRow?> getById(String id) {
    return (select(leaveRequestTable)
          ..where((LeaveRequestTable t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<LeaveRequestRow>> getPendingSync() {
    return (select(leaveRequestTable)
          ..where(
            (LeaveRequestTable t) => t.syncState.equals('synced').not(),
          ))
        .get();
  }

  Future<void> upsertLeaveRequest(LeaveRequestTableCompanion entry) {
    return into(leaveRequestTable).insertOnConflictUpdate(entry);
  }

  Future<void> markSyncState(String id, String syncState) {
    return (update(leaveRequestTable)
          ..where((LeaveRequestTable t) => t.id.equals(id)))
        .write(
      LeaveRequestTableCompanion(syncState: Value<String>(syncState)),
    );
  }

  Future<void> markDeletedLocally(String id) {
    return (update(leaveRequestTable)
          ..where((LeaveRequestTable t) => t.id.equals(id)))
        .write(
      const LeaveRequestTableCompanion(
        isDeletedLocally: Value<bool>(true),
        syncState: Value<String>('pending'),
      ),
    );
  }
}
