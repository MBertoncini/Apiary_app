import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService;
  
  ApiService(this._authService);
  
  // Headers per le richieste autenticate
  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${_authService.token}',
    };
  }
  
  // Handler generico per le risposte
  dynamic _handleResponse(http.Response response) async {
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
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }
  
  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }
  
  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }
  
  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }
  
  // Sincronizzazione dati
  Future<Map<String, dynamic>> syncData({String? lastSync}) async {
    String url = ApiConstants.syncUrl;
    if (lastSync != null) {
      url += '?last_sync=$lastSync';
    }
    
    final response = await get(url);
    return response;
  }
}