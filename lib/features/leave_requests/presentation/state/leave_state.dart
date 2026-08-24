import '../../../../core/constants/permissions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/leave_request.dart';
import '../../../../domain/enums/leave_status.dart';

/// حالة `LeaveCubit` الكاملة — Union Type مكتوب يدوياً (بلا `freezed`)،
/// بنفس نمط `EquipmentState`/`DocumentsState`/`PunchState`/
/// `NotificationsState` تماماً: ثلاث حالات فقط (`LeaveLoading` /
/// `LeaveLoaded` / `LeaveError`). 🆕 (Prompt 24)
sealed class LeaveState {
  const LeaveState();

  T when<T>({
    required T Function() loading,
    required T Function(LeaveData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final LeaveState state = this;
    return switch (state) {
      LeaveLoading() => loading(),
      LeaveLoaded(:final data) => loaded(data),
      LeaveError(:final failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(LeaveData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [LeaveData] الحالية إن كانت الحالة [LeaveLoaded]، أو `null` —
  /// بنفس نمط `EquipmentState.dataOrNull`/`PunchState.dataOrNull`.
  LeaveData? get dataOrNull => maybeWhen<LeaveData?>(
        orElse: () => null,
        loaded: (LeaveData d) => d,
      );
}

/// جارٍ التحميل الأولي (طلبات المستخدم الحالي، وطلبات الشركة كاملة
/// إن ملك صلاحية [Permission.leaveRequestApproveTeam]).
final class LeaveLoading extends LeaveState {
  const LeaveLoading();
}

/// جاهزة لعرض كل شاشات الميزة معاً — `my_leave_requests_screen.dart`
/// (الهاتف/الفرع الشخصي على سطح المكتب بلا صلاحية اعتماد) و
/// `leave_requests_inbox.dart`/`leave_request_review.dart` (الفرع
/// الإداري على سطح المكتب)، بنفس منطق `PunchLoaded`/`DocumentsLoaded`.
final class LeaveLoaded extends LeaveState {
  const LeaveLoaded(this.data);

  final LeaveData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً — يعتمد `Retry` في الشاشة
/// لإعادة `LeaveCubit.loadInitial`.
final class LeaveError extends LeaveState {
  const LeaveError(this.failure);

  final Failure failure;
}

/// حزمة بيانات ميزة طلبات الإجازة المجمّعة — يحملها [LeaveLoaded] وحدها.
class LeaveData {
  const LeaveData({
    required this.currentUser,
    this.myRequests = const <LeaveRequest>[],
    this.companyRequests = const <LeaveRequest>[],
    this.statusFilter = LeaveStatus.pending,
    this.employeeFilter,
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.isReviewing = false,
    this.submitErrorMessage,
  });

  final AppUser currentUser;

  /// طلبات المستخدم الحالي وحده (كل الحالات معاً، الأحدث أولاً) —
  /// `my_leave_requests_screen.dart` عبر [GetLeaveRequestsUsecase].
  final List<LeaveRequest> myRequests;

  /// **كل** طلبات الشركة (كل الحالات معاً) — لا تُحمَّل ولا تُستخدم
  /// إلا عند [canApproveTeam]؛ تبقى قائمة فارغة لأي دور آخر بلا أي
  /// استدعاء شبكة إضافي — `leave_requests_inbox.dart` عبر
  /// `ILeaveRepository.getCompanyLeaveRequests` مباشرة (انظر توثيق
  /// القرار الكامل في `LeaveCubit`).
  final List<LeaveRequest> companyRequests;

  /// تصفية الحالة الحالية لـ [leave_requests_inbox.dart] — `null`
  /// يعني "كل الحالات". القيمة الافتراضية [LeaveStatus.pending]
  /// (تبويب "بانتظار الاعتماد")، بنفس منطق
  /// `ReportsInboxData.statusFilter` الافتراضي [ReportStatus.submitted].
  final LeaveStatus? statusFilter;

  /// تصفية حسب `userId` مقدّم الطلب — `leave_requests_inbox.dart`.
  final String? employeeFilter;

  final bool isRefreshing;

  /// تقديم طلب إجازة جديد جارٍ — `create_leave_request_screen.dart`.
  final bool isSubmitting;

  /// اعتماد/رفض طلب جارٍ — `leave_request_review.dart`.
  final bool isReviewing;

  /// رسالة فشل آخر محاولة تقديم طلب (مثال: "يوجد طلب إجازة آخر
  /// يتداخل مع هذا المدى الزمني" من [LeaveValidator]) — `null` عند
  /// عدم وجود فشل حديث أو بعد نجاح المحاولة التالية. ⚠️ قرار تصميم
  /// متعمَّد (خروج عن نمط الإرجاع البسيط `Future<LeaveRequest?>`
  /// المعتمد في بقية الـ Cubits لعمليات الإنشاء، مثل
  /// `PunchCubit.createPunchItem`/`ProjectsCubit.createProject`):
  /// فشل تقديم طلب إجازة غالباً **تحقّق منطقي محدَّد** (تداخل تواريخ،
  /// تاريخ ماضٍ) برسالة عربية جاهزة ومفيدة فعلياً للمستخدم لتصحيح
  /// الطلب فوراً — بخلاف فشل الشبكة العام في تلك الحالات الأخرى الذي
  /// لا يضيف تفصيل مفيد يستحق نقله. بنفس روح `ReportFormData.weatherError`
  /// (حقل نصي مخصّص لسبب فشل تحديد؛ الاستثناء الوحيد المسبوق هنا).
  final String? submitErrorMessage;

  /// صحيح إن ملك [currentUser] صلاحية اعتماد/رفض طلبات فريقه —
  /// يحدد الفرع المعروض في `my_leave_requests_screen.dart`
  /// (`_LeaveDispatcher`، بنفس منطق `_RoleBranch.canApproveTeam` في
  /// `field_reports_screen.dart`) وما إذا كانت [companyRequests] ذات
  /// معنى أصلاً.
  bool get canApproveTeam => RolePermissions.has(
        currentUser.role,
        Permission.leaveRequestApproveTeam,
      );

  /// [companyRequests] بعد تطبيق [statusFilter]/[employeeFilter]
  /// الحاليين معاً — `leave_requests_inbox.dart` وحدها.
  List<LeaveRequest> get filteredCompanyRequests {
    return companyRequests.where((LeaveRequest r) {
      final bool matchesStatus =
          statusFilter == null || r.status == statusFilter;
      final bool matchesEmployee =
          employeeFilter == null || r.userId == employeeFilter;
      return matchesStatus && matchesEmployee;
    }).toList(growable: false);
  }

  /// معرّفات الموظفين المميّزة ضمن [companyRequests] — تغذي قائمة
  /// تصفية "حسب الموظف" في `leave_requests_inbox.dart`. لا تحمل أسماء
  /// كاملة (عرض معرّف مختصر فقط) — انظر توثيق القيد نفسه في
  /// `worker_row.dart` (`features/attendance/`، Prompt 15): حل عرض
  /// أسماء كاملة مؤجَّل عمداً لـ `features/users/` (Prompt 26).
  List<String> get distinctEmployeeIds {
    final Set<String> ids = <String>{
      for (final LeaveRequest r in companyRequests) r.userId,
    };
    return ids.toList(growable: false)..sort();
  }

  /// عدد طلبات الشركة بانتظار الاعتماد — شارة/عدّاد في
  /// `leave_requests_inbox.dart` (`_PendingCountChip`، بنفس نمط
  /// `ReportsInbox._PendingCountChip`)، بصرف النظر عن [statusFilter]
  /// الحالي.
  int get pendingApprovalCount =>
      companyRequests.where((LeaveRequest r) => r.status.isPending).length;

  LeaveData copyWith({
    AppUser? currentUser,
    List<LeaveRequest>? myRequests,
    List<LeaveRequest>? companyRequests,
    LeaveStatus? statusFilter,
    bool clearStatusFilter = false,
    String? employeeFilter,
    bool clearEmployeeFilter = false,
    bool? isRefreshing,
    bool? isSubmitting,
    bool? isReviewing,
    String? submitErrorMessage,
    bool clearSubmitErrorMessage = false,
  }) {
    return LeaveData(
      currentUser: currentUser ?? this.currentUser,
      myRequests: myRequests ?? this.myRequests,
      companyRequests: companyRequests ?? this.companyRequests,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      employeeFilter: clearEmployeeFilter
          ? null
          : (employeeFilter ?? this.employeeFilter),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isReviewing: isReviewing ?? this.isReviewing,
      submitErrorMessage: clearSubmitErrorMessage
          ? null
          : (submitErrorMessage ?? this.submitErrorMessage),
    );
  }
}
