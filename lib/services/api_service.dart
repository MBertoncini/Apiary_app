// File: lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
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
        final data = json.decode(response.body);
        _token = data['access'];
        return true;
      }
    } catch (_) {}
    return false;
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
  
  // Handler generico per le risposte
  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token scaduto, prova a rinnovarlo
      final success = await _authService.refreshToken();
      if (!success) {
        throw Exception('Sessione scaduta. Effettua nuovamente il login.');
      }
      throw Exception('Token rinnovato. Riprova l\'operazione.');
    } else {
      throw Exception('Errore API: ${response.statusCode} ${response.body}');
    }
  }
  
  // GET request
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    final headers = await _headers;
    
    final response = await http.get(
      uri,
      headers: headers,
    );
    return _handleResponse(response);
  }
  
  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    final headers = await _headers;
    
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }
  
  // PUT request (invece di patch)
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    final headers = await _headers;
    
    final response = await http.put(
      uri,
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }
  
  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    final headers = await _headers;
    
    final response = await http.delete(
      uri,
      headers: headers,
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
  
  // Aggiungi una regina ad un'arnia
  Future<dynamic> addRegina(int arniaId, Map<String, dynamic> data) async {
    return await post('${ApiConstants.arnieUrl}$arniaId/regina/aggiungi/', data);
  }
  
  // Sostituisci una regina di un'arnia
  Future<dynamic> replaceRegina(int arniaId, Map<String, dynamic> data) async {
    return await post('${ApiConstants.arnieUrl}$arniaId/regina/sostituisci/', data);
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
  
  // Rimuovi un melario
  Future<dynamic> removeMelario(int melarioId) async {
    return await post('${ApiConstants.melariUrl}$melarioId/rimuovi/', {});
  }
  
  // Invia un melario in smielatura
  Future<dynamic> sendMelarioToSmielatura(int melarioId) async {
    return await post('${ApiConstants.melariUrl}$melarioId/smielatura/', {});
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