// File: lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';
import 'dart:async';

class AuthService extends ChangeNotifier {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _offlineMode = false;
  String? _token;
  String? _refreshToken;
  User? _currentUser;
  String? _lastError;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isOfflineMode => _offlineMode;
  String? get token => _token;
  String? get refreshTokenValue => _refreshToken;
  String? get lastError => _lastError;
  User? get currentUser => _currentUser;

  // Costruttore
  AuthService() {
    // Verifica l'autenticazione all'avvio
    checkAuth();
  }

  // Verifica lo stato dell'autenticazione
  Future<bool> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Recupera token salvati
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(AppConstants.tokenKey);
      final savedRefreshToken = prefs.getString(AppConstants.refreshTokenKey);
      final savedUserInfo = prefs.getString(AppConstants.userInfoKey);

      if (savedToken != null && savedRefreshToken != null) {
        // Imposta i token in memoria
        _token = savedToken;
        _refreshToken = savedRefreshToken;

        // Prova a recuperare l'utente dalla cache
        if (savedUserInfo != null) {
          try {
            _currentUser = User.fromJson(json.decode(savedUserInfo));
            _isAuthenticated = true;
            _isLoading = false;
            notifyListeners();
            
            // Tenta di aggiornare i dati dell'utente in background
            _fetchUserInfo().then((user) {
              if (user != null) {
                _currentUser = user;
                notifyListeners();
              }
            }).catchError((_) {
              // Fallback a modalità offline se non riesci a comunicare col server
              _offlineMode = true;
              notifyListeners();
            });
            
            return true;
          } catch (e) {
            print('Error parsing saved user info: $e');
          }
        }

        // Verifica la validità del token recuperando le info dell'utente
        final userInfo = await _fetchUserInfo();
        if (userInfo != null) {
          _currentUser = userInfo;
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          // Prova a estrarre info utente dal token
          extractUserFromToken();
          if (_currentUser != null) {
            _isAuthenticated = true;
            _isLoading = false;
            notifyListeners();
            return true;
          }
          
          // Prova a rinnovare il token
          final refreshed = await refreshToken();
          _isLoading = false;
          notifyListeners();
          return refreshed;
        }
      }
    } catch (e) {
      print('Error checking auth: $e');
      
      // Verifica se abbiamo informazioni utente salvate per la modalità offline
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedUserInfo = prefs.getString(AppConstants.userInfoKey);
        
        if (savedUserInfo != null) {
          _currentUser = User.fromJson(json.decode(savedUserInfo));
          _isAuthenticated = true;
          _offlineMode = true;
          print('Fallback to offline mode with saved user data');
        }
      } catch (cacheError) {
        print('Error accessing cache: $cacheError');
      }
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  // Login con username e password
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Prepara i dati per la richiesta
      final data = {
        'username': username,
        'password': password,
      };

      // Effettua la richiesta al server
      final response = await http.post(
        Uri.parse(ApiConstants.tokenUrl),
        body: data,  // Cambiato da JSON a form data per compatibilità con l'endpoint standard
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La richiesta di login è scaduta. Controlla la tua connessione.');
        },
      );

      if (response.statusCode == 200) {
        // Tenta di analizzare la risposta come JSON
        try {
          final responseData = json.decode(response.body);

          _token = responseData['access'];
          _refreshToken = responseData['refresh'];

          // Salva i token
          final prefs = await SharedPreferences.getInstance();
          prefs.setString(AppConstants.tokenKey, _token!);
          prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);

          // Estrai info dal token se presente
          extractUserFromToken();

          _isAuthenticated = true;
          _offlineMode = false;
          
          // Tenta di ottenere le informazioni dell'utente
          final user = await _fetchUserInfo();
          if (user != null) {
            _currentUser = user;
            
            // Salva le informazioni dell'utente per uso offline
            prefs.setString(AppConstants.userInfoKey, json.encode(user.toJson()));
          }

          _isLoading = false;
          notifyListeners();
          return true;
        } catch (jsonError) {
          print('Error parsing JSON response: $jsonError');
          _lastError = 'Risposta del server non valida. Il server potrebbe essere in manutenzione.';
          throw Exception(_lastError);
        }
      } else {
        // Controlla se la risposta è in HTML (errore 500 o simili)
        if (response.body.trim().startsWith('<')) {
          _lastError = 'Il server ha riscontrato un errore interno. Per favore, riprova più tardi.';
          throw Exception(_lastError);
        }
        
        // Tenta di estrarre il messaggio di errore dal JSON
        try {
          final responseData = json.decode(response.body);
          _lastError = responseData['detail'] ?? 'Errore di autenticazione';
        } catch (e) {
          _lastError = 'Errore di autenticazione. Codice: ${response.statusCode}';
        }
        
        throw Exception(_lastError);
      }
    } on SocketException {
      _lastError = 'Impossibile connettersi al server. Verifica la tua connessione internet.';
      throw Exception(_lastError);
    } on TimeoutException {
      _lastError = 'La richiesta è scaduta. Il server potrebbe essere sovraccarico o la connessione lenta.';
      throw Exception(_lastError);
    } catch (e) {
      print('Login error: $e');
      if (_lastError == null) {
        _lastError = 'Si è verificato un errore durante il login: ${e.toString()}';
      }
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Demo login (quando il server non è disponibile)
  Future<bool> demoLogin(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simula un ritardo di rete
      await Future.delayed(Duration(seconds: 1));
      
      // Credenziali demo
      if (username == 'demo' && password == 'demo') {
        // Crea un utente demo
        _currentUser = User(
          id: 999,
          username: 'demo',
          email: 'demo@example.com',
          isActive: true,
          firstName: 'Utente',
          lastName: 'Demo',
        );
        
        // Imposta token fittizio
        _token = 'demo_token';
        _refreshToken = 'demo_refresh_token';
        
        // Salva i token e le info utente
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(AppConstants.tokenKey, _token!);
        prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
        prefs.setString(AppConstants.userInfoKey, json.encode(_currentUser!.toJson()));
        
        _isAuthenticated = true;
        _offlineMode = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _lastError = 'Credenziali demo non valide. Usa "demo" come username e password.';
        throw Exception(_lastError);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Rinnova il token di accesso usando il refresh token
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;

    try {
      // Prepara i dati per la richiesta
      final data = {
        'refresh': _refreshToken,
      };

      // Effettua la richiesta al server
      final response = await http.post(
        Uri.parse(ApiConstants.tokenRefreshUrl),
        body: data,
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timeout refreshing token'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Aggiorna il token di accesso
        _token = responseData['access'];
        
        // Salva il nuovo token
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(AppConstants.tokenKey, _token!);
        
        // Verifica la validità del nuovo token
        _currentUser = await _fetchUserInfo();
        if (_currentUser == null) {
          extractUserFromToken();
        }
        
        _isAuthenticated = (_currentUser != null);
        _offlineMode = false;
        
        notifyListeners();
        return _isAuthenticated;
      }
    } catch (e) {
      print('Token refresh error: $e');
      // Se offline, continua in modalità offline
      if (_currentUser != null) {
        _offlineMode = true;
        notifyListeners();
        return true;
      }
    }
    
    // Se arriviamo qui, il refresh è fallito e non siamo in modalità offline
    await logout();
    return false;
  }

  // Logout
  Future<void> logout() async {
    // Rimuovi i token salvati
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(AppConstants.tokenKey);
    prefs.remove(AppConstants.refreshTokenKey);
    
    // Non rimuoviamo le info utente per permettere un uso offline futuro
    // prefs.remove(AppConstants.userInfoKey);
    
    // Pulisci lo stato in memoria
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    _isAuthenticated = false;
    _offlineMode = false;
    
    notifyListeners();
  }

  // Ottieni informazioni sull'utente
  Future<User?> _fetchUserInfo() async {
    if (_token == null) return null;

    try {
      print('Fetching user info from: ${ApiConstants.userProfileUrl}');
      
      final response = await http.get(
        Uri.parse(ApiConstants.userProfileUrl),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timeout fetching user info'),
      );

      print('User profile response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final userJson = json.decode(response.body);
          final user = User.fromJson(userJson);
          
          // Salva le info utente per uso offline
          final prefs = await SharedPreferences.getInstance();
          prefs.setString(AppConstants.userInfoKey, json.encode(userJson));
          
          print('Parsed user: ${user.username}, ${user.email}, ${user.fullName}');
          return user;
        } catch (jsonError) {
          print('Error parsing user JSON: $jsonError');
          return null;
        }
      } else if (response.statusCode == 401) {
        // Token non valido, tenteremo un refresh
        return null;
      } else {
        print('User profile response body: ${response.body}');
        return null;
      }
    } on SocketException {
      print('Network error fetching user info');
      _offlineMode = true;
      return null;
    } on TimeoutException {
      print('Timeout fetching user info');
      _offlineMode = true;
      return null;
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    }
  }

  // Recupera il token salvato
  Future<String?> getToken() async {
    if (_token != null) return _token;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // Recupera il refresh token salvato
  Future<String?> getRefreshToken() async {
    if (_refreshToken != null) return _refreshToken;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  // Aggiorna il profilo utente
  Future<bool> refreshUserProfile() async {
    print('Refreshing user profile...');
    try {
      final user = await _fetchUserInfo();
      if (user != null) {
        print('User profile refreshed successfully: ${user.username}');
        _currentUser = user;
        _offlineMode = false;
        notifyListeners();
        return true;
      } else {
        print('User profile refresh failed: No user data returned');
        
        // Se c'è un utente in memoria, vai in modalità offline
        if (_currentUser != null) {
          _offlineMode = true;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      print('Error refreshing user profile: $e');
      
      if (_currentUser != null) {
        _offlineMode = true;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // Estrai info utente dal token JWT
  void extractUserFromToken() {
    if (_token != null) {
      try {
        // Dividi il token nelle sue parti
        final parts = _token!.split('.');
        if (parts.length == 3) {
          // Decodifica il payload
          String normalizedPayload = parts[1];
          while (normalizedPayload.length % 4 != 0) {
            normalizedPayload += '=';
          }
          
          final payloadBytes = base64Url.decode(normalizedPayload);
          final payloadMap = json.decode(utf8.decode(payloadBytes));
          
          print('Token payload: $payloadMap');
          
          // Ottieni l'ID utente dal payload
          final userId = payloadMap['user_id'] ?? 0;
          
          // Crea un utente con un nome basato sull'ID
          _currentUser = User(
            id: userId,
            username: 'Utente $userId',
            email: 'utente$userId@esempio.it',
            isActive: true
          );
          
          _isAuthenticated = true;
          notifyListeners();
        }
      } catch (e) {
        print('Error extracting user info from token: $e');
      }
    }
  }
}