// File: lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _token;
  String? _refreshToken;
  User? _currentUser;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get refreshTokenValue => _refreshToken; // Rinominato per evitare conflitti

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

      if (savedToken != null && savedRefreshToken != null) {
        // Imposta i token in memoria
        _token = savedToken;
        _refreshToken = savedRefreshToken;

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
      // Pulisci i token in caso di errore
      await logout();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login con username e password
  Future<bool> login(String username, String password) async {
    _isLoading = true;
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Dopo aver ottenuto il token in login()
        _token = responseData['access'];
        _refreshToken = responseData['refresh'];

        // Salva i token
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(AppConstants.tokenKey, _token!);
        prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);

        // Aggiungi questa riga
        extractUserFromToken();

        _isAuthenticated = true;
        _currentUser = await _fetchUserInfo();

        _isLoading = false;
        notifyListeners();
        return true;

      } else {
        // Login fallito
        final responseData = json.decode(response.body);
        throw Exception(responseData['detail'] ?? 'Errore di autenticazione');
      }
    } catch (e) {
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Registrazione nuovo utente
  Future<bool> register(String username, String email, String password, String? firstName, String? lastName) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Prepara i dati per la richiesta
      final data = {
        'username': username,
        'email': email,
        'password': password,
      };

      // Aggiungi nome e cognome se forniti
      if (firstName != null && firstName.isNotEmpty) {
        data['first_name'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        data['last_name'] = lastName;
      }

      // Effettua la richiesta al server
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        // Registrazione riuscita, effettua login
        _isLoading = false;
        notifyListeners();
        return await login(username, password);
      } else {
        // Registrazione fallita
        final responseData = json.decode(response.body);
        String errorMsg = 'Errore di registrazione';
        
        // Estrai messaggi di errore specifici
        if (responseData is Map) {
          if (responseData.containsKey('username')) {
            errorMsg = 'Username: ${responseData['username'].join(', ')}';
          } else if (responseData.containsKey('email')) {
            errorMsg = 'Email: ${responseData['email'].join(', ')}';
          } else if (responseData.containsKey('password')) {
            errorMsg = 'Password: ${responseData['password'].join(', ')}';
          }
        }
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Registration error: $e');
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
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
        
        notifyListeners();
        return _isAuthenticated;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    
    // Se arriviamo qui, il refresh è fallito
    await logout();
    return false;
  }

  // Logout
  Future<void> logout() async {
    // Rimuovi i token salvati
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(AppConstants.tokenKey);
    prefs.remove(AppConstants.refreshTokenKey);
    
    // Pulisci lo stato in memoria
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    _isAuthenticated = false;
    
    notifyListeners();
  }

  // Ottieni informazioni sull'utente
  Future<User?> _fetchUserInfo() async {
    if (_token == null) return null;

    try {
      // Il metodo ora punterà al nuovo endpoint funzionante
      final response = await http.get(
        Uri.parse(ApiConstants.userProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final userJson = json.decode(response.body);
        return User.fromJson(userJson);
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
    
    return null;
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

  // Aggiungi questo metodo in AuthService
  Future<bool> refreshUserProfile() async {
    try {
      final user = await _fetchUserInfo();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error refreshing user profile: $e');
    }
    return false;
  }
  // Aggiungi questo metodo a auth_service.dart
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
            username: 'Utente $userId', // Uso "Utente 1" invece di solo "Utente"
            email: 'utente$userId@esempio.it', // Email fittizia basata sull'ID
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