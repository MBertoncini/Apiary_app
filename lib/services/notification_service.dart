import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _onNotificationClick = StreamController<String?>.broadcast();
  
  Stream<String?> get onNotificationClick => _onNotificationClick.stream;
  
  NotificationService._internal();
  
  Future<void> init() async {
    // Inizializza timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
    // Configurazione iniziale Android
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configurazione iniziale iOS
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false, // Richiederemo i permessi esplicitamente
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    // Impostazioni di inizializzazione combinate
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Inizializza il plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationClick.add(response.payload);
      },
    );
  }
  
  // Richiedi i permessi per le notifiche
  Future<bool> requestNotificationPermissions() async {
    // Permessi per Android
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return true;
    }
    
    // Permessi per iOS
    if (Platform.isIOS) {
      final settings = await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings ?? false;
    }
    
    return false;
  }
  
  // Crea canali di notifica per Android (categorie di notifiche)
  Future<void> createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Canale per controlli
      const AndroidNotificationChannel controlliChannel = AndroidNotificationChannel(
        'controlli_channel',
        'Controlli Arnie',
        description: 'Notifiche relative ai controlli delle arnie',
        importance: Importance.high,
      );
      
      // Canale per trattamenti
      const AndroidNotificationChannel trattamentiChannel = AndroidNotificationChannel(
        'trattamenti_channel',
        'Trattamenti Sanitari',
        description: 'Notifiche relative ai trattamenti sanitari',
        importance: Importance.high,
      );
      
      // Canale per sincronizzazione
      const AndroidNotificationChannel syncChannel = AndroidNotificationChannel(
        'sync_channel',
        'Sincronizzazione',
        description: 'Notifiche relative alla sincronizzazione dei dati',
        importance: Importance.low,
      );
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(controlliChannel);
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(trattamentiChannel);
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(syncChannel);
    }
  }
  
  // Mostra una notifica immediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
  }) async {
    // Specifiche per Android
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    // Specifiche per iOS
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    // Specifiche combinate
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Mostra la notifica
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
    
    // Aggiorna il badge dell'app (solo iOS)
    if (Platform.isIOS && await FlutterAppBadger.isAppBadgeSupported()) {
      await FlutterAppBadger.updateBadgeCount(1);
    }
  }
  
  // Pianifica una notifica per una data futura
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channelId = 'default_channel',
    bool allowWhileIdle = true,
  }) async {
    // Specifiche per Android
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: Importance.max,
      priority: Priority.high,
    );
    
    // Specifiche per iOS
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    
    // Specifiche combinate
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Pianifica la notifica
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: allowWhileIdle ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.exact,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
  
  // Pianifica una notifica ricorrente
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required DateTimeComponents repeats,
    required DateTime scheduledDate,
    String? payload,
    String channelId = 'default_channel',
  }) async {
    // Specifiche per Android
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: Importance.max,
      priority: Priority.high,
    );
    
    // Specifiche per iOS
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    
    // Specifiche combinate
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Pianifica la notifica ricorrente
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeats,
      payload: payload,
    );
  }
  
  // Pianifica notifica per controllo arnia
  Future<void> scheduleControlloReminder({
    required int arniaId,
    required String arniaNumero,
    required String apiarioNome,
    required DateTime scheduledDate,
  }) async {
    final id = 'controllo_$arniaId'.hashCode;
    final title = 'Controllo programmato';
    final body = 'È ora di controllare l\'arnia $arniaNumero in $apiarioNome';
    final payload = 'controllo:$arniaId';
    
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      channelId: 'controlli_channel',
    );
  }
  
  // Pianifica notifica per trattamento
  Future<void> scheduleTrattamentoReminder({
    required int trattamentoId,
    required String tipoTrattamento,
    required String apiarioNome,
    required DateTime scheduledDate,
  }) async {
    final id = 'trattamento_$trattamentoId'.hashCode;
    final title = 'Trattamento sanitario';
    final body = 'È ora di effettuare il trattamento "$tipoTrattamento" in $apiarioNome';
    final payload = 'trattamento:$trattamentoId';
    
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      channelId: 'trattamenti_channel',
    );
  }
  
  // Cancella una notifica specifica
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
  
  // Cancella tutte le notifiche
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    // Reset badge (solo iOS)
    if (Platform.isIOS && await FlutterAppBadger.isAppBadgeSupported()) {
      await FlutterAppBadger.removeBadge();
    }
  }
  
  // Cancella notifiche per una specifica categoria
  Future<void> cancelNotificationsByGroupKey(String groupKey) async {
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.cancelNotificationsByGroupKey(groupKey);
    }
  }
  
  // Chiudi il controller quando non serve più
  void dispose() {
    _onNotificationClick.close();
  }
}