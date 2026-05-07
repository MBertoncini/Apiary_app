// File: lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../utils/navigator_key.dart';
import 'auth_token_provider.dart';

/// AuthTokenProvider basato su token statici, usato dal background sync service.
class _StaticTokenProvider implements AuthTokenProvider {
  String? _token;
  final String? _refreshToken;

  _StaticTokenProvider(this._token, this._refreshToken);

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.tokenRefreshUrl),
        body: {'refresh': _refreshToken},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _token = data['access'];
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<void> onSessionExpired() async {
    _token = null;
  }
}

class ApiService {
  final AuthTokenProvider _authService;

  ApiService(this._authService);

  /// Factory constructor per creare un ApiService a partire da token statici.
  /// Usato dal background sync service dove non c'e' un AuthService disponibile.
  factory ApiService.fromToken(String token, String refreshToken) {
    return ApiService(_StaticTokenProvider(token, refreshToken));
  }
  
  // Helper per costruire l'URL correttamente
  String _buildUrl(String endpoint) {
    // Verifica se l'endpoint è già un URL completo
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    
    // Verifica se l'endpoint è un URL completo con prefisso API
    if (endpoint.startsWith(ApiConstants.apiPrefix)) {
      return ApiConstants.baseUrl + endpoint;
    }
    
    // Assicura che l'endpoint inizi con / se non è già così
    if (!endpoint.startsWith('/') && endpoint.isNotEmpty) {
      endpoint = '/' + endpoint;
    }
    
    // Assicura che baseUrl non termini con / per evitare doppi slash
    String baseUrl = ApiConstants.baseUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    // Aggiungi il prefisso API se l'endpoint non lo include già
    if (!endpoint.startsWith(ApiConstants.apiPrefix)) {
      endpoint = ApiConstants.apiPrefix + endpoint;
    }
    
    // Costruisci l'URL completo
    final url = baseUrl + endpoint;
    return url;
  }
  
  // Headers per le richieste autenticate
  Future<Map<String, String>> get _headers async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  // Flag to prevent multiple simultaneous redirects to login
  static bool _isRedirectingToLogin = false;

  // Redirect to login page on session expiry
  void _handleSessionExpired() {
    if (_isRedirectingToLogin) return;
    _isRedirectingToLogin = true;

    debugPrint('Session expired: redirecting to login');

    // Clear auth state so AuthService is in sync with the UI
    _authService.onSessionExpired();

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppConstants.loginRoute,
      (route) => false,
    );

    // Reset flag after navigation completes
    Future.delayed(const Duration(seconds: 2), () {
      _isRedirectingToLogin = false;
    });
  }

  // Execute an HTTP request with automatic token refresh + retry on 401
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _headers;
    var response = await request(headers);

    if (response.statusCode == 401) {
      // Try to refresh the token
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Retry the request with the new token
        headers = await _headers;
        response = await request(headers);
      } else {
        // Refresh failed — session is truly expired
        _handleSessionExpired();
        throw Exception('Sessione scaduta. Effettua nuovamente il login.');
      }
    }

    return response;
  }

  // Handler generico per le risposte (no longer handles 401 — that's in _executeWithRetry)
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 429) {
      // Quota AI superata — lancia eccezione specifica
      Map<String, dynamic>? body;
      try {
        body = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {}
      throw QuotaExceededException(
        message: body?['error'] as String? ?? 'Quota AI giornaliera esaurita',
        tierLimits: body?['tier_limits'] as Map<String, dynamic>?,
      );
    } else {
      throw HttpStatusException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    final response = await _executeWithRetry(
      (headers) => http.get(uri, headers: headers),
    );
    return _handleResponse(response);
  }

  // GET di una list-resource paginata, seguendo `next` finché disponibile.
  // Senza questo, DRF (PAGE_SIZE=20) restituisce solo la prima pagina e
  // collezioni grandi (melari, controlli, smielature) appaiono troncate —
  // sintomo: aggiungere un nuovo elemento "fa sparire" un altro che era
  // semplicemente fuori dalla finestra dei primi 20.
  Future<List<dynamic>> getAll(String endpoint) async {
    final all = <dynamic>[];
    String? next = endpoint;
    var safety = 0;
    while (next != null) {
      if (++safety > 200) break; // hard cap a ~4000 record
      final res = await get(next);
      if (res is List) {
        all.addAll(res);
        return all; // endpoint non paginato
      }
      if (res is Map<String, dynamic>) {
        final results = res['results'];
        if (results is List) all.addAll(results);
        final n = res['next'];
        next = (n is String && n.isNotEmpty) ? n : null;
      } else {
        next = null;
      }
    }
    return all;
  }

  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    final response = await _executeWithRetry(
      (headers) => http.post(uri, headers: headers, body: json.encode(data)),
    );
    return _handleResponse(response);
  }

  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    final response = await _executeWithRetry(
      (headers) => http.put(uri, headers: headers, body: json.encode(data)),
    );
    return _handleResponse(response);
  }

  // PATCH request (aggiornamento parziale)
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    final response = await _executeWithRetry(
      (headers) => http.patch(uri, headers: headers, body: json.encode(data)),
    );
    return _handleResponse(response);
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    final response = await _executeWithRetry(
      (headers) => http.delete(uri, headers: headers),
    );
    return _handleResponse(response);
  }
  
  // Sincronizzazione dati
  Future<Map<String, dynamic>> syncData({String? lastSync}) async {
    String endpoint = ApiConstants.syncUrl;
    
    if (lastSync != null) {
      // Assicurati che il formato della data sia ISO 8601 completo
      try {
        // Verifica se lastSync è già in formato ISO completo
        if (!lastSync.contains('T') || !lastSync.endsWith('Z')) {
          // Se non lo è, converti in formato ISO 8601 completo
          final DateTime parsedDate = DateTime.parse(lastSync);
          lastSync = parsedDate.toUtc().toIso8601String();
          // Assicurati che termini con 'Z' per indicare UTC
          if (!lastSync.endsWith('Z')) {
            lastSync += 'Z';
          }
        }
      } catch (e) {
        debugPrint('Error formatting lastSync timestamp: $e');
      }
      
      // Aggiungi il parametro di query all'URL
      if (endpoint.contains('?')) {
        endpoint += '&last_sync=$lastSync';
      } else {
        endpoint += '?last_sync=$lastSync';
      }
    }
    
    final response = await get(endpoint);
    return response;
  }
  
  // === METODI PER ARNIE ===
  
  // Ottieni tutte le arnie
  Future<List<dynamic>> getArnie() async {
    final response = await get(ApiConstants.arnieUrl);
    return response is List ? response : [];
  }
  
  // Ottieni arnie di un apiario specifico
  Future<List<dynamic>> getArnieByApiario(int apiarioId) async {
    final response = await get('${ApiConstants.apiariUrl}$apiarioId/arnie/');
    return response is List ? response : [];
  }

  // Layout mappa apiario
  Future<dynamic> getMapLayout(int apiarioId) async {
    return await get('${ApiConstants.apiariUrl}$apiarioId/map_layout/');
  }

  Future<dynamic> saveMapLayout(int apiarioId, String layoutJson) async {
    return await put(
      '${ApiConstants.apiariUrl}$apiarioId/map_layout/',
      {'layout_json': layoutJson},
    );
  }

  // Ottieni dettagli di un'arnia specifica
  Future<dynamic> getArnia(int arniaId) async {
    return await get('${ApiConstants.arnieUrl}$arniaId/');
  }
  
  // Crea una nuova arnia
  Future<dynamic> createArnia(Map<String, dynamic> data) async {
    return await post(ApiConstants.arnieUrl, data);
  }
  
  // Aggiorna un'arnia esistente
  Future<dynamic> updateArnia(int arniaId, Map<String, dynamic> data) async {
    return await put('${ApiConstants.arnieUrl}$arniaId/', data);
  }
  
  // === METODI PER COLONIE ===

  Future<List<dynamic>> getColonie() async {
    final response = await get(ApiConstants.colonieUrl);
    if (response is List) return response;
    if (response is Map && response['results'] is List) return response['results'] as List;
    return [];
  }

  Future<dynamic> getColonia(int coloniaId) async {
    return await get('${ApiConstants.colonieUrl}$coloniaId/');
  }

  Future<dynamic> getColoniaAttivaByArnia(int arniaId) async {
    return await get('${ApiConstants.arnieUrl}$arniaId/colonia_attiva/');
  }

  Future<List<dynamic>> getStoriaColonieByArnia(int arniaId) async {
    final response = await get('${ApiConstants.arnieUrl}$arniaId/storia_colonie/');
    if (response is List) return response;
    if (response is Map && response['results'] is List) return response['results'] as List;
    return [];
  }

  Future<dynamic> createColonia(Map<String, dynamic> data) async {
    return await post(ApiConstants.colonieUrl, data);
  }

  Future<dynamic> chiudiColonia(int coloniaId, Map<String, dynamic> data) async {
    return await post('${ApiConstants.colonieUrl}$coloniaId/chiudi/', data);
  }

  Future<dynamic> spostaColonia(int coloniaId, Map<String, dynamic> data) async {
    return await post('${ApiConstants.colonieUrl}$coloniaId/sposta_contenitore/', data);
  }

  Future<List<dynamic>> getControlliByColonia(int coloniaId, {int? days}) async {
    var url = '${ApiConstants.colonieUrl}$coloniaId/controlli/';
    if (days != null) url += '?days=$days';
    final response = await get(url);
    if (response is List) return response;
    if (response is Map && response['results'] is List) return response['results'] as List;
    return [];
  }

  Future<dynamic> getReginaByColonia(int coloniaId) async {
    return await get('${ApiConstants.colonieUrl}$coloniaId/regina/');
  }

  // === METODI PER REGINE ===

  // Ottieni tutte le regine
  Future<List<dynamic>> getRegine() async {
    final response = await get(ApiConstants.regineUrl);
    return response is List ? response : [];
  }
  
  // Ottieni regina per una specifica arnia
  Future<dynamic> getReginaByArnia(int arniaId) async {
    return await get('${ApiConstants.arnieUrl}$arniaId/regina/');
  }
  
  // Ottieni dettagli di una regina specifica
  Future<dynamic> getRegina(int reginaId) async {
    return await get('${ApiConstants.regineUrl}$reginaId/');
  }
  
  // Crea una regina (POST diretto a /regine/, includere 'arnia' e/o 'colonia').
  Future<dynamic> addRegina(Map<String, dynamic> data) async {
    return await post(ApiConstants.regineUrl, data);
  }

  // Sostituisci una regina via azione custom: POST /regine/{id}/sostituisci/
  Future<dynamic> replaceRegina(int reginaId, Map<String, dynamic> data) async {
    return await post(ApiConstants.reginaSostituisciUrlOf(reginaId), data);
  }


  // === METODI PER TRATTAMENTI SANITARI ===
  
  // Ottieni tutti i trattamenti
  Future<List<dynamic>> getTrattamenti() async {
    final response = await get(ApiConstants.trattamentiUrl);
    return response is List ? response : [];
  }
  
  // Ottieni trattamenti attivi
  Future<List<dynamic>> getTrattamentiAttivi() async {
    final response = await get('${ApiConstants.trattamentiUrl}attivi/');
    return response is List ? response : [];
  }
  
  // Ottieni dettagli di un trattamento specifico
  Future<dynamic> getTrattamento(int trattamentoId) async {
    return await get('${ApiConstants.trattamentiUrl}$trattamentoId/');
  }
  
  // Crea un nuovo trattamento
  Future<dynamic> createTrattamento(Map<String, dynamic> data) async {
    return await post(ApiConstants.trattamentiUrl, data);
  }
  
  // Aggiorna un trattamento esistente
  Future<dynamic> updateTrattamento(int trattamentoId, Map<String, dynamic> data) async {
    return await put('${ApiConstants.trattamentiUrl}$trattamentoId/', data);
  }
  
  // Cambia lo stato di un trattamento
  Future<dynamic> updateTrattamentoStatus(int trattamentoId, String nuovoStato) async {
    return await post('${ApiConstants.trattamentiUrl}$trattamentoId/stato/$nuovoStato/', {});
  }
  
  // Ottieni tipi di trattamento
  Future<List<dynamic>> getTipiTrattamento() async {
    final response = await get(ApiConstants.tipiTrattamentoUrl);
    return response is List ? response : [];
  }
  
  // === METODI PER MELARI E PRODUZIONI ===
  
  // Ottieni tutti i melari
  Future<List<dynamic>> getMelari() async {
    final response = await get(ApiConstants.melariUrl);
    return response is List ? response : [];
  }
  
  // Ottieni dettagli di un melario specifico
  Future<dynamic> getMelario(int melarioId) async {
    return await get('${ApiConstants.melariUrl}$melarioId/');
  }
  
  // Aggiungi un melario ad un'arnia
  Future<dynamic> addMelario(int arniaId, Map<String, dynamic> data) async {
    return await post('${ApiConstants.arnieUrl}$arniaId/melario/aggiungi/', data);
  }
  
  // Rimuovi un melario.
  // Il backend non espone l'action `rimuovi/` sul MelarioViewSet (solo CRUD
  // standard via DRF router), quindi facciamo PATCH con stato='rimosso' e i
  // campi data_rimozione/peso_stimato passati dall'UI. Il signal m2m_changed
  // su Smielatura.melari gestirà poi le transizioni a 'smielato' al momento
  // della creazione della smielatura.
  Future<dynamic> removeMelario(int melarioId, {Map<String, dynamic>? data}) async {
    final payload = <String, dynamic>{
      'stato': 'rimosso',
      ...?data,
    };
    return await patch('${ApiConstants.melariUrl}$melarioId/', payload);
  }

  // Invia un melario in smielatura: PATCH stato='in_smielatura'. Stesso
  // motivo di removeMelario: l'endpoint custom non esiste sul backend.
  Future<dynamic> sendMelarioToSmielatura(int melarioId) async {
    return await patch(
      '${ApiConstants.melariUrl}$melarioId/',
      {'stato': 'in_smielatura'},
    );
  }
  
  // Ottieni tutte le smielature
  Future<List<dynamic>> getSmielature() async {
    final response = await get(ApiConstants.produzioniUrl);
    return response is List ? response : [];
  }
  
  // Registra una nuova smielatura
  Future<dynamic> createSmielatura(int apiarioId, Map<String, dynamic> data) async {
    return await post('${ApiConstants.apiariUrl}$apiarioId/smielatura/registra/', data);
  }
  
  // PATCH multipart request (for file updates, e.g. profile image)
  Future<dynamic> patchMultipart(
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String fileField = 'immagine',
  }) async {
    final uri = Uri.parse(_buildUrl(endpoint));

    Future<http.Response> sendRequest(Map<String, String> headers) async {
      final request = http.MultipartRequest('PATCH', uri);
      request.headers.addAll({
        'Authorization': headers['Authorization']!,
        'Accept': 'application/json',
      });
      request.fields.addAll(fields);
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }
      final streamed = await request.send();
      return await http.Response.fromStream(streamed);
    }

    final headers = await _headers;
    var response = await sendRequest(headers);

    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        final newHeaders = await _headers;
        response = await sendRequest(newHeaders);
      } else {
        _handleSessionExpired();
        throw Exception('Sessione scaduta. Effettua nuovamente il login.');
      }
    }

    return _handleResponse(response);
  }

  // POST multipart request (for file uploads)
  Future<dynamic> postMultipart(
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String fileField = 'immagine',
  }) async {
    final uri = Uri.parse(_buildUrl(endpoint));

    Future<http.Response> sendRequest(Map<String, String> headers) async {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': headers['Authorization']!,
        'Accept': 'application/json',
      });
      request.fields.addAll(fields);
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }
      final streamed = await request.send();
      return await http.Response.fromStream(streamed);
    }

    final headers = await _headers;
    var response = await sendRequest(headers);

    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        final newHeaders = await _headers;
        response = await sendRequest(newHeaders);
      } else {
        _handleSessionExpired();
        throw Exception('Sessione scaduta. Effettua nuovamente il login.');
      }
    }

    return _handleResponse(response);
  }

  // Metodo di debug per verificare la costruzione degli URL
  void printDebugInfo() {
    if (kDebugMode) {
      debugPrint('API Constants Debug Info:');
      debugPrint('baseUrl: ${ApiConstants.baseUrl}');
      debugPrint('apiPrefix: ${ApiConstants.apiPrefix}');
      debugPrint('Esempio URL costruito: ${_buildUrl("inviti/ricevuti/")}');
      debugPrint('Esempio URL con leading slash: ${_buildUrl("/inviti/ricevuti/")}');
    }
  }
}


/// Eccezione lanciata quando la quota AI giornaliera è esaurita (HTTP 429).
class QuotaExceededException implements Exception {
  final String message;
  final Map<String, dynamic>? tierLimits;

  QuotaExceededException({required this.message, this.tierLimits});

  @override
  String toString() => message;
}

/// Eccezione che porta con sé lo status HTTP per consentire ai chiamanti
/// di distinguere 4xx (errore client, non riprovabile) da 5xx (transitorio).
class HttpStatusException implements Exception {
  final int statusCode;
  final String body;

  HttpStatusException({required this.statusCode, required this.body});

  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  @override
  String toString() => 'Errore API: $statusCode $body';
}