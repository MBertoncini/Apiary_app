import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../constants/api_constants.dart';

/// Servizio per il modulo Statistiche & AI Analytics.
/// Gli endpoint statistiche sono sotto /api/stats/ (non /api/v1/).
class StatisticheService {
  final ApiService _api;

  StatisticheService(this._api);

  /// Costruisce URL per l'endpoint stats (prefisso /api/stats/)
  String _statsUrl(String path, [Map<String, String>? params]) {
    String base = ApiConstants.baseUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    String url = '$base/api/stats/$path/';
    if (params != null && params.isNotEmpty) {
      final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      url = '$url?$query';
    }
    return url;
  }

  Future<Map<String, dynamic>> _getStats(String path, [Map<String, String>? params]) async {
    final result = await _api.get(_statsUrl(path, params));
    if (result is Map<String, dynamic>) return result;
    return {};
  }

  Future<Map<String, dynamic>> _postStats(String path, Map<String, dynamic> body) async {
    final result = await _api.post(_statsUrl(path), body);
    if (result is Map<String, dynamic>) return result;
    return {};
  }

  // -------------------------------------------------------------------------
  // Widget data
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> getSaluteArnie({int periodoDays = 90, int? apiarioId}) {
    final p = {'periodo_giorni': periodoDays.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/salute_arnie', p);
  }

  Future<Map<String, dynamic>> getProduzioneAnnuale({int anni = 3, int? apiarioId}) {
    final p = {'anni': anni.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/produzione_annuale', p);
  }

  Future<Map<String, dynamic>> getFrequenzaControlli({int? anno, int? apiarioId}) {
    final p = <String, String>{};
    if (anno != null) p['anno'] = anno.toString();
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/frequenza_controlli', p);
  }

  Future<Map<String, dynamic>> getRegineStatistiche({int? anno}) {
    final p = <String, String>{};
    if (anno != null) p['anno'] = anno.toString();
    return _getStats('widgets/regine_statistiche', p);
  }

  Future<Map<String, dynamic>> getPerformanceRegine({int? apiarioId, int topN = 5}) {
    final p = {'mostra_top_n': topN.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/performance_regine', p);
  }

  Future<Map<String, dynamic>> getVarroaTrend({int mesi = 12, int? apiarioId}) {
    final p = {'periodo_mesi': mesi.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/varroa_trend', p);
  }

  Future<Map<String, dynamic>> getBilancioEconomico({int? anno}) {
    final p = <String, String>{};
    if (anno != null) p['anno'] = anno.toString();
    return _getStats('widgets/bilancio_economico', p);
  }

  Future<Map<String, dynamic>> getQuoteGruppo({int? gruppoId, int? anno}) {
    final p = <String, String>{};
    if (gruppoId != null) p['gruppo_id'] = gruppoId.toString();
    if (anno != null) p['anno'] = anno.toString();
    return _getStats('widgets/quote_gruppo', p);
  }

  Future<Map<String, dynamic>> getFioritureVicine({double raggioKm = 5.0}) {
    return _getStats('widgets/fioriture_vicine', {'raggio_km': raggioKm.toString()});
  }

  Future<Map<String, dynamic>> getAndamentoScorte({int mesi = 6, int? apiarioId}) {
    final p = {'periodo_mesi': mesi.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/andamento_scorte', p);
  }

  Future<Map<String, dynamic>> getProduzionePerTipo({int? anno}) {
    final p = <String, String>{};
    if (anno != null) p['anno'] = anno.toString();
    return _getStats('widgets/produzione_per_tipo', p);
  }

  Future<Map<String, dynamic>> getRiepilogoAttrezzature({String? categoria}) {
    final p = <String, String>{};
    if (categoria != null) p['categoria'] = categoria;
    return _getStats('widgets/riepilogo_attrezzature', p);
  }

  // -------------------------------------------------------------------------
  // Dashboard config
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> getDashboardConfig() => _getStats('dashboard');

  Future<void> saveDashboardConfig(List<Map<String, dynamic>> widgetConfig) async {
    await _postStats('dashboard', {'widget_config': widgetConfig});
  }

  // -------------------------------------------------------------------------
  // Query builder
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> eseguiQueryBuilder(Map<String, dynamic> payload) {
    return _postStats('query-builder', payload);
  }

  // -------------------------------------------------------------------------
  // NL Query (AI)
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> chiediAI(String domanda) {
    return _postStats('nl-query', {'domanda': domanda});
  }

  // -------------------------------------------------------------------------
  // Export (returns raw bytes for file download)
  // -------------------------------------------------------------------------

  Future<List<int>> exportExcel(String titolo, List<String> colonne, List<List<dynamic>> righe) async {
    return _exportRaw('export/excel', titolo, colonne, righe);
  }

  Future<List<int>> exportPdf(String titolo, List<String> colonne, List<List<dynamic>> righe) async {
    return _exportRaw('export/pdf', titolo, colonne, righe);
  }

  Future<List<int>> _exportRaw(
    String path,
    String titolo,
    List<String> colonne,
    List<List<dynamic>> righe,
  ) async {
    // Uses _api directly to get raw bytes
    final result = await _api.post(_statsUrl(path), {
      'titolo': titolo,
      'colonne': colonne,
      'righe': righe,
    });
    // The API returns bytes wrapped — this is a fallback
    // In production, call via http directly for binary response
    if (result is List) return List<int>.from(result);
    return [];
  }
}
