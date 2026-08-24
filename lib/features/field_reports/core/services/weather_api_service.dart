import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/network_exception.dart';
import '../../../../domain/enums/weather_condition.dart';

/// قراءة طقس لحظية واحدة — [WeatherCondition] مصنَّف + درجة الحرارة
/// الخام بالمئوية، جاهزة مباشرة لتعبئة `weather_selector.dart` دون أي
/// تحويل إضافي من طبقة العرض.
class WeatherReading {
  const WeatherReading({required this.condition, required this.temperatureC});

  final WeatherCondition condition;
  final double temperatureC;
}

/// خدمة استدعاء API الطقس المجاني (Open-Meteo، بلا مفتاح API مطلوب)
/// بناءً على إحداثيات GPS الحالية — تُستخدم من `report_form_cubit.dart`
/// (Prompt 17) لتعبئة حقلَي الطقس/درجة الحرارة تلقائياً عند فتح نموذج
/// تقرير جديد، مع بقاء الحقلين قابلين للتعديل اليدوي دوماً بعدها. 🆕
///
/// ⚠️ خدمة محلية لهذه الميزة تحديداً (`lib/features/field_reports/core/`)
/// وليست ضمن `core/services/` العامة — لا استهلاك لها من أي ميزة أخرى
/// حالياً، بخلاف [LocationService]/[CameraService] ونحوهما.
class WeatherApiService {
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// يجلب حالة الطقس ودرجة الحرارة الحاليتين لإحداثيات [latitude]/
  /// [longitude] معطاة (عادةً موقع المشروع أو موقع الجهاز الحالي عبر
  /// `LocationService.currentLocation()`).
  Future<ResultOf<WeatherReading>> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = Uri.parse(_baseUrl).replace(
      queryParameters: <String, String>{
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current': 'temperature_2m,weather_code,wind_speed_10m',
        'timezone': 'auto',
      },
    );

    try {
      final http.Response response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Left<Failure, WeatherReading>(
          Failure.fromException(
            NetworkException.serverError(statusCode: response.statusCode),
          ),
        );
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic>? current =
          body['current'] as Map<String, dynamic>?;
      if (current == null) {
        return Left<Failure, WeatherReading>(
          Failure.fromException(NetworkException.malformedResponse()),
        );
      }

      final double temperatureC =
          (current['temperature_2m'] as num?)?.toDouble() ?? 0;
      final int weatherCode = (current['weather_code'] as num?)?.toInt() ?? -1;
      final double windSpeedKmh =
          (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;

      return Right<Failure, WeatherReading>(
        WeatherReading(
          condition: _classify(
            weatherCode: weatherCode,
            temperatureC: temperatureC,
            windSpeedKmh: windSpeedKmh,
          ),
          temperatureC: temperatureC,
        ),
      );
    } on FormatException catch (error, stackTrace) {
      return Left<Failure, WeatherReading>(
        Failure.fromException(
          NetworkException.malformedResponse(cause: error, st: stackTrace),
        ),
      );
    } catch (error, stackTrace) {
      return Left<Failure, WeatherReading>(
        Failure.fromException(
          NetworkException.timeout(cause: error, st: stackTrace),
        ),
      );
    }
  }

  /// يحوّل رمز طقس WMO (`weather_code` — معيار Open-Meteo القياسي) إلى
  /// [WeatherCondition] معياري للتطبيق، مع تجاوزات مناخية لمواقع عمل
  /// إنشائية في مناخ حار/غباري (حرارة قصوى، رياح شديدة).
  WeatherCondition _classify({
    required int weatherCode,
    required double temperatureC,
    required double windSpeedKmh,
  }) {
    // تجاوز أولوية: حرارة قصوى تفوق أي وصف آخر لسلامة العمّال الميدانيين
    // (عتبة شائعة لمواقع البناء في مناخ العراق الصيفي).
    if (temperatureC >= 45) return WeatherCondition.extremeHeat;

    switch (weatherCode) {
      case 0:
        return WeatherCondition.sunny;
      case 1:
      case 2:
        return WeatherCondition.partlyCloudy;
      case 3:
        return WeatherCondition.cloudy;
      case 45:
      case 48:
        return WeatherCondition.foggy;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return WeatherCondition.rainy;
      case 95:
      case 96:
      case 99:
        return WeatherCondition.stormy;
      default:
        // رياح شديدة (>40 كم/س) دون هطول واضح — تُصنَّف عاصفة رياح/غبار
        // بدل تركها "غير معروفة"، مفيد لمواقع مكشوفة عرضة للغبار.
        if (windSpeedKmh >= 40) return WeatherCondition.windy;
        return WeatherCondition.unknown;
    }
  }

  void dispose() => _client.close();
}
