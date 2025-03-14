import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;
  String? _token;
  String? _refreshToken;
  bool _isLoading = false;
  
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  
  AuthService() {
    _tryAutoLogin();
  }
  
  Future<void> _tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey(AppConstants.tokenKey)) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    final extractedToken = prefs.getString(AppConstants.tokenKey);
    final extractedRefreshToken = prefs.getString(AppConstants.refreshTokenKey);
    final extractedUserData = prefs.getString(AppConstants.userInfoKey);
    
    if (extractedToken == null || extractedRefreshToken == null || extractedUserData == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _token = extractedToken;
    _refreshToken = extractedRefreshToken;
    _currentUser = User.fromJson(json.decode(extractedUserData));
    
    // Verifica se il token è valido facendo una chiamata di test
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.apiariUrl}'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      
      if (response.statusCode == 401) {
        // Token scaduto, prova a rinnovarlo
        final success = await refreshToken();
        if (!success) {
          await logout();
        }
      }
    } catch (e) {
      print('Error verifying token: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tokenUrl}'),
        body: {
          'username': username,
          'password': password,
        },
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        _token = data['access'];
        _refreshToken = data['refresh'];
        
        // Ottieni informazioni utente
        final userResponse = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/token/'),
          headers: {'Authorization': 'Bearer $_token'},
        );
        
        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          _currentUser = User.fromJson(userData);
          
          // Salva tutto in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          prefs.setString(AppConstants.tokenKey, _token!);
          prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
          prefs.setString(AppConstants.userInfoKey, json.encode(_currentUser!.toJson()));
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> refreshToken() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tokenRefreshUrl}'),
        body: {'refresh': _refreshToken},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access'];
        
        // Aggiorna il token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(AppConstants.tokenKey, _token!);
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(AppConstants.tokenKey);
    prefs.remove(AppConstants.refreshTokenKey);
    prefs.remove(AppConstants.userInfoKey);
    
    notifyListeners();
  }
}