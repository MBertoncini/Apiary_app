class AppConstants {
  // Info applicazione
  static const String appName = "Apiario Manager";
  static const String appVersion = "1.0.0";
  
  // Chiavi Storage
  static const String tokenKey = "auth_token";
  static const String refreshTokenKey = "auth_refresh_token";
  static const String userInfoKey = "user_info";
  static const String lastSyncKey = "last_sync";
  
  // Route principali
  static const String splashRoute = "/splash";
  static const String loginRoute = "/login";
  static const String registerRoute = "/register";
  static const String dashboardRoute = "/dashboard";
  static const String settingsRoute = "/settings";
  
  // Route per apiari
  static const String apiarioListRoute = "/apiari";
  static const String apiarioDetailRoute = "/apiario/detail";
  static const String apiarioCreateRoute = "/apiario/create";
  
  // Route per arnie
  static const String arniaListRoute = "/arnie";
  static const String arniaDetailRoute = "/arnia/detail";
  static const String arniaCreateRoute = "/arnia/create";
  @Deprecated('Usa arniaCreateRoute')
  static const String creaArniaRoute = arniaCreateRoute;
  static const String controlloCreateRoute = "/controllo/create";
  
  // Route per regine
  static const String reginaListRoute = "/regine";
  static const String reginaDetailRoute = "/regina/detail";
  static const String reginaCreateRoute = "/regina/create";
  
  // Route per trattamenti
  static const String trattamentiRoute = "/trattamenti";
  static const String trattamentoDetailRoute = "/trattamento/detail";
  static const String trattamentoCreateRoute = "/trattamento/create";
  @Deprecated('Usa trattamentoCreateRoute')
  static const String nuovoTrattamentoRoute = trattamentoCreateRoute;
  static const String tipiTrattamentoRoute = "/trattamenti/tipi";
  
  // Route per melari e produzioni
  static const String melariRoute = "/melari";
  static const String melarioDetailRoute = "/melario/detail";
  static const String smielaturaListRoute = "/smielature";
  static const String smielaturaCreateRoute = "/smielatura/create";
  static const String smielaturaDetailRoute = "/smielatura/detail";
  
  // Route per gestione gruppi
  static const String gruppiListRoute = "/gruppi";
  static const String gruppoDetailRoute = "/gruppo/detail";
  static const String gruppoCreateRoute = "/gruppo/create";
  static const String gruppoInvitoRoute = "/gruppo/invito";
  static const String gruppoMembriRoute = "/gruppo/membri";
  static const String gruppoApiariRoute = "/gruppo/apiari";
  
  // Route per la mappa
  static const String mappaRoute = "/mappa";
  static const String mappaApiariRoute = "/mappa/apiari";
  static const String mappaMeteoRoute = "/mappa/meteo";

  // Route per gestione pagamenti
  static const String pagamentiRoute = "/pagamenti";
  static const String pagamentoDetailRoute = "/pagamento/detail";
  static const String pagamentoCreateRoute = "/pagamento/create";
  static const String quoteRoute = "/quote";

  // Route per gestione attrezzature
  static const String attrezzatureRoute = "/attrezzature";
  static const String attrezzaturaDetailRoute = "/attrezzatura/detail";
  static const String attrezzaturaCreateRoute = "/attrezzatura/create";
  static const String spesaAttrezzaturaCreateRoute = "/spesa-attrezzatura/create";
  static const String manutenzioneCreateRoute = "/manutenzione/create";

  // Route per chat
  static const String chatRoute = "/chat";
  
  // Route per QR scanner
  static const String qrScannerRoute = "/qr_scanner";

  // Route per input vocale
  static const String voiceCommandRoute = "/voice_command";
  static const String voiceVerificationRoute = "/voice/verification";

  // Altri parametri
  static const int defaultSyncInterval = 30; // Minuti
  
  // Parametri per input vocale
  static const String wakePhrase = "ok ape"; // Frase di attivazione
  static const int maxVoiceRecordingTime = 60; // Secondi
  static const int maxBatchEntries = 20; // Numero massimo di registrazioni in batch
}