import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/user.dart';

// Provider per lo stato di autenticazione
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  
  AuthStateNotifier(this._ref) : super(AuthState.initial()) {
    _tryAutoLogin();
  }
  
  Future<void> _tryAutoLogin() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(AppConstants.tokenKey)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      
      final extractedToken = prefs.getString(AppConstants.tokenKey);
      final extractedRefreshToken = prefs.getString(AppConstants.refreshTokenKey);
      final extractedUserData = prefs.getString(AppConstants.userInfoKey);
      
      if (extractedToken == null || extractedRefreshToken == null || extractedUserData == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      
      final user = User.fromJson(json.decode(extractedUserData));
      
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        token: extractedToken,
        refreshToken: extractedRefreshToken,
        error: null,
      );
      
      // Verifica validità token
      await _verifyToken();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> _verifyToken() async {
    try {
      final apiService = ApiService(this);
      await apiService.get(ApiConstants.apiariUrl);
    } catch (e) {
      // Token non valido, prova a rinnovarlo
      final success = await refreshToken();
      if (!success) {
        await logout();
      }
    }
  }
  
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _makePostRequest(
        '${ApiConstants.baseUrl}${ApiConstants.tokenUrl}',
        {'username': username, 'password': password},
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final token = data['access'];
        final refreshToken = data['refresh'];
        
        // Ottieni info utente
        final userResponse = await _makeGetRequest(
          ApiConstants.userProfileUrl,  // Use the correct endpoint
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          final user = User.fromJson(userData);
          
          // Salva in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          prefs.setString(AppConstants.tokenKey, token);
          prefs.setString(AppConstants.refreshTokenKey, refreshToken);
          prefs.setString(AppConstants.userInfoKey, json.encode(user.toJson()));
          
          state = AuthState(
            isAuthenticated: true,
            isLoading: false,
            user: user,
            token: token,
            refreshToken: refreshToken,
            error: null,
          );
          
          return true;
        }
      }
      
      String errorMsg = 'Login fallito';
      if (data.containsKey('detail')) {
        errorMsg = data['detail'];
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Errore di connessione: ${e.toString()}',
      );
      return false;
    }
  }
  
  Future<bool> refreshToken() async {
    try {
      if (state.refreshToken == null) {
        return false;
      }
      
      final response = await _makePostRequest(
        '${ApiConstants.baseUrl}${ApiConstants.tokenRefreshUrl}',
        {'refresh': state.refreshToken},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['access'];
        
        // Aggiorna token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(AppConstants.tokenKey, newToken);
        
        state = state.copyWith(token: newToken);
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(AppConstants.tokenKey);
    prefs.remove(AppConstants.refreshTokenKey);
    prefs.remove(AppConstants.userInfoKey);
    
    state = AuthState.initial();
  }
  
  // Helpers
  dynamic _makePostRequest(String url, Map<String, dynamic> body) async {
    final uri = Uri.parse(url);
    return await http.post(uri, body: body);
  }
  
  dynamic _makeGetRequest(String url, {Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    return await http.get(uri, headers: headers);
  }
}

// Stato di autenticazione
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? token;
  final String? refreshToken;
  final String? error;
  
  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.user,
    this.token,
    this.refreshToken,
    this.error,
  });
  
  factory AuthState.initial() {
    return AuthState(
      isAuthenticated: false,
      isLoading: false,
      user: null,
      token: null,
      refreshToken: null,
      error: null,
    );
  }
  
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? token,
    String? refreshToken,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      error: error ?? this.error,
    );
  }
}