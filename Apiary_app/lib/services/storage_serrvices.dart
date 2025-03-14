import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  // Salva dati di sincronizzazione
  Future<void> saveSyncData(Map<String, dynamic> syncData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Salva timestamp
    if (syncData.containsKey('timestamp')) {
      prefs.setString(AppConstants.lastSyncKey, syncData['timestamp']);
    }
    
    // Salva ogni tipo di dato
    if (syncData.containsKey('apiari')) {
      prefs.setString('apiari', json.encode(syncData['apiari']));
    }
    if (syncData.containsKey('arnie')) {
      prefs.setString('arnie', json.encode(syncData['arnie']));
    }
    if (syncData.containsKey('controlli')) {
      prefs.setString('controlli', json.encode(syncData['controlli']));
    }
    if (syncData.containsKey('regine')) {
      prefs.setString('regine', json.encode(syncData['regine']));
    }
    if (syncData.containsKey('fioriture')) {
      prefs.setString('fioriture', json.encode(syncData['fioriture']));
    }
    if (syncData.containsKey('trattamenti')) {
      prefs.setString('trattamenti', json.encode(syncData['trattamenti']));
    }
    if (syncData.containsKey('melari')) {
      prefs.setString('melari', json.encode(syncData['melari']));
    }
    if (syncData.containsKey('smielature')) {
      prefs.setString('smielature', json.encode(syncData['smielature']));
    }
  }
  
  // Ottieni timestamp ultima sincronizzazione
  Future<String?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.lastSyncKey);
  }
  
  // Ottieni dati salvati in base al tipo
  Future<List<dynamic>> getStoredData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data == null) return [];
    return json.decode(data);
  }
  
  // Pulisci tutti i dati tranne quelli di autenticazione
  Future<void> clearDataCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Salva token e dati utente
    final token = prefs.getString(AppConstants.tokenKey);
    final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    final userData = prefs.getString(AppConstants.userInfoKey);
    
    // Cancella tutto
    List<String> keysToRemove = prefs.getKeys()
        .where((key) => key != AppConstants.tokenKey &&
                        key != AppConstants.refreshTokenKey &&
                        key != AppConstants.userInfoKey)
        .toList();
    
    for (String key in keysToRemove) {
      await prefs.remove(key);
    }
    
    // Ripristina token e dati utente
    if (token != null) {
      prefs.setString(AppConstants.tokenKey, token);
    }
    if (refreshToken != null) {
      prefs.setString(AppConstants.refreshTokenKey, refreshToken);
    }
    if (userData != null) {
      prefs.setString(AppConstants.userInfoKey, userData);
    }
  }
}