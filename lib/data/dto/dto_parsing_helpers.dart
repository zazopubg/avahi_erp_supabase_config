/// دوال مساعدة مشتركة لتحويل قيم JSON القادمة من PostgREST (Supabase)
/// إلى أنواع Dart آمنة، تُستخدم من كل ملفات `data/dto/`.
///
/// ⚠️ سبب وجود هذا الملف: أعمدة `numeric` في Postgres قد تُعاد من
/// PostgREST كرقم (`num`) أو كنص (`String`) بحسب إعداد الترميز؛
/// وأعمدة `timestamptz`/`date` تُعاد دائماً كنص ISO-8601. هذه الدوال
/// تتعامل مع الحالتين معاً بأمان بدل الاعتماد على `as` مباشرة (والذي قد
/// يرمي [TypeError] عند أي اختلاف طفيف في نوع الاستجابة).
library;

/// يحوّل قيمة JSON إلى [DateTime] (يفترض عمود `not null`).
DateTime parseDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw FormatException('تعذّر تحويل القيمة إلى DateTime: $value');
}

/// يحوّل قيمة JSON اختيارية إلى [DateTime]، أو `null`.
DateTime? parseNullableDateTime(Object? value) {
  if (value == null) return null;
  return parseDateTime(value);
}

/// يحوّل قيمة JSON إلى [double] (يقبل `num` أو `String` رقمية).
double parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('تعذّر تحويل القيمة إلى double: $value');
}

/// يحوّل قيمة JSON اختيارية إلى [double]، أو `null`.
double? parseNullableDouble(Object? value) {
  if (value == null) return null;
  return parseDouble(value);
}

/// يحوّل قيمة JSON اختيارية إلى [int]، أو `null`.
int? parseNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('تعذّر تحويل القيمة إلى int: $value');
}

/// يحوّل [DateTime] إلى نص تاريخ فقط (`YYYY-MM-DD`) لأعمدة Postgres
/// من نوع `date` (مثل `due_date`, `report_date`, `start_date`).
String toDateOnlyString(DateTime value) => value.toIso8601String().split('T').first;

/// كنظيرتها لكن تقبل `null`.
String? toNullableDateOnlyString(DateTime? value) =>
    value == null ? null : toDateOnlyString(value);
