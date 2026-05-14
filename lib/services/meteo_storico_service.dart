// File: lib/services/meteo_storico_service.dart
import '../constants/api_constants.dart';
import '../models/meteo_giornaliero.dart';
import 'api_service.dart';

/// Servizio per leggere/triggerare il dataset MeteoGiornaliero dal backend.
///
/// I dati live (meteo attuale + previsioni a 5gg) restano sul `WeatherWidget`
/// che chiama Open-Meteo direttamente. Questo servizio è dedicato allo storico
/// giornaliero usato per grafici e per i modelli ML.
class MeteoStoricoService {
  final ApiService _api;

  MeteoStoricoService(this._api);

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Restituisce il dataset giornaliero per un apiario nel range richiesto.
  /// Se [start]/[end] non sono passati, il backend ritorna l'ultimo anno.
  Future<List<MeteoGiornaliero>> getMeteoGiornaliero(
    int apiarioId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final url = ApiConstants.apiarioMeteoGiornalieroUrlOf(apiarioId);
    final params = <String>[];
    if (start != null) params.add('start=${_fmt(start)}');
    if (end != null) params.add('end=${_fmt(end)}');
    final fullUrl = params.isEmpty ? url : '$url?${params.join('&')}';

    final response = await _api.get(fullUrl);
    final List<dynamic> rows = response is Map && response.containsKey('results')
        ? response['results'] as List<dynamic>
        : (response as List<dynamic>);
    return rows
        .map((j) => MeteoGiornaliero.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Aggregati statistici sul range richiesto.
  Future<MeteoStats> getStats(
    int apiarioId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final url = ApiConstants.apiarioMeteoGiornalieroStatsUrlOf(apiarioId);
    final params = <String>[];
    if (start != null) params.add('start=${_fmt(start)}');
    if (end != null) params.add('end=${_fmt(end)}');
    final fullUrl = params.isEmpty ? url : '$url?${params.join('&')}';

    final response = await _api.get(fullUrl);
    return MeteoStats.fromJson(response as Map<String, dynamic>);
  }

  /// Trigger del backfill per un singolo apiario.
  /// Idempotente: si può chiamare a piacere.
  Future<Map<String, dynamic>> triggerBackfill(
    int apiarioId, {
    int? maxDays,
  }) async {
    final url = ApiConstants.apiarioMeteoGiornalieroBackfillUrlOf(apiarioId);
    final body = <String, dynamic>{};
    if (maxDays != null) body['max_days'] = maxDays;
    final response = await _api.post(url, body);
    return (response as Map<String, dynamic>);
  }
}
