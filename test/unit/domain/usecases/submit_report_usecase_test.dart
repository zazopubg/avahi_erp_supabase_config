import 'package:avahi/core/errors/failure.dart';
import 'package:avahi/domain/entities/field_report.dart';
import 'package:avahi/domain/enums/report_status.dart';
import 'package:avahi/domain/repositories/i_report_repository.dart';
import 'package:avahi/domain/usecases/reports/submit_report_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';

class MockReportRepository extends Mock implements IReportRepository {}

void main() {
  late MockReportRepository repository;
  late SubmitReportUsecase usecase;

  setUp(() {
    repository = MockReportRepository();
    usecase = SubmitReportUsecase(repository);
  });

  group('SubmitReportUsecase — رفض عند نقص الحقول', () {
    test('يرفض التقديم عند خلوّ workPerformed دون استدعاء المستودع', () async {
      final FieldReport incomplete = Fixtures.fieldReport(
        workPerformed: null,
      );

      final ResultOf<FieldReport> result = await usecase.call(incomplete);

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'report.incomplete');
      expect(failure.fieldErrors, contains('workPerformed'));
      verifyNever(() => repository.submitReport(any()));
    });

    test('يرفض التقديم عند laborCount سالب دون استدعاء المستودع', () async {
      final FieldReport invalidLabor = Fixtures.fieldReport(
        laborCount: -1,
      );

      final ResultOf<FieldReport> result = await usecase.call(invalidLabor);

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).fieldErrors, contains('laborCount'));
      verifyNever(() => repository.submitReport(any()));
    });

    test('يرفض التقديم إن لم تكن الحالة draft (مثال: submitted بالفعل)',
        () async {
      final FieldReport alreadySubmitted = Fixtures.fieldReport(
        status: ReportStatus.submitted,
      );

      final ResultOf<FieldReport> result = await usecase.call(alreadySubmitted);

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).code, 'report.not_in_draft');
      verifyNever(() => repository.submitReport(any()));
    });

    test('يقدّم التقرير بنجاح عبر المستودع عندما يكون مكتملاً وضمن draft',
        () async {
      final FieldReport complete = Fixtures.fieldReport(
        workPerformed: 'صب خرسانة الأساسات',
        laborCount: 8,
      );
      final FieldReport submitted =
          complete.copyWith(status: ReportStatus.submitted);

      when(() => repository.submitReport(complete.id))
          .thenAnswer((_) async => Right<Failure, FieldReport>(submitted));

      final ResultOf<FieldReport> result = await usecase.call(complete);

      expect(result.isRight, isTrue);
      expect(result.getOrNull()!.status, ReportStatus.submitted);
      verify(() => repository.submitReport(complete.id)).called(1);
    });
  });
}
