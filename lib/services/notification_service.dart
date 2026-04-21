import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

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
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
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
      
      // Canale per gruppi
      const AndroidNotificationChannel gruppiChannel = AndroidNotificationChannel(
        'gruppi_channel',
        'Gruppi',
        description: 'Notifiche relative agli inviti e ai gruppi collaborativi',
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
          ?.createNotificationChannel(gruppiChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(syncChannel);

      // Canale per smielatura e maturazione
      const AndroidNotificationChannel smielaturaChannel = AndroidNotificationChannel(
        'smielatura_channel',
        'Smielatura e Maturazione',
        description: 'Notifiche relative a smielatura e maturazione del miele',
        importance: Importance.high,
      );

      // Canale per attrezzatura e manutenzioni
      const AndroidNotificationChannel attrezzaturaChannel = AndroidNotificationChannel(
        'attrezzatura_channel',
        'Attrezzatura e Manutenzioni',
        description: 'Notifiche relative a manutenzioni programmate',
        importance: Importance.defaultImportance,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(smielaturaChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(attrezzaturaChannel);
    }
  }

  // Mostra notifica per un nuovo invito al gruppo
  Future<void> showInvitazioneGruppoNotification({
    required int invitoId,
    required String gruppoNome,
    required String invitatoDaUsername,
  }) async {
    await showNotification(
      id: 'invito_$invitoId'.hashCode,
      title: 'Nuovo invito al gruppo',
      body: '$invitatoDaUsername ti ha invitato a unirsi a "$gruppoNome"',
      payload: 'gruppi',
      channelId: 'gruppi_channel',
    );
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
    
    // TODO: Badge app iOS - flutter_app_badger rimosso perche' discontinuato.
    // Valutare alternative come app_badge_plus se necessario.
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
  
  // Pianifica notifica per rimozione trattamento (fine sospensione)
  Future<void> scheduleRimozioneTrattamentoReminder({
    required int trattamentoId,
    required String tipoTrattamento,
    required String apiarioNome,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;
    final id = 'rimozione_$trattamentoId'.hashCode;
    await scheduleNotification(
      id: id,
      title: 'Rimuovi trattamento – $apiarioNome',
      body: 'È ora di rimuovere "$tipoTrattamento". Fine periodo di sospensione.',
      scheduledDate: scheduledDate,
      payload: 'trattamento:$trattamentoId',
      channelId: 'trattamenti_channel',
    );
  }

  // Pianifica notifica per sgabbiamento regina (fine blocco covata)
  Future<void> scheduleBloccoCovataReminder({
    required int trattamentoId,
    required String apiarioNome,
    required DateTime dataFineBlocco,
  }) async {
    if (dataFineBlocco.isBefore(DateTime.now())) return;
    final id = 'blocco_covata_$trattamentoId'.hashCode;
    await scheduleNotification(
      id: id,
      title: 'Sgabbia la regina – $apiarioNome',
      body: 'Fine del blocco di covata: è il momento di sgabbiare la regina e applicare il trattamento sgocciolato.',
      scheduledDate: dataFineBlocco,
      payload: 'trattamento:$trattamentoId',
      channelId: 'trattamenti_channel',
    );
  }

  // Pianifica verifica orfanità a 7 e 25 giorni (celle reali / fecondazione)
  Future<void> scheduleOrfanitaReminders({
    required int arniaId,
    required int arniaNumero,
    required String apiarioNome,
    required DateTime dataControllo,
  }) async {
    final now = DateTime.now();

    final data7 = dataControllo.add(const Duration(days: 7));
    if (data7.isAfter(now)) {
      await scheduleNotification(
        id: 'orfanita_celle_$arniaId'.hashCode,
        title: 'Verifica celle reali – Arnia $arniaNumero',
        body: 'Controlla se le api hanno tirato celle reali in $apiarioNome (7 giorni fa hai rilevato orfanità).',
        scheduledDate: data7,
        payload: 'controllo:$arniaId',
        channelId: 'controlli_channel',
      );
    }

    final data25 = dataControllo.add(const Duration(days: 25));
    if (data25.isAfter(now)) {
      await scheduleNotification(
        id: 'orfanita_fecond_$arniaId'.hashCode,
        title: 'Verifica fecondazione – Arnia $arniaNumero',
        body: 'Controlla la presenza di uova fresche in $apiarioNome (25 giorni fa hai rilevato orfanità). Conferma l\'avvenuto volo nuziale.',
        scheduledDate: data25,
        payload: 'controllo:$arniaId',
        channelId: 'controlli_channel',
      );
    }
  }

  // Pianifica 4 avvisi settimanali per rischio sciamatura
  Future<void> scheduleSciamaturaReminders({
    required int arniaId,
    required int arniaNumero,
    required String apiarioNome,
    required DateTime dataControllo,
  }) async {
    final now = DateTime.now();
    for (int i = 1; i <= 4; i++) {
      final data = dataControllo.add(Duration(days: 7 * i));
      if (data.isAfter(now)) {
        await scheduleNotification(
          id: 'sciamatura_${arniaId}_$i'.hashCode,
          title: 'Rischio sciamatura – Arnia $arniaNumero',
          body: 'Arnia $arniaNumero in $apiarioNome: verifica presenza celle reali / a coppa. Settimana $i di monitoraggio.',
          scheduledDate: data,
          payload: 'controllo:$arniaId',
          channelId: 'controlli_channel',
        );
      }
    }
  }

  // Cancella avvisi sciamatura per un'arnia
  Future<void> cancelSciamaturaReminders(int arniaId) async {
    for (int i = 1; i <= 4; i++) {
      await cancelNotification('sciamatura_${arniaId}_$i'.hashCode);
    }
  }

  // Pianifica avviso maturazione miele (18 giorni dopo smielatura)
  Future<void> scheduleMaturazioneMieleReminder({
    required int smielaturaId,
    required String tipoMiele,
    required String apiarioNome,
    required DateTime dataSmielatura,
  }) async {
    final scheduledDate = dataSmielatura.add(const Duration(days: 18));
    if (scheduledDate.isBefore(DateTime.now())) return;
    await scheduleNotification(
      id: 'maturazione_$smielaturaId'.hashCode,
      title: 'Miele pronto per invasettamento',
      body: 'Il miele "$tipoMiele" di $apiarioNome ha riposato 18 giorni. Misura l\'umidità e schiumalo prima di invasettare.',
      scheduledDate: scheduledDate,
      payload: 'smielatura:$smielaturaId',
      channelId: 'smielatura_channel',
    );
  }

  // Pianifica avviso manutenzione (1 giorno prima della data programmata)
  Future<void> scheduleManutenzioneReminder({
    required int notificationId,
    required String attrezzaturaNome,
    required String tipoManutenzione,
    required DateTime dataProgrammata,
  }) async {
    final scheduledDate = dataProgrammata.subtract(const Duration(days: 1));
    if (scheduledDate.isBefore(DateTime.now())) return;
    await scheduleNotification(
      id: notificationId,
      title: 'Manutenzione domani – $attrezzaturaNome',
      body: 'Domani è programmata una manutenzione "$tipoManutenzione" per $attrezzaturaNome.',
      scheduledDate: scheduledDate,
      payload: 'attrezzatura',
      channelId: 'attrezzatura_channel',
    );
  }

  // Cancella una notifica specifica
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
  
  // Cancella tutte le notifiche
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    // TODO: Reset badge iOS - flutter_app_badger rimosso perche' discontinuato.
  }
  
  // Cancella notifiche per una specifica categoria
  // Nota: cancelNotificationsByGroupKey non disponibile nella versione attuale.
  // Si usa cancelAll() o cancel(id) come alternativa.
  Future<void> cancelNotificationsByGroupKey(String groupKey) async {
    // Non supportato direttamente - cancella tutte le notifiche come fallback
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // Chiudi il controller quando non serve più
  void dispose() {
    _onNotificationClick.close();
  }
}