import 'package:flutter/material.dart';

import '../../../../domain/entities/attendance_record.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// منطق حساب ساعات العمل الفعلية من سجل حضور — دالة حسابية بحتة
/// (Pure)، مفصولة عن [HoursCalculator] (الودجت) لتسهيل اختبارها
/// مستقبلاً في `test/unit/` (Prompt 29) دون الحاجة لشجرة Widget.
abstract final class AttendanceHoursLogic {
  /// مدة العمل الفعلية، أو `null` إن كان المستخدم لا يزال يعمل (لم
  /// يسجّل انصرافاً بعد).
  static Duration? workedDuration(AttendanceRecord record) {
    final DateTime? checkOutAt = record.checkOutAt;
    if (checkOutAt == null) return null;
    return checkOutAt.difference(record.checkInAt);
  }

  /// مدة "العمل حتى الآن" لسجل لم يُسجَّل انصرافه بعد — تُستخدم في
  /// `check_out_screen.dart` لعرض عدّاد حي تقريبي.
  static Duration elapsedSinceCheckIn(AttendanceRecord record) {
    return DateTime.now().difference(record.checkInAt);
  }

  /// تنسيق مدة كنص عربي مختصر — مثال: `7 س 32 د`.
  static String format(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    if (hours <= 0) return '$minutesد';
    return '$hoursس $minutesد';
  }
}

/// عرض ساعات العمل المحسوبة لسجل حضور — إن كان [record.checkOutAt]
/// فارغاً يعرض "لا يزال يعمل" مع مدة تقريبية منذ الحضور بدل قيمة
/// نهائية مضلِّلة.
///
/// مكوّن عرض بحت فوق [AttendanceHoursLogic].
class HoursCalculator extends StatelessWidget {
  const HoursCalculator({required this.record, super.key, this.dense = false});

  final AttendanceRecord record;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Duration? worked = AttendanceHoursLogic.workedDuration(record);
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (worked != null) {
      return Text(
        AttendanceHoursLogic.format(worked),
        style: dense ? textTheme.labelMedium : textTheme.titleMedium,
      );
    }

    final Duration elapsed = AttendanceHoursLogic.elapsedSinceCheckIn(record);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.timelapse, size: dense ? 14 : 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AvahiSpacing.xxs),
        Text(
          'لا يزال يعمل · ${AttendanceHoursLogic.format(elapsed)}',
          style: (dense ? textTheme.labelSmall : textTheme.labelMedium)?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
