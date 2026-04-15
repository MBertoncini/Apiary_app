import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'package:flutter/foundation.dart';

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
    final timestamp = prefs.getString(AppConstants.lastSyncKey);
    
    if (timestamp != null) {
      try {
        // Assicurati che il timestamp sia in formato ISO 8601 completo
        final DateTime date = DateTime.parse(timestamp);
        return date.toUtc().toIso8601String();
      } catch (e) {
        debugPrint('Error parsing saved timestamp: $e');
      }
    }
    
    return timestamp;
  }
  
  // Ottieni dati salvati in base al tipo
  Future<List<dynamic>> getStoredData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data == null) return [];
    return json.decode(data);
  }
  
  // Pulisci tutti i dati tranne quelli di autenticazione e preferenze persistenti
  Future<void> clearDataCache() async {
    final prefs = await SharedPreferences.getInstance();

    final keysToRemove = prefs.getKeys()
        .where((key) => key != AppConstants.tokenKey &&
                        key != AppConstants.refreshTokenKey &&
                        key != AppConstants.userInfoKey &&
                        key != 'onboarding_completato' &&
                        key != _disclaimerAcceptedKey)
        .toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  // Add this method to the StorageService class
  Future<void> saveData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(data);
    await prefs.setString(key, jsonString);
  }

  // Chiave per salvare lo stato del disclaimer
  static const String _disclaimerAcceptedKey = 'disclaimer_accepted';

  // Salva se l'utente ha accettato il disclaimer
  Future<void> saveDisclaimerAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclaimerAcceptedKey, accepted);
  }

  // Verifica se l'utente ha già accettato il disclaimer
  Future<bool> hasAcceptedDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_disclaimerAcceptedKey) ?? false;
  }

  // Preferenza "Non chiedere più" per il prompt attrezzatura dopo creazione arnia
  static const String _skipAttrezzaturaPromptKey = 'skip_attrezzatura_prompt';

  Future<void> saveSkipAttrezzaturaPrompt(bool skip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipAttrezzaturaPromptKey, skip);
  }

  Future<bool> shouldSkipAttrezzaturaPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipAttrezzaturaPromptKey) ?? false;
  }

}