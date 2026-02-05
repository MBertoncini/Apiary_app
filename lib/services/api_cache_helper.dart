// lib/services/api_cache_helper.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiCacheHelper {
  static const String _lastSyncKey = 'last_sync';
  
  // Salva i dati nella cache locale
  static Future<void> saveToCache<T>(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (data is List) {
        // Salva come lista JSON
        await prefs.setString(key, jsonEncode(data));
      } else if (data is Map) {
        // Salva come mappa JSON
        await prefs.setString(key, jsonEncode(data));
      } else {
        // Per altri tipi, converti in stringa
        await prefs.setString(key, data.toString());
      }
      // Aggiorna timestamp ultima sincronizzazione
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Errore nel salvare i dati nella cache: $e');
    }
  }
  
  // Carica i dati dalla cache locale
  static Future<T?> loadFromCache<T>(String key, T Function(dynamic) converter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      
      if (jsonString == null) {
        return null;
      }
      
      final data = jsonDecode(jsonString);
      return converter(data);
    } catch (e) {
      debugPrint('Errore nel caricamento dei dati dalla cache: $e');
      return null;
    }
  }
  
  // Controlla se la connessione è disponibile
  static Future<bool> isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Ottiene la data dell'ultima sincronizzazione
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);
      if (lastSync == null) return null;
      return DateTime.parse(lastSync);
    } catch (e) {
      debugPrint('Errore nel recupero dell\'ultima sincronizzazione: $e');
      return null;
    }
  }
  
  // Verifica se i dati sono obsoleti (più vecchi di maxAge)
  static Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 24)}) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    
    final now = DateTime.now();
    return now.difference(lastSync) > maxAge;
  }
  
  // Implementa una strategia fetch -> cache -> offline fallback
  static Future<T> fetchWithFallback<T>({
    required Future<T> Function() fetchFromApi,
    required Future<T?> Function() loadFromCache,
    required String cacheKey,
    required T Function(dynamic) converter,
    required T defaultValue,
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      // Verifica la connessione e se la cache è obsoleta
      final bool isOnline = await isConnected();
      final bool isCacheOld = await isCacheStale(maxAge: maxAge);
      
      // Se online, prova a recuperare dall'API
      if (isOnline) {
        try {
          final data = await fetchFromApi();
          // Salva i nuovi dati nella cache
          await saveToCache(cacheKey, data);
          return data;
        } catch (apiError) {
          debugPrint('Errore API, fallback sulla cache: $apiError');
          // Se l'API fallisce, prova con la cache
          final cachedData = await loadFromCache();
          if (cachedData != null) {
            return cachedData;
          }
          // Se non c'è cache, usa il valore predefinito
          return defaultValue;
        }
      } else {
        // Se offline, prova a usare la cache
        final cachedData = await loadFromCache();
        if (cachedData != null) {
          return cachedData;
        }
        // Se non c'è cache, usa il valore predefinito
        return defaultValue;
      }
    } catch (e) {
      debugPrint('Errore generale nel fetch con fallback: $e');
      return defaultValue;
    }
  }
}