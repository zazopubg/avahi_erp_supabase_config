/// امتدادات مساعدة على [DateTime] مستخدمة عبر التطبيق.
extension DateTimeX on DateTime {
  /// يُعيد صحيح إذا كان التاريخ يقع في نفس يوم [other] (بغض النظر عن
  /// الوقت)، مفيد لتجميع سجلات الحضور/المهام حسب اليوم في الواجهة.
  bool isSameDayAs(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// يُعيد صحيح إذا كان التاريخ اليوم.
  bool get isToday => isSameDayAs(DateTime.now());

  /// يُعيد صحيح إذا كان التاريخ يقع في الماضي.
  bool get isPast => isBefore(DateTime.now());

  /// يُعيد صحيح إذا كان التاريخ يقع في المستقبل.
  bool get isFuture => isAfter(DateTime.now());

  /// يُعيد نسخة من التاريخ عند بداية اليوم (00:00:00.000).
  DateTime get startOfDay => DateTime(year, month, day);

  /// يُعيد نسخة من التاريخ عند نهاية اليوم (23:59:59.999).
  DateTime get endOfDay =>
      DateTime(year, month, day, 23, 59, 59, 999);

  /// يُعيد نسخة من التاريخ عند بداية الأسبوع (الاثنين، وفق التقويم
  /// المعياري ISO-8601 المستخدم في `DateTime.weekday`).
  DateTime get startOfWeek => subtract(Duration(days: weekday - 1)).startOfDay;

  /// عدد الأيام الكاملة الفاصلة بين هذا التاريخ و[other] (بدون وقت).
  int daysBetween(DateTime other) {
    return startOfDay.difference(other.startOfDay).inDays.abs();
  }
}
