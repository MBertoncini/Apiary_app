// File: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService;
  
  ApiService(this._authService);
  
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
    print('DEBUG - Built URL: $url'); // Per debug
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
    
    print('GET request to: $uri'); // Per debug
    
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
    
    print('POST request to: $uri'); // Per debug
    print('POST data: ${json.encode(data)}'); // Per debug
    
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
    
    print('PUT request to: $uri'); // Per debug
    
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
    
    print('DELETE request to: $uri'); // Per debug
    
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
        print('Error formatting lastSync timestamp: $e');
      }
      
      // Aggiungi il parametro di query all'URL
      if (endpoint.contains('?')) {
        endpoint += '&last_sync=$lastSync';
      } else {
        endpoint += '?last_sync=$lastSync';
      }
    }
    
    print('Sync URL: $endpoint'); // Per debug
    final response = await get(endpoint);
    return response;
  }
  
  // Metodo di debug per verificare la costruzione degli URL
  void printDebugInfo() {
    print('API Constants Debug Info:');
    print('baseUrl: ${ApiConstants.baseUrl}');
    print('apiPrefix: ${ApiConstants.apiPrefix}');
    print('Esempio URL costruito: ${_buildUrl("inviti/ricevuti/")}');
    print('Esempio URL con leading slash: ${_buildUrl("/inviti/ricevuti/")}');
  }
}