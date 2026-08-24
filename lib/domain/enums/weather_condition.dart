/// حالة الطقس المسجّلة في التقرير الميداني (`field_reports.weather_condition`،
/// Prompt 17: تُملأ تلقائياً لاحقاً عبر Weather API). العمود في قاعدة
/// البيانات نص حر بدون قيد CHECK؛ هذا التعداد يوفّر قيماً معيارية
/// للواجهة (أيقونات، ترجمة) مع قيمة [unknown] احتياطية لأي نص لا
/// يطابق القيم المعروفة، بدل فقدان البيانات أو رمي استثناء.
enum WeatherCondition {
  sunny,
  cloudy,
  partlyCloudy,
  rainy,
  stormy,
  foggy,
  dusty,
  windy,
  extremeHeat,

  /// قيمة احتياطية عند عدم توفر بيانات الطقس أو عدم تطابق النص.
  unknown;

  String get dbValue {
    switch (this) {
      case WeatherCondition.sunny:
        return 'sunny';
      case WeatherCondition.cloudy:
        return 'cloudy';
      case WeatherCondition.partlyCloudy:
        return 'partly_cloudy';
      case WeatherCondition.rainy:
        return 'rainy';
      case WeatherCondition.stormy:
        return 'stormy';
      case WeatherCondition.foggy:
        return 'foggy';
      case WeatherCondition.dusty:
        return 'dusty';
      case WeatherCondition.windy:
        return 'windy';
      case WeatherCondition.extremeHeat:
        return 'extreme_heat';
      case WeatherCondition.unknown:
        return 'unknown';
    }
  }

  static WeatherCondition fromDbValue(String? value) {
    if (value == null) return WeatherCondition.unknown;
    return WeatherCondition.values.firstWhere(
      (WeatherCondition w) => w.dbValue == value,
      orElse: () => WeatherCondition.unknown,
    );
  }
}
