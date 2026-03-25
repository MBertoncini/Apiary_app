import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Dati meteo attuali da Open-Meteo
class CurrentWeatherData {
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double windSpeed;
  final double precipitation;
  final double pressure;
  final int weatherCode;
  final DateTime time;
  final bool isDay;

  CurrentWeatherData({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.pressure,
    required this.weatherCode,
    required this.time,
    required this.isDay,
  });
}

/// Previsione per un singolo giorno
class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final double precipitationSum;

  DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
  });
}

/// Risposta completa dal servizio meteo
class MeteoData {
  final CurrentWeatherData current;
  final List<DailyForecast> daily;

  MeteoData({required this.current, required this.daily});
}

/// Servizio meteo basato su Open-Meteo (gratuito, no API key)
class MeteoService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<MeteoData?> fetchMeteo(double latitude, double longitude) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': [
        'temperature_2m',
        'apparent_temperature',
        'relative_humidity_2m',
        'wind_speed_10m',
        'precipitation',
        'weather_code',
        'surface_pressure',
        'is_day',
      ].join(','),
      'daily': [
        'weather_code',
        'temperature_2m_max',
        'temperature_2m_min',
        'precipitation_sum',
      ].join(','),
      'forecast_days': '7',
      'timezone': 'auto',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint('MeteoService: HTTP ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final cur = json['current'] as Map<String, dynamic>;
      final dai = json['daily'] as Map<String, dynamic>;

      final current = CurrentWeatherData(
        temperature: (cur['temperature_2m'] as num).toDouble(),
        apparentTemperature: (cur['apparent_temperature'] as num).toDouble(),
        humidity: (cur['relative_humidity_2m'] as num).toDouble(),
        windSpeed: (cur['wind_speed_10m'] as num).toDouble(),
        precipitation: (cur['precipitation'] as num).toDouble(),
        pressure: (cur['surface_pressure'] as num).toDouble(),
        weatherCode: cur['weather_code'] as int,
        time: DateTime.parse(cur['time'] as String),
        isDay: (cur['is_day'] as int? ?? 1) == 1,
      );

      final dates = dai['time'] as List;
      final codes = dai['weather_code'] as List;
      final maxTemps = dai['temperature_2m_max'] as List;
      final minTemps = dai['temperature_2m_min'] as List;
      final precips = dai['precipitation_sum'] as List;

      final daily = List.generate(dates.length, (i) => DailyForecast(
        date: DateTime.parse(dates[i] as String),
        weatherCode: codes[i] as int,
        tempMax: (maxTemps[i] as num).toDouble(),
        tempMin: (minTemps[i] as num).toDouble(),
        precipitationSum: (precips[i] as num?)?.toDouble() ?? 0.0,
      ));

      return MeteoData(current: current, daily: daily);
    } catch (e) {
      debugPrint('MeteoService error: $e');
      return null;
    }
  }

  /// Descrizione testuale italiana del codice WMO
  static String descriptionFromCode(int code, {bool isDay = true}) {
    if (code == 0) return isDay ? 'Cielo sereno' : 'Notte serena';
    if (code == 1) return isDay ? 'Prevalentemente sereno' : 'Prevalentemente sereno';
    if (code == 2) return 'Parzialmente nuvoloso';
    if (code == 3) return 'Coperto';
    if (code == 45 || code == 48) return 'Nebbia';
    if (code >= 51 && code <= 55) return 'Pioggerella';
    if (code >= 56 && code <= 57) return 'Pioggerella gelata';
    if (code >= 61 && code <= 65) return 'Pioggia';
    if (code >= 66 && code <= 67) return 'Pioggia gelata';
    if (code >= 71 && code <= 75) return 'Neve';
    if (code == 77) return 'Granuli di neve';
    if (code >= 80 && code <= 82) return 'Rovesci di pioggia';
    if (code >= 85 && code <= 86) return 'Rovesci di neve';
    if (code == 95) return 'Temporale';
    if (code == 96 || code == 99) return 'Temporale con grandine';
    return 'Non disponibile';
  }
}
