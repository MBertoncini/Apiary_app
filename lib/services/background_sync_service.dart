import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';

class BackgroundSyncService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    
    // Configura il servizio
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'sync_channel',
        initialNotificationTitle: 'Apiario Manager',
        initialNotificationContent: 'Sincronizzazione in background attiva',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    // Inizializza notifiche
    await _setupNotifications();
  }
  
  static Future<void> _setupNotifications() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sync_channel',
      'Sincronizzazione',
      description: 'Notifiche relative alla sincronizzazione dei dati',
      importance: Importance.low,
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  static void startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }
  
  static void stopService() async {
    final service = FlutterBackgroundService();
    await service.invoke('stopService');
  }
  
  static void triggerSync() async {
    final service = FlutterBackgroundService();
    await service.invoke('sync');
  }
  
  static void setInterval(int minutes) async {
    final service = FlutterBackgroundService();
    await service.invoke('setInterval', {'minutes': minutes});
  }
}

// Implementazione per iOS in background
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  // Salva che il servizio è in esecuzione
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('sync_service_running', true);
  
  return true;
}

// Implementazione principale del servizio
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Solo per debug
  debugPrint('BACKGROUND SERVICE: Started');
  
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  // Inizializza il database
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  
  // Prepara il servizio per Android
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  
  // Gestisci richieste di stop
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  
  // Configurazione dell'intervallo
  int syncIntervalMinutes = AppConstants.defaultSyncInterval;
  
  // Gestisci richieste di cambio intervallo
  service.on('setInterval').listen((event) {
    if (event != null && event.containsKey('minutes')) {
      syncIntervalMinutes = event['minutes'];
      // Salva la preferenza
      _savePreference('sync_interval_minutes', syncIntervalMinutes);
    }
  });
  
  // Gestisci richieste di sincronizzazione manuale
  service.on('sync').listen((event) async {
    await _performSync(service);
  });
  
  // Carica le preferenze salvate
  final prefs = await SharedPreferences.getInstance();
  syncIntervalMinutes = prefs.getInt('sync_interval_minutes') ?? AppConstants.defaultSyncInterval;
  
  // Avvia timer di sincronizzazione periodica
  Timer.periodic(Duration(minutes: syncIntervalMinutes), (timer) async {
    await _performSync(service);
  });
  
  // Notifica che il servizio è attivo
  await _showNotification(
    id: 888,
    title: 'Apiario Manager',
    body: 'Sincronizzazione in background attiva',
  );
}

// Helper per mostrare notifiche dal background service
Future<void> _showNotification({
  required int id,
  required String title,
  required String body,
}) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'sync_channel',
        'Sincronizzazione',
        channelDescription: 'Notifiche relative alla sincronizzazione dei dati',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
      ),
    ),
  );
}

// Esegue la sincronizzazione
Future<void> _performSync(ServiceInstance service) async {
  try {
    // Verifica se abbiamo connessione
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      await _showNotification(
        id: 889,
        title: 'Sincronizzazione non riuscita',
        body: 'Nessuna connessione internet disponibile',
      );
      return;
    }

    // Ottieni token di autenticazione
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final refreshToken = prefs.getString(AppConstants.refreshTokenKey);

    if (token == null || refreshToken == null) {
      await _showNotification(
        id: 889,
        title: 'Sincronizzazione non riuscita',
        body: 'Nessuna sessione attiva',
      );
      return;
    }

    // Notifica inizio sincronizzazione
    await _showNotification(
      id: 889,
      title: 'Sincronizzazione in corso',
      body: 'Sincronizzazione dati in background...',
    );

    // Crea API Service
    final apiService = ApiService.fromToken(token, refreshToken);

    // Ottieni ultimo timestamp sincronizzazione
    final lastSync = prefs.getString(AppConstants.lastSyncKey);

    // Sincronizza con il server
    final syncData = await apiService.syncData(lastSync: lastSync);

    // Salva i dati nella cache locale
    await _saveDataToDatabase(syncData);

    // Salva timestamp sincronizzazione
    if (syncData['timestamp'] != null) {
      await prefs.setString(AppConstants.lastSyncKey, syncData['timestamp']);
    }

    // Notifica completamento
    await _showNotification(
      id: 889,
      title: 'Sincronizzazione completata',
      body: 'Dati aggiornati correttamente',
    );
  } catch (e) {
    debugPrint('BACKGROUND SERVICE: Sync error: $e');

    // Notifica errore
    await _showNotification(
      id: 889,
      title: 'Sincronizzazione fallita',
      body: 'Si è verificato un errore: $e',
    );
  }
}

// Salva dati nel database
Future<void> _saveDataToDatabase(Map<String, dynamic> syncData) async {
  final dbHelper = DatabaseHelper();
  
  // Salva apiari
  if (syncData.containsKey('apiari')) {
    await dbHelper.batchInsertOrUpdate(dbHelper.tableApiari, syncData['apiari']);
  }
  
  // Salva arnie
  if (syncData.containsKey('arnie')) {
    await dbHelper.batchInsertOrUpdate(dbHelper.tableArnie, syncData['arnie']);
  }
  
  // Salva controlli
  if (syncData.containsKey('controlli')) {
    await dbHelper.batchInsertOrUpdate(dbHelper.tableControlli, syncData['controlli']);
  }
  
  // Salva regine
  if (syncData.containsKey('regine')) {
    await dbHelper.batchInsertOrUpdate(dbHelper.tableRegine, syncData['regine']);
  }
  
  // Salva fioriture
  if (syncData.containsKey('fioriture')) {
    await dbHelper.batchInsertOrUpdate(dbHelper.tableFioriture, syncData['fioriture']);
  }
  
  // Salva trattamenti
  if (syncData.containsKey('trattamenti')) {
    await dbHelper.batchInsertOrUpdate(dbHelper.tableTrattamenti, syncData['trattamenti']);
  }
  
  // Salva melari
  if (syncData.containsKey('melari')) {
    await dbHelper.batchInsertOrUpdate(dbHelper.tableMelari, syncData['melari']);
  }
  
  // Salva smielature
  if (syncData.containsKey('smielature')) {
    await dbHelper.batchInsertOrUpdate(dbHelper.tableSmielature, syncData['smielature']);
  }
}

// Salva preferenza
Future<void> _savePreference(String key, dynamic value) async {
  final prefs = await SharedPreferences.getInstance();
  
  if (value is int) {
    await prefs.setInt(key, value);
  } else if (value is String) {
    await prefs.setString(key, value);
  } else if (value is bool) {
    await prefs.setBool(key, value);
  } else if (value is double) {
    await prefs.setDouble(key, value);
  }
}
