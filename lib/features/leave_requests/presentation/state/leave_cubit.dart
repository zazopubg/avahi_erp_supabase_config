import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/leave_request.dart';
import '../../../../domain/enums/leave_status.dart';
import '../../../../domain/enums/leave_type.dart';
import '../../../../domain/repositories/i_leave_repository.dart';
import '../../../../domain/usecases/leave/get_leave_requests_usecase.dart';
import '../../../../domain/usecases/leave/request_leave_usecase.dart';
import '../../../../domain/usecases/leave/review_leave_usecase.dart';
import 'leave_state.dart';

/// `Cubit` ميزة `features/leave_requests/` (Prompt 24) — يقود كل
/// شاشات الميزة معاً (`my_leave_requests_screen.dart`/
/// `create_leave_request_screen.dart` الهاتفية، و
/// `leave_requests_inbox.dart`/`leave_request_review.dart` الإدارية
/// على سطح المكتب) عبر [LeaveData] واحدة مجمّعة، بنفس فلسفة
/// `EquipmentCubit`/`DocumentsCubit`/`PunchCubit` تماماً.
///
/// ⚠️ قرار تصميم مهم (`ILeaveRepository` مُحقَنة مباشرة إلى جانب
/// `UseCases`، لا `UseCase` إضافية لجلب طلبات الفريق): جلب **كل**
/// طلبات إجازة الشركة (`getCompanyLeaveRequests`) عملية قراءة خام
/// بلا أي منطق عمل يستحق طبقة `UseCase` خاصة به — التصفية حسب الحالة/
/// الموظف تطبَّق لاحقاً ضمن [LeaveData] نفسها (`filteredCompanyRequests`)
/// وليس في طبقة `domain/`. بنفس سابقة `notificationRepository:
/// sl<INotificationRepository>()` في `NotificationsCubit` و
/// `photoRepository: sl<IPhotoRepository>()` في `PhotosCubit`/
/// `ReportFormCubit` — انظر توثيق القرار الكامل هناك.
///
/// ⚠️ قرار تصميم ثانٍ (بلا اشتراك لحظي/Realtime): بخلاف
/// `NotificationsCubit`/`ReportsInboxCubit`/`AttendanceCubit`، لا يوجد
/// `watchXxx` ضمن [ILeaveRepository] (لا حاجة فعلية موثَّقة لتحديث
/// لحظي لطلبات الإجازة ضمن مواصفة Prompt 24 هذه) — [refresh] يدوي
/// فقط (سحب للتحديث/بعد تقديم أو مراجعة طلب).
class LeaveCubit extends Cubit<LeaveState> {
  LeaveCubit({
    required RequestLeaveUsecase requestLeaveUsecase,
    required ReviewLeaveUsecase reviewLeaveUsecase,
    required GetLeaveRequestsUsecase getLeaveRequestsUsecase,
    required ILeaveRepository leaveRepository,
  })  : _requestLeaveUsecase = requestLeaveUsecase,
        _reviewLeaveUsecase = reviewLeaveUsecase,
        _getLeaveRequestsUsecase = getLeaveRequestsUsecase,
        _leaveRepository = leaveRepository,
        super(const LeaveLoading());

  final RequestLeaveUsecase _requestLeaveUsecase;
  final ReviewLeaveUsecase _reviewLeaveUsecase;
  final GetLeaveRequestsUsecase _getLeaveRequestsUsecase;
  final ILeaveRepository _leaveRepository;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى عند دخول `my_leave_requests_screen.dart` (نقطة الدخول
  /// الوحيدة لمسار `RouteNames.leaveRequests`، بنفس نمط
  /// `PunchListScreen`): يجلب طلبات [user] الشخصية دوماً، ثم يجلب
  /// أيضاً كل طلبات الشركة إن ملك [LeaveData.canApproveTeam] (لا
  /// استدعاء شبكة إضافي لمن لا يحتاجه إطلاقاً).
  Future<void> loadInitial(AppUser user) async {
    emit(const LeaveLoading());

    final ResultOf<List<LeaveRequest>> myResult =
        await _getLeaveRequestsUsecase(user.userId);

    if (myResult.isLeft) {
      final Failure failure = myResult.fold(
        (Failure f) => f,
        (List<LeaveRequest> _) => throw StateError('unreachable'),
      );
      emit(LeaveError(failure));
      return;
    }

    final List<LeaveRequest> myRequests = myResult.getOrNull()!;
    LeaveData data = LeaveData(currentUser: user, myRequests: myRequests);

    if (data.canApproveTeam) {
      final ResultOf<List<LeaveRequest>> companyResult =
          await _leaveRepository.getCompanyLeaveRequests(user.companyId);
      final List<LeaveRequest> companyRequests = companyResult.fold(
        (Failure _) => const <LeaveRequest>[],
        (List<LeaveRequest> r) => r,
      );
      data = data.copyWith(companyRequests: companyRequests);
    }

    emit(LeaveLoaded(data));
  }

  /// يعيد تحميل [LeaveData.myRequests]/[LeaveData.companyRequests]
  /// معاً (سحب للتحديث، أو بعد تقديم/مراجعة طلب من نسخة `LeaveCubit`
  /// أخرى — بنفس قيد `PunchCubit.refresh` بعد `punchListCreate`).
  Future<void> refresh() async {
    final LeaveData? current = state.dataOrNull;
    if (current == null) return;

    emit(LeaveLoaded(current.copyWith(isRefreshing: true)));

    final ResultOf<List<LeaveRequest>> myResult =
        await _getLeaveRequestsUsecase(current.currentUser.userId);
    final List<LeaveRequest> myRequests = myResult.fold(
      (Failure _) => current.myRequests,
      (List<LeaveRequest> r) => r,
    );

    List<LeaveRequest> companyRequests = current.companyRequests;
    if (current.canApproveTeam) {
      final ResultOf<List<LeaveRequest>> companyResult = await _leaveRepository
          .getCompanyLeaveRequests(current.currentUser.companyId);
      companyRequests = companyResult.fold(
        (Failure _) => current.companyRequests,
        (List<LeaveRequest> r) => r,
      );
    }

    final LeaveData latest = state.dataOrNull ?? current;
    emit(
      LeaveLoaded(
        latest.copyWith(
          myRequests: myRequests,
          companyRequests: companyRequests,
          isRefreshing: false,
        ),
      ),
    );
  }

  // ── تصفية (`leave_requests_inbox.dart`) ──────────────────────────

  /// `null` يزيل تصفية الحالة (كل الحالات) — `leave_requests_inbox.dart`
  /// عند اختيار تبويب/رقاقة "الكل".
  void setStatusFilter(LeaveStatus? status) {
    final LeaveData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      LeaveLoaded(
        status == null
            ? current.copyWith(clearStatusFilter: true)
            : current.copyWith(statusFilter: status),
      ),
    );
  }

  void setEmployeeFilter(String? userId) {
    final LeaveData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      LeaveLoaded(
        userId == null
            ? current.copyWith(clearEmployeeFilter: true)
            : current.copyWith(employeeFilter: userId),
      ),
    );
  }

  void clearFilters() {
    final LeaveData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      LeaveLoaded(
        current.copyWith(clearStatusFilter: true, clearEmployeeFilter: true),
      ),
    );
  }

  // ── تقديم طلب جديد (`create_leave_request_screen.dart`) ──────────

  /// يقدّم طلب إجازة جديداً عبر [RequestLeaveUsecase] (يتحقق داخلياً
  /// من صحة المدى الزمني وعدم تداخله مع طلبات قائمة عبر
  /// `LeaveValidator` قبل الإرسال). يُعيد [LeaveRequest] المُنشأ فعلياً
  /// عند النجاح، أو `null` عند الفشل — رسالة الفشل التفصيلية
  /// (تحقّق منطقي محدَّد غالباً) تُحفظ ضمن
  /// [LeaveData.submitErrorMessage] لعرضها مباشرة في النموذج (انظر
  /// توثيق القرار الكامل هناك).
  Future<LeaveRequest?> submitLeaveRequest({
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final LeaveData? current = state.dataOrNull;
    if (current == null) return null;

    emit(
      LeaveLoaded(
        current.copyWith(isSubmitting: true, clearSubmitErrorMessage: true),
      ),
    );

    final ResultOf<LeaveRequest> result = await _requestLeaveUsecase(
      companyId: current.currentUser.companyId,
      userId: current.currentUser.userId,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: (reason == null || reason.trim().isEmpty) ? null : reason.trim(),
    );

    final LeaveData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure failure) {
        emit(
          LeaveLoaded(
            latest.copyWith(
              isSubmitting: false,
              submitErrorMessage: failure.message,
            ),
          ),
        );
        return null;
      },
      (LeaveRequest created) {
        emit(
          LeaveLoaded(
            latest.copyWith(
              myRequests: <LeaveRequest>[created, ...latest.myRequests],
              isSubmitting: false,
              clearSubmitErrorMessage: true,
            ),
          ),
        );
        return created;
      },
    );
  }

  // ── اعتماد / رفض (`leave_request_review.dart`) ────────────────────

  /// يعتمد أو يرفض [request] — `leave_request_review.dart`. يُحدَّث
  /// [LeaveData.companyRequests] محلياً فور نجاح الاستدعاء، بنفس نمط
  /// `ReportsInboxCubit.review` تماماً (بلا اشتراك لحظي هنا — انظر
  /// توثيق القرار الكامل أعلى الصنف).
  Future<bool> reviewLeave({
    required LeaveRequest request,
    required bool approve,
    String? reviewNote,
  }) async {
    final LeaveData? current = state.dataOrNull;
    if (current == null) return false;

    // إلزامية سبب الرفض — دفاعية هنا أيضاً (التحقق الأساسي ضمن نموذج
    // `leave_request_review.dart` نفسه، بنفس منطق
    // `ReportApprovalActions._promptRejectionReason`).
    if (!approve && (reviewNote == null || reviewNote.trim().isEmpty)) {
      return false;
    }

    emit(LeaveLoaded(current.copyWith(isReviewing: true)));

    final ResultOf<LeaveRequest> result = await _reviewLeaveUsecase(
      request: request,
      approve: approve,
      reviewerId: current.currentUser.userId,
      reviewNote: reviewNote?.trim(),
    );

    final LeaveData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(LeaveLoaded(latest.copyWith(isReviewing: false)));
        return false;
      },
      (LeaveRequest reviewed) {
        final List<LeaveRequest> updated = latest.companyRequests
            .map((LeaveRequest r) => r.id == reviewed.id ? reviewed : r)
            .toList(growable: false);
        emit(
          LeaveLoaded(
            latest.copyWith(companyRequests: updated, isReviewing: false),
          ),
        );
        return true;
      },
    );
  }
}

