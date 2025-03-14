class AppConstants {
  // Info applicazione
  static const String appName = "Apiario Manager";
  static const String appVersion = "1.0.0";
  
  // Chiavi Storage
  static const String tokenKey = "auth_token";
  static const String refreshTokenKey = "auth_refresh_token";
  static const String userInfoKey = "user_info";
  static const String lastSyncKey = "last_sync";
  
  // Ruote principali
  static const String splashRoute = "/splash";
  static const String loginRoute = "/login";
  static const String registerRoute = "/register";
  static const String dashboardRoute = "/dashboard";
  static const String apiarioListRoute = "/apiari";
  static const String apiarioDetailRoute = "/apiario/detail";
  static const String apiarioCreateRoute = "/apiario/create";
  static const String arniaListRoute = "/arnie";
  static const String arniaDetailRoute = "/arnia/detail";
  static const String arniaCreateRoute = "/arnia/create";
  static const String controlloCreateRoute = "/controllo/create";
  static const String settingsRoute = "/settings";
  
  // Altri parametri
  static const int defaultSyncInterval = 30; // Minuti
}