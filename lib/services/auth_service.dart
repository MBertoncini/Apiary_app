// File: lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';
import 'dart:async';
import 'auth_token_provider.dart';

// Web Client ID da google-services.json (oauth_client type 3)
const _googleServerClientId =
    '349177568966-it8t7p7d79geijhup4l3n51gkh16bc6k.apps.googleusercontent.com';

class AuthService extends ChangeNotifier implements AuthTokenProvider {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _offlineMode = false;
  String? _token;
  String? _refreshToken;
  User? _currentUser;
  String? _lastError;

  // Lock to prevent concurrent refresh attempts
  Future<bool>? _refreshFuture;

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

        // Load cached user data for immediate display
        if (savedUserInfo != null) {
          try {
            _currentUser = User.fromJson(json.decode(savedUserInfo));
          } catch (e) {
            debugPrint('Error parsing saved user info: $e');
          }
        }

        // Always validate the token by calling the server
        final userInfo = await _fetchUserInfo();
        if (userInfo != null) {
          // Token is valid
          _currentUser = userInfo;
          _isAuthenticated = true;
          _offlineMode = false;
          _isLoading = false;
          notifyListeners();
          return true;
        }

        // Token invalid — try refreshing
        final refreshed = await refreshToken();
        if (refreshed) {
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }

        // Both token and refresh failed.
        // If we have a cached user AND the failure was due to network issues
        // (offlineMode was set by _fetchUserInfo or refreshToken), allow offline access.
        if (_offlineMode && _currentUser != null) {
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }

        // Session is truly expired — force logout
        await logout();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error checking auth: $e');
      
      // Verifica se abbiamo informazioni utente salvate per la modalità offline
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedUserInfo = prefs.getString(AppConstants.userInfoKey);
        
        if (savedUserInfo != null) {
          _currentUser = User.fromJson(json.decode(savedUserInfo));
          _isAuthenticated = true;
          _offlineMode = true;
          debugPrint('Fallback to offline mode with saved user data');
        }
      } catch (cacheError) {
        debugPrint('Error accessing cache: $cacheError');
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
          final responseData = json.decode(utf8.decode(response.bodyBytes));

          _token = responseData['access'];
          _refreshToken = responseData['refresh'];

          // Salva i token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, _token!);
          await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);

          // Estrai info dal token se presente
          extractUserFromToken();

          _isAuthenticated = true;
          _offlineMode = false;
          
          // Tenta di ottenere le informazioni dell'utente
          final user = await _fetchUserInfo();
          if (user != null) {
            _currentUser = user;
            
            // Salva le informazioni dell'utente per uso offline
            await prefs.setString(AppConstants.userInfoKey, json.encode(user.toJson()));
          }

          _isLoading = false;
          notifyListeners();
          return true;
        } catch (jsonError) {
          debugPrint('Error parsing JSON response: $jsonError');
          _lastError = 'Risposta del server non valida. Il server potrebbe essere in manutenzione.';
          throw Exception(_lastError);
        }
      } else {
        // Controlla se la risposta è in HTML (errore 500 o simili)
        if (response.body.trim().startsWith('<')) {
          _lastError = 'server_error';
          throw Exception(_lastError);
        }

        // Tenta di estrarre il messaggio di errore dal JSON
        try {
          final responseData = json.decode(utf8.decode(response.bodyBytes));
          if (response.statusCode == 401) {
            // Il backend restituisce un 'code' specifico per distinguere i casi
            final code = responseData['code'];
            if (code == 'user_not_found' || code == 'wrong_password') {
              _lastError = code;
            } else {
              _lastError = 'wrong_credentials';
            }
          } else {
            final detail = responseData['detail'] ?? '';
            _lastError = detail.isNotEmpty ? detail : 'server_error';
          }
        } catch (e) {
          _lastError = 'server_error';
        }

        throw Exception(_lastError);
      }
    } on SocketException {
      _lastError = 'network_error';
      throw Exception(_lastError);
    } on TimeoutException {
      _lastError = 'timeout_error';
      throw Exception(_lastError);
    } catch (e) {
      debugPrint('Login error: $e');
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

  // Login con Google OAuth
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: _googleServerClientId,
        scopes: ['email', 'profile'],
      );

      // Forza sempre il selettore account
      await googleSignIn.signOut();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        // L'utente ha annullato
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await account.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _lastError = 'google_token_error';
        throw Exception(_lastError);
      }

      final response = await http.post(
        Uri.parse(ApiConstants.googleAuthUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Google auth response: ${response.statusCode} — ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        _token = responseData['access'];
        _refreshToken = responseData['refresh'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, _token!);
        await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);

        _isAuthenticated = true;
        _offlineMode = false;

        final user = await _fetchUserInfo();
        if (user != null) {
          _currentUser = user;
          await prefs.setString(AppConstants.userInfoKey, json.encode(user.toJson()));
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        try {
          final data = json.decode(utf8.decode(response.bodyBytes));
          _lastError = data['detail'] ?? 'google_auth_error';
        } catch (_) {
          _lastError = 'google_auth_error';
        }
        throw Exception(_lastError);
      }
    } on SocketException {
      _lastError = 'network_error';
      throw Exception(_lastError);
    } on TimeoutException {
      _lastError = 'timeout_error';
      throw Exception(_lastError);
    } catch (e) {
      debugPrint('Google login error: $e');
      _lastError ??= 'google_auth_error';
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password: invia email con link di ripristino
  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.passwordResetUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      String message;
      try {
        final data = json.decode(utf8.decode(response.bodyBytes));
        message = data['detail'] ?? data['email']?.first ?? 'Errore durante il reset della password.';
      } catch (_) {
        message = 'Errore durante il reset della password (${response.statusCode}).';
      }
      throw Exception(message);
    } on SocketException {
      throw Exception('Impossibile connettersi al server. Verifica la tua connessione internet.');
    } on TimeoutException {
      throw Exception('La richiesta è scaduta. Riprova più tardi.');
    }
  }

  // Rinnova il token di accesso usando il refresh token.
  // Uses a lock to prevent concurrent refresh attempts from racing.
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;

    // If a refresh is already in progress, share its result
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _doRefreshToken();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefreshToken() async {
    try {
      final data = {
        'refresh': _refreshToken,
      };

      final response = await http.post(
        Uri.parse(ApiConstants.tokenRefreshUrl),
        body: data,
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timeout refreshing token'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        // Aggiorna il token di accesso
        _token = responseData['access'];

        // Se il server ruota anche il refresh token, aggiornalo
        if (responseData['refresh'] != null) {
          _refreshToken = responseData['refresh'];
        }

        // Salva i nuovi token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, _token!);
        if (_refreshToken != null) {
          await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
        }

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

      // Non-200 response (e.g., refresh token expired) — fall through to logout
    } on SocketException {
      debugPrint('Token refresh: network error (offline)');
      if (_currentUser != null) {
        _offlineMode = true;
        notifyListeners();
        return true;
      }
    } on TimeoutException {
      debugPrint('Token refresh: timeout (offline)');
      if (_currentUser != null) {
        _offlineMode = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      if (_currentUser != null) {
        _offlineMode = true;
        notifyListeners();
        return true;
      }
    }

    // If we get here, the refresh truly failed (not a network issue)
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
      debugPrint('Fetching user info from: ${ApiConstants.userProfileUrl}');
      
      final response = await http.get(
        Uri.parse(ApiConstants.userProfileUrl),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timeout fetching user info'),
      );

      debugPrint('User profile response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final userJson = json.decode(utf8.decode(response.bodyBytes));
          final user = User.fromJson(userJson);
          
          // Salva le info utente per uso offline
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.userInfoKey, json.encode(userJson));

          debugPrint('Parsed user: ${user.username}, ${user.email}, ${user.fullName}');
          return user;
        } catch (jsonError) {
          debugPrint('Error parsing user JSON: $jsonError');
          return null;
        }
      } else if (response.statusCode == 401) {
        // Token non valido, tenteremo un refresh
        return null;
      } else {
        debugPrint('User profile response body: ${response.body}');
        return null;
      }
    } on SocketException {
      debugPrint('Network error fetching user info');
      _offlineMode = true;
      return null;
    } on TimeoutException {
      debugPrint('Timeout fetching user info');
      _offlineMode = true;
      return null;
    } catch (e) {
      debugPrint('Error fetching user info: $e');
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

  // Aggiorna i dati del profilo utente sul server (first_name, last_name, email, gemini_api_key)
  Future<bool> updateProfile(Map<String, String> fields) async {
    if (_token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse(ApiConstants.userProfileUrl),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode(fields),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final userJson = json.decode(utf8.decode(response.bodyBytes));
        _currentUser = User.fromJson(userJson);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userInfoKey, json.encode(userJson));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
    return false;
  }

  // Carica/aggiorna l'immagine del profilo utente
  Future<bool> uploadProfileImage(File image) async {
    if (_token == null) return false;
    try {
      final uri = Uri.parse(ApiConstants.userProfileUrl);
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Accept'] = 'application/json';
      request.files.add(await http.MultipartFile.fromPath('immagine', image.path));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final userJson = json.decode(utf8.decode(response.bodyBytes));
        _currentUser = User.fromJson(userJson);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userInfoKey, json.encode(userJson));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
    }
    return false;
  }

  // Aggiorna il profilo utente
  Future<bool> refreshUserProfile() async {
    debugPrint('Refreshing user profile...');
    try {
      final user = await _fetchUserInfo();
      if (user != null) {
        debugPrint('User profile refreshed successfully: ${user.username}');
        _currentUser = user;
        _offlineMode = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('User profile refresh failed: No user data returned');
        
        // Se c'è un utente in memoria, vai in modalità offline
        if (_currentUser != null) {
          _offlineMode = true;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error refreshing user profile: $e');
      
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
          
          debugPrint('Token payload: $payloadMap');
          
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
        debugPrint('Error extracting user info from token: $e');
      }
    }
  }
}