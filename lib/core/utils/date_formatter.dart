import 'package:intl/intl.dart';

/// أداة تنسيق التواريخ والأوقات الموحّدة عبر التطبيق، تحترم اللغة
/// الحالية (عربي/إنجليزي) عبر معامل [locale] الصريح، تفادياً لأي
/// اعتماد ضمني على `BuildContext` داخل طبقة الأدوات (Utils) المستقلة.
abstract final class DateFormatter {
  /// تنسيق تاريخ قصير: 2026-08-11.
  static String shortDate(DateTime date, {String locale = 'ar'}) {
    return DateFormat('yyyy-MM-dd', locale).format(date);
  }

  /// تنسيق تاريخ طويل مقروء: 11 أغسطس 2026.
  static String longDate(DateTime date, {String locale = 'ar'}) {
    return DateFormat('d MMMM yyyy', locale).format(date);
  }

  /// تنسيق الوقت فقط (نظام 12 ساعة): 03:45 م.
  static String time12h(DateTime date, {String locale = 'ar'}) {
    return DateFormat('hh:mm a', locale).format(date);
  }

  /// تنسيق التاريخ والوقت معاً: 11 أغسطس 2026 - 03:45 م.
  static String dateTime(DateTime date, {String locale = 'ar'}) {
    return '${longDate(date, locale: locale)} - ${time12h(date, locale: locale)}';
  }

  /// وقت نسبي مبسّط ("قبل 5 دقائق")، مفيد لعناصر القوائم وسجلات
  /// المزامنة. لا يعتمد على حزم خارجية إضافية؛ حساب يدوي بسيط.
  static String relative(DateTime date, {DateTime? now, String locale = 'ar'}) {
    final DateTime reference = now ?? DateTime.now();
    final Duration diff = reference.difference(date);

    if (locale.startsWith('ar')) {
      if (diff.inSeconds < 60) return 'الآن';
      if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
      if (diff.inDays < 30) return 'قبل ${diff.inDays} يوم';
      return shortDate(date, locale: locale);
    }

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return shortDate(date, locale: locale);
  }

  /// يحوّل [DateTime] إلى نص ISO-8601 موحّد للتخزين/الإرسال إلى
  /// Supabase (دائماً UTC لتفادي التباس المناطق الزمنية).
  static String toIso(DateTime date) => date.toUtc().toIso8601String();

  /// يحلّل نص ISO-8601 قادم من Supabase إلى [DateTime] محلي.
  static DateTime fromIso(String value) => DateTime.parse(value).toLocal();
}
