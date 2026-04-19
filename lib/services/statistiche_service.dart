import 'api_service.dart';
import '../constants/api_constants.dart';
import 'ai_quota_service.dart';

/// Servizio per il modulo Statistiche & AI Analytics.
/// Gli endpoint statistiche sono sotto /api/stats/ (non /api/v1/).
class StatisticheService {
  final ApiService _api;
  AiQuotaService? _quotaService;

  StatisticheService(this._api, {AiQuotaService? quotaService})
      : _quotaService = quotaService;

  /// Collega il servizio centralizzato di quota AI per gating NL query.
  void attachQuotaService(AiQuotaService? svc) {
    _quotaService = svc;
  }

  // Cache statica in-memory: dati validi finché non esplicitamente invalidati.
  // Chiave: 'path|param1=val1&...' (params ordinati per stabilità).
  static final Map<String, Map<String, dynamic>> _cache = {};

  /// Invalida tutta la cache (usato dal pull-to-refresh globale).
  static void clearAllCache() => _cache.clear();

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

  Future<Map<String, dynamic>> _getStats(String path, [Map<String, String>? params, bool forceRefresh = false]) async {
    final sortedParams = params == null
        ? ''
        : (params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
            .map((e) => '${e.key}=${e.value}')
            .join('&');
    final cacheKey = params == null ? path : '$path|$sortedParams';
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    final result = await _api.get(_statsUrl(path, params));
    final data = result is Map<String, dynamic> ? result : <String, dynamic>{};
    _cache[cacheKey] = data;
    return data;
  }

  Future<Map<String, dynamic>> _postStats(String path, Map<String, dynamic> body) async {
    final result = await _api.post(_statsUrl(path), body);
    if (result is Map<String, dynamic>) return result;
    return {};
  }

  // -------------------------------------------------------------------------
  // Widget data
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> getSaluteArnie({int periodoDays = 90, int? apiarioId, bool forceRefresh = false}) {
    final p = {'periodo_giorni': periodoDays.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/salute_arnie', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getProduzioneAnnuale({int anni = 3, int? apiarioId, bool forceRefresh = false}) {
    final p = {'anni': anni.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/produzione_annuale', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getFrequenzaControlli({int? anno, int? apiarioId, bool forceRefresh = false}) {
    final p = <String, String>{};
    if (anno != null) p['anno'] = anno.toString();
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/frequenza_controlli', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getRegineStatistiche({int? anno, bool forceRefresh = false}) {
    final p = <String, String>{};
    if (anno != null) p['anno'] = anno.toString();
    return _getStats('widgets/regine_statistiche', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getPerformanceRegine({int? apiarioId, int topN = 5, bool forceRefresh = false}) {
    final p = {'mostra_top_n': topN.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/performance_regine', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getVarroaTrend({int mesi = 12, int? apiarioId, bool forceRefresh = false}) {
    final p = {'periodo_mesi': mesi.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/varroa_trend', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getBilancioEconomico({int? anno, bool forceRefresh = false}) {
    final p = <String, String>{};
    if (anno != null) p['anno'] = anno.toString();
    return _getStats('widgets/bilancio_economico', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getQuoteGruppo({int? gruppoId, int? anno, bool forceRefresh = false}) {
    final p = <String, String>{};
    if (gruppoId != null) p['gruppo_id'] = gruppoId.toString();
    if (anno != null) p['anno'] = anno.toString();
    return _getStats('widgets/quote_gruppo', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getFioritureVicine({double raggioKm = 5.0, bool forceRefresh = false}) {
    return _getStats('widgets/fioriture_vicine', {'raggio_km': raggioKm.toString()}, forceRefresh);
  }

  Future<Map<String, dynamic>> getAndamentoScorte({int mesi = 6, int? apiarioId, bool forceRefresh = false}) {
    final p = {'periodo_mesi': mesi.toString()};
    if (apiarioId != null) p['apiario_id'] = apiarioId.toString();
    return _getStats('widgets/andamento_scorte', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getProduzionePerTipo({int? anno, bool forceRefresh = false}) {
    final p = <String, String>{};
    if (anno != null) p['anno'] = anno.toString();
    return _getStats('widgets/produzione_per_tipo', p, forceRefresh);
  }

  Future<Map<String, dynamic>> getRiepilogoAttrezzature({String? categoria, bool forceRefresh = false}) {
    final p = <String, String>{};
    if (categoria != null) p['categoria'] = categoria;
    return _getStats('widgets/riepilogo_attrezzature', p, forceRefresh);
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

  Future<Map<String, dynamic>> chiediAI(String domanda, {String? groqApiKey}) async {
    // Pre-check quota: la feature stats è bloccata se il pool condiviso è
    // esaurito e l'utente non ha configurato una chiave Groq personale.
    final quota = _quotaService;
    if (quota != null && !quota.canCall(AiFeature.stats)) {
      throw QuotaExceededException(
        message: 'Quota AI statistiche esaurita. Riprova dopo il reset o '
            'configura una chiave Groq personale.',
      );
    }
    final body = <String, dynamic>{'domanda': domanda};
    if (groqApiKey != null && groqApiKey.isNotEmpty) {
      body['groq_api_key'] = groqApiKey;
    }
    try {
      final result = await _postStats('nl-query', body);
      _quotaService?.recordOptimisticCall(AiFeature.stats);
      return result;
    } on QuotaExceededException {
      _quotaService?.markExceeded(AiFeature.stats);
      rethrow;
    }
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
