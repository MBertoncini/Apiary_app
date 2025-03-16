// File: lib/constants/api_constants.dart
// Assicurati che il file contenga questi valori corretti:

class ApiConstants {
  // Base URL dell'API
  static const String baseUrl = "https://cible99.pythonanywhere.com";
  
  // Endpoint API principali - la correzione chiave è qui!
  static const String apiPrefix = "/api/v1";
  
  // Endpoint autenticazione
  static const String tokenUrl = baseUrl + apiPrefix + "/token/";
  static const String tokenRefreshUrl = baseUrl + apiPrefix + "/token/refresh/";
  static const String userProfileUrl = baseUrl + apiPrefix + "/users/me/";
  
  // Endpoint apiari - nota l'uso di apiPrefix qui
  static const String apiariUrl = baseUrl + apiPrefix + '/apiari/';
  
  // Endpoint arnie
  static const String arnieUrl = baseUrl + apiPrefix + '/arnie/';
  
  // Endpoint controlli
  static const String controlliUrl = baseUrl + apiPrefix + '/controlli/';
  
  // Endpoint trattamenti
  static const String trattamentiUrl = baseUrl + apiPrefix + '/trattamenti/';
  static const String tipiTrattamentoUrl = baseUrl + apiPrefix + '/tipi-trattamento/';
  
  // Endpoint melari e produzioni
  static const String melariUrl = baseUrl + apiPrefix + '/melari/';
  static const String produzioniUrl = baseUrl + apiPrefix + '/smielature/';
  
  // Endpoint regine
  static const String regineUrl = baseUrl + apiPrefix + '/regine/';
  
  // Endpoint gruppi
  static const String gruppiUrl = baseUrl + apiPrefix + '/gruppi/';
  
  // Endpoint sincronizzazione
  static const String syncUrl = baseUrl + apiPrefix + '/sync/';
  
  // Endpoint meteo
  static const String meteoUrl = baseUrl + apiPrefix + '/meteo/';
  
  // Endpoint inviti
  static const String invitiUrl = baseUrl + apiPrefix + '/inviti/';
  
  // Timeout per le richieste in secondi
  static const int requestTimeout = 30;
}