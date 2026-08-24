import 'package:intl/intl.dart';

/// أداة تنسيق الأرقام، النسب المئوية، والمسافات، تحترم اللغة الحالية
/// (بما فيها الأرقام الهندية/العربية عند locale='ar' حسب إعدادات
/// `intl`، ويمكن التحكم بها لاحقاً عبر `ui/rtl/number_direction.dart`).
abstract final class NumberFormatter {
  /// تنسيق عدد صحيح مع فواصل الآلاف: 12,340.
  static String integer(num value, {String locale = 'ar'}) {
    return NumberFormat.decimalPattern(locale).format(value);
  }

  /// تنسيق عدد عشري بعدد منازل محدد: 12.5.
  static String decimal(
    num value, {
    int fractionDigits = 1,
    String locale = 'ar',
  }) {
    final NumberFormat fmt = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = fractionDigits
      ..maximumFractionDigits = fractionDigits;
    return fmt.format(value);
  }

  /// تنسيق نسبة مئوية من قيمة عشرية (0.42 → 42%).
  static String percent(double ratio, {int fractionDigits = 0, String locale = 'ar'}) {
    final NumberFormat fmt = NumberFormat.decimalPercentPattern(
      locale: locale,
      decimalDigits: fractionDigits,
    );
    return fmt.format(ratio);
  }

  /// تنسيق مسافة بالمتر مع تحويل تلقائي إلى كيلومتر عند تجاوز 1000م.
  static String distanceMeters(double meters, {String locale = 'ar'}) {
    if (meters >= 1000) {
      final double km = meters / 1000;
      return locale.startsWith('ar')
          ? '${decimal(km, locale: locale)} كم'
          : '${decimal(km, locale: locale)} km';
    }
    return locale.startsWith('ar')
        ? '${integer(meters, locale: locale)} م'
        : '${integer(meters, locale: locale)} m';
  }

  /// تنسيق حجم ملف بالبايت إلى وحدة مقروءة (KB/MB/GB).
  static String fileSize(int bytes) {
    const List<String> units = <String>['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size >= 10 || unitIndex == 0 ? 0 : 1)} '
        '${units[unitIndex]}';
  }
}
