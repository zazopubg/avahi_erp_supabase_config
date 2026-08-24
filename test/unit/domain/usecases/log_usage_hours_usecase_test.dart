import 'package:avahi/core/errors/failure.dart';
import 'package:avahi/domain/entities/equipment.dart';
import 'package:avahi/domain/repositories/i_equipment_repository.dart';
import 'package:avahi/domain/usecases/equipment/log_usage_hours_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';

class MockEquipmentRepository extends Mock implements IEquipmentRepository {}

void main() {
  late MockEquipmentRepository repository;
  late LogUsageHoursUsecase usecase;

  setUp(() {
    repository = MockEquipmentRepository();
    usecase = LogUsageHoursUsecase(repository);
  });

  group('LogUsageHoursUsecase — تحقق المدخلات', () {
    test('يرفض إضافة ساعات صفر أو سالبة دون استدعاء المستودع', () async {
      final Equipment crane = Fixtures.equipment(usageHours: 50);

      final ResultOf<LogUsageHoursResult> result = await usecase.call(
        equipment: crane,
        additionalHours: 0,
      );

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).code, 'equipment.invalid_usage_hours');
      verifyNever(
        () => repository.updateUsageHours(
          equipmentId: any(named: 'equipmentId'),
          newUsageHours: any(named: 'newUsageHours'),
        ),
      );
    });
  });

  group('LogUsageHoursUsecase — تراكم الساعات وعتبة الصيانة', () {
    test('يجمع الساعات الجديدة على القديمة ويستدعي المستودع بالقيمة الصحيحة',
        () async {
      final Equipment crane = Fixtures.equipment(usageHours: 50);
      final Equipment updated = crane.copyWith(usageHours: 58);

      when(
        () => repository.updateUsageHours(
          equipmentId: crane.id,
          newUsageHours: 58,
        ),
      ).thenAnswer((_) async => Right<Failure, Equipment>(updated));

      final ResultOf<LogUsageHoursResult> result = await usecase.call(
        equipment: crane,
        additionalHours: 8,
      );

      expect(result.isRight, isTrue);
      final LogUsageHoursResult data = result.getOrNull()!;
      expect(data.equipment.usageHours, 58);
      expect(data.maintenanceThresholdExceeded, isFalse);
      verify(
        () => repository.updateUsageHours(
          equipmentId: crane.id,
          newUsageHours: 58,
        ),
      ).called(1);
    });

    test('يُعلم بتجاوز عتبة الصيانة الافتراضية (250 ساعة) عند الوصول إليها',
        () async {
      final Equipment crane = Fixtures.equipment(usageHours: 245);
      final Equipment updated = crane.copyWith(usageHours: 251);

      when(
        () => repository.updateUsageHours(
          equipmentId: crane.id,
          newUsageHours: 251,
        ),
      ).thenAnswer((_) async => Right<Failure, Equipment>(updated));

      final ResultOf<LogUsageHoursResult> result = await usecase.call(
        equipment: crane,
        additionalHours: 6,
      );

      expect(result.isRight, isTrue);
      expect(result.getOrNull()!.maintenanceThresholdExceeded, isTrue);
    });

    test('يحترم عتبة صيانة مخصّصة يمررها المستدعي بدل الافتراضية', () async {
      final Equipment generator = Fixtures.equipment(usageHours: 40, type: 'generator');
      final Equipment updated = generator.copyWith(usageHours: 55);

      when(
        () => repository.updateUsageHours(
          equipmentId: generator.id,
          newUsageHours: 55,
        ),
      ).thenAnswer((_) async => Right<Failure, Equipment>(updated));

      final ResultOf<LogUsageHoursResult> result = await usecase.call(
        equipment: generator,
        additionalHours: 15,
        maintenanceThresholdHours: 50,
      );

      expect(result.isRight, isTrue);
      expect(result.getOrNull()!.maintenanceThresholdExceeded, isTrue);
    });

    test('يمرر فشل المستودع كما هو دون تعديل', () async {
      final Equipment crane = Fixtures.equipment(usageHours: 50);
      const UnknownFailure failure =
          UnknownFailure(message: 'خطأ اتصال', code: 'network.unavailable');

      when(
        () => repository.updateUsageHours(
          equipmentId: crane.id,
          newUsageHours: any(named: 'newUsageHours'),
        ),
      ).thenAnswer((_) async => const Left<Failure, Equipment>(failure));

      final ResultOf<LogUsageHoursResult> result = await usecase.call(
        equipment: crane,
        additionalHours: 5,
      );

      expect(result.isLeft, isTrue);
      expect(result.fold((Failure f) => f, (_) => throw StateError('?')), same(failure));
    });
  });
}
