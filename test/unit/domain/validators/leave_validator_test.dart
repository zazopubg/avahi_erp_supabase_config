import 'package:avahi/core/errors/failure.dart';
import 'package:avahi/domain/entities/leave_request.dart';
import 'package:avahi/domain/enums/leave_status.dart';
import 'package:avahi/domain/validators/leave_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  final DateTime today = DateTime.utc(2026, 6, 15);

  group('LeaveValidator.validateDateRange', () {
    test('يرفض عندما تسبق تاريخ النهاية تاريخ البداية', () {
      final ResultOf<void> result = LeaveValidator.validateDateRange(
        startDate: today.add(const Duration(days: 5)),
        endDate: today.add(const Duration(days: 3)),
        now: today,
      );

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).code, 'leave.end_before_start');
    });

    test('يرفض تاريخ بداية في الماضي بالنسبة لـ now الممرَّرة', () {
      final ResultOf<void> result = LeaveValidator.validateDateRange(
        startDate: today.subtract(const Duration(days: 1)),
        endDate: today.add(const Duration(days: 2)),
        now: today,
      );

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).code, 'leave.start_in_past');
    });

    test('يقبل تاريخ بداية مطابق تماماً لليوم الحالي (حدّي)', () {
      final ResultOf<void> result = LeaveValidator.validateDateRange(
        startDate: today,
        endDate: today.add(const Duration(days: 1)),
        now: today,
      );

      expect(result.isRight, isTrue);
    });

    test('يقبل مدى ليوم واحد فقط (البداية = النهاية)', () {
      final ResultOf<void> result = LeaveValidator.validateDateRange(
        startDate: today.add(const Duration(days: 1)),
        endDate: today.add(const Duration(days: 1)),
        now: today,
      );

      expect(result.isRight, isTrue);
    });

    test('يتجاهل مكوّن الوقت (ساعة/دقيقة) عند مقارنة تاريخ البداية باليوم '
        'الحالي', () {
      final DateTime lateInDay = today.add(const Duration(hours: 23, minutes: 59));

      final ResultOf<void> result = LeaveValidator.validateDateRange(
        startDate: DateTime.utc(today.year, today.month, today.day),
        endDate: today.add(const Duration(days: 1)),
        now: lateInDay,
      );

      expect(result.isRight, isTrue);
    });
  });

  group('LeaveValidator.validateNoOverlap', () {
    test('يرفض عند تداخل جزئي مع طلب معتمد قائم (تقاطع في المنتصف)', () {
      final ResultOf<void> result = LeaveValidator.validateNoOverlap(
        startDate: today.add(const Duration(days: 10)),
        endDate: today.add(const Duration(days: 15)),
        existingRequests: <LeaveRequest>[
          Fixtures.leaveRequest(
            startDate: today.add(const Duration(days: 12)),
            endDate: today.add(const Duration(days: 20)),
            status: LeaveStatus.approved,
          ),
        ],
      );

      expect(result.isLeft, isTrue);
      final Failure failure =
          result.fold((Failure f) => f, (_) => throw StateError('?'));
      expect((failure as ValidationFailure).code, 'leave.overlapping_request');
    });

    test('يرفض عندما يحتوي الطلب الجديد الطلب القائم بالكامل', () {
      final ResultOf<void> result = LeaveValidator.validateNoOverlap(
        startDate: today.add(const Duration(days: 5)),
        endDate: today.add(const Duration(days: 25)),
        existingRequests: <LeaveRequest>[
          Fixtures.leaveRequest(
            startDate: today.add(const Duration(days: 10)),
            endDate: today.add(const Duration(days: 15)),
          ),
        ],
      );

      expect(result.isLeft, isTrue);
    });

    test('يقبل مدى مجاور تماماً (ينتهي القائم بيوم قبل بداية الجديد بيوم '
        'كامل فاصل) دون تداخل فعلي', () {
      // الطلب القائم: 1-5 يونيو. الطلب الجديد: 7-10 يونيو — يوم كامل فاصل
      // (6 يونيو) بينهما، فلا تداخل.
      final ResultOf<void> result = LeaveValidator.validateNoOverlap(
        startDate: today.add(const Duration(days: 7)),
        endDate: today.add(const Duration(days: 10)),
        existingRequests: <LeaveRequest>[
          Fixtures.leaveRequest(
            startDate: today.add(const Duration(days: 1)),
            endDate: today.add(const Duration(days: 5)),
            status: LeaveStatus.approved,
          ),
        ],
      );

      expect(result.isRight, isTrue);
    });

    test('يتجاهل طلباً مرفوضاً متداخلاً زمنياً بالكامل', () {
      final ResultOf<void> result = LeaveValidator.validateNoOverlap(
        startDate: today.add(const Duration(days: 10)),
        endDate: today.add(const Duration(days: 15)),
        existingRequests: <LeaveRequest>[
          Fixtures.leaveRequest(
            startDate: today.add(const Duration(days: 10)),
            endDate: today.add(const Duration(days: 15)),
            status: LeaveStatus.rejected,
          ),
        ],
      );

      expect(result.isRight, isTrue);
    });

    test('يتجاهل طلباً ملغى متداخلاً زمنياً بالكامل', () {
      final ResultOf<void> result = LeaveValidator.validateNoOverlap(
        startDate: today.add(const Duration(days: 10)),
        endDate: today.add(const Duration(days: 15)),
        existingRequests: <LeaveRequest>[
          Fixtures.leaveRequest(
            startDate: today.add(const Duration(days: 10)),
            endDate: today.add(const Duration(days: 15)),
            status: LeaveStatus.cancelled,
          ),
        ],
      );

      expect(result.isRight, isTrue);
    });

    test('يقبل عندما لا توجد أي طلبات قائمة إطلاقاً (قائمة فارغة)', () {
      final ResultOf<void> result = LeaveValidator.validateNoOverlap(
        startDate: today.add(const Duration(days: 1)),
        endDate: today.add(const Duration(days: 2)),
        existingRequests: const <LeaveRequest>[],
      );

      expect(result.isRight, isTrue);
    });
  });
}
