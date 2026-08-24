import 'package:avahi/core/errors/failure.dart';
import 'package:avahi/domain/entities/leave_request.dart';
import 'package:avahi/domain/enums/leave_status.dart';
import 'package:avahi/domain/enums/leave_type.dart';
import 'package:avahi/domain/repositories/i_leave_repository.dart';
import 'package:avahi/domain/usecases/leave/request_leave_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';

class MockLeaveRepository extends Mock implements ILeaveRepository {}

void main() {
  late MockLeaveRepository repository;
  late RequestLeaveUsecase usecase;

  setUpAll(() {
    registerFallbackValue(Fixtures.leaveRequest());
  });

  // ⚠️ `RequestLeaveUsecase` لا يمرّر `now` صراحة إلى
  // `LeaveValidator.validateDateRange` (يعتمد `DateTime.now()` الحقيقي
  // داخلياً لمنع طلبات بأثر رجعي) — لذا تُبنى كل تواريخ هذا الملف نسبةً
  // إلى وقت التنفيذ الفعلي [today] وليس `Fixtures.baseTime` الثابت
  // (وإلا لَفشلت كل السيناريوهات بخطأ `leave.start_in_past` بدل الوصول
  // فعلياً لمسار فحص التداخل المقصود اختباره هنا).
  final DateTime today = DateTime.now();

  setUp(() {
    repository = MockLeaveRepository();
    usecase = RequestLeaveUsecase(repository);
  });

  group('RequestLeaveUsecase — رفض عند تداخل التواريخ', () {
    test('يرفض الطلب دون تقديمه عندما يتداخل مع طلب معتمد قائم', () async {
      final DateTime start = today.add(const Duration(days: 5));
      final DateTime end = today.add(const Duration(days: 8));

      final LeaveRequest overlapping = Fixtures.leaveRequest(
        id: 'leave-existing',
        startDate: today.add(const Duration(days: 6)),
        endDate: today.add(const Duration(days: 10)),
        status: LeaveStatus.approved,
      );

      when(
        () => repository.getOverlappingLeaveRequests(
          userId: 'user-1',
          startDate: start,
          endDate: end,
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<LeaveRequest>>(<LeaveRequest>[overlapping]),
      );

      final ResultOf<LeaveRequest> result = await usecase.call(
        companyId: 'company-1',
        userId: 'user-1',
        leaveType: LeaveType.annual,
        startDate: start,
        endDate: end,
      );

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).code, 'leave.overlapping_request');
      verifyNever(() => repository.requestLeave(any()));
    });

    test('يتجاهل الطلبات المرفوضة/الملغاة عند فحص التداخل ويقدّم الطلب بنجاح',
        () async {
      final DateTime start = today.add(const Duration(days: 5));
      final DateTime end = today.add(const Duration(days: 8));

      final LeaveRequest rejectedOverlap = Fixtures.leaveRequest(
        id: 'leave-rejected',
        startDate: today.add(const Duration(days: 6)),
        endDate: today.add(const Duration(days: 9)),
        status: LeaveStatus.rejected,
      );

      when(
        () => repository.getOverlappingLeaveRequests(
          userId: 'user-1',
          startDate: start,
          endDate: end,
        ),
      ).thenAnswer(
        (_) async =>
            Right<Failure, List<LeaveRequest>>(<LeaveRequest>[rejectedOverlap]),
      );
      when(() => repository.requestLeave(any())).thenAnswer(
        (Invocation invocation) async => Right<Failure, LeaveRequest>(
          invocation.positionalArguments.first as LeaveRequest,
        ),
      );

      final ResultOf<LeaveRequest> result = await usecase.call(
        companyId: 'company-1',
        userId: 'user-1',
        leaveType: LeaveType.sick,
        startDate: start,
        endDate: end,
      );

      expect(result.isRight, isTrue);
      expect(result.getOrNull()!.status, LeaveStatus.pending);
      verify(() => repository.requestLeave(any())).called(1);
    });

    test('يرفض المدى الزمني غير الصالح (نهاية قبل بداية) دون استدعاء المستودع',
        () async {
      final DateTime start = Fixtures.baseTime.add(const Duration(days: 5));
      final DateTime end = Fixtures.baseTime.add(const Duration(days: 3));

      final ResultOf<LeaveRequest> result = await usecase.call(
        companyId: 'company-1',
        userId: 'user-1',
        leaveType: LeaveType.unpaid,
        startDate: start,
        endDate: end,
      );

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).code, 'leave.end_before_start');
      verifyNever(
        () => repository.getOverlappingLeaveRequests(
          userId: any(named: 'userId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
      verifyNever(() => repository.requestLeave(any()));
    });

    test('يمرر فشل جلب التداخل (اتصال) كما هو دون تقديم الطلب', () async {
      final DateTime start = today.add(const Duration(days: 5));
      final DateTime end = today.add(const Duration(days: 8));
      const NetworkFailure networkFailure =
          NetworkFailure(message: 'تعذّر الاتصال بالخادم.', code: 'network.offline');

      when(
        () => repository.getOverlappingLeaveRequests(
          userId: 'user-1',
          startDate: start,
          endDate: end,
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, List<LeaveRequest>>(networkFailure),
      );

      final ResultOf<LeaveRequest> result = await usecase.call(
        companyId: 'company-1',
        userId: 'user-1',
        leaveType: LeaveType.annual,
        startDate: start,
        endDate: end,
      );

      expect(result.isLeft, isTrue);
      expect(result.fold((Failure f) => f, (_) => throw StateError('?')), same(networkFailure));
      verifyNever(() => repository.requestLeave(any()));
    });
  });
}
