// File: lib/constants/api_constants.dart

class ApiConstants {
  // Base URL dell'API
  static const String baseUrl = "https://cible99.pythonanywhere.com";
  
  // Endpoint API principali
  static const String apiPrefix = "/api/v1";
  
  // Endpoint autenticazione
  static const String tokenUrl = baseUrl + apiPrefix + "/token/";
  static const String tokenRefreshUrl = baseUrl + apiPrefix + "/token/refresh/";
  static const String userProfileUrl = baseUrl + apiPrefix + "/users/me/";
  
  // Endpoint apiari
  static const String apiariUrl = baseUrl + apiPrefix + '/apiari/';
  
  // Endpoint arnie
  static const String arnieUrl = baseUrl + apiPrefix + '/arnie/';
  static const String arniaDetailUrl = baseUrl + apiPrefix + '/arnia/'; // Per azioni specifiche su una singola arnia
  
  // Endpoint controlli
  static const String controlliUrl = baseUrl + apiPrefix + '/controlli/';
  static const String controlloDetailUrl = baseUrl + apiPrefix + '/controllo/';
  static const String arniaControlliUrl = baseUrl + apiPrefix + '/arnia/{arnia_id}/controllo/';
  
  // Endpoint regine
  static const String regineUrl = baseUrl + apiPrefix + '/regine/';
  static const String arniaReginaUrl = baseUrl + apiPrefix + '/arnia/{arnia_id}/regina/';
  static const String arniaReginaAggiungiUrl = baseUrl + apiPrefix + '/arnia/{arnia_id}/regina/aggiungi/';
  static const String arniaReginaSostituisciUrl = baseUrl + apiPrefix + '/arnia/{arnia_id}/regina/sostituisci/';
  static const String reginaGenealogiaUrl = baseUrl + apiPrefix + '/regina/{regina_id}/genealogia/';
  
  // Endpoint trattamenti
  static const String trattamentiUrl = baseUrl + apiPrefix + '/trattamenti/';
  static const String trattamentiAttiviUrl = baseUrl + apiPrefix + '/trattamenti/attivi/';
  static const String tipiTrattamentoUrl = baseUrl + apiPrefix + '/tipi-trattamento/';
  static const String apiarioTrattamentoUrl = baseUrl + apiPrefix + '/apiario/{apiario_id}/trattamento/nuovo/';
  static const String trattamentoStatoUrl = baseUrl + apiPrefix + '/trattamento/{trattamento_id}/stato/{nuovo_stato}/';
  
  // Endpoint melari e produzioni
  static const String melariUrl = baseUrl + apiPrefix + '/melari/';
  static const String arniaAddMelarioUrl = baseUrl + apiPrefix + '/arnia/{arnia_id}/melario/aggiungi/';
  static const String melarioRimuoviUrl = baseUrl + apiPrefix + '/melario/{melario_id}/rimuovi/';
  static const String melarioSmielaturaUrl = baseUrl + apiPrefix + '/melario/{melario_id}/smielatura/';
  static const String produzioniUrl = baseUrl + apiPrefix + '/smielature/';
  static const String apiarioSmielaturaUrl = baseUrl + apiPrefix + '/apiario/{apiario_id}/smielatura/registra/';
  static const String smielaturaDetailUrl = baseUrl + apiPrefix + '/smielatura/{smielatura_id}/';
  
  // Endpoint gruppi
  static const String gruppiUrl = baseUrl + apiPrefix + '/gruppi/';
  static const String gruppoDetailUrl = baseUrl + apiPrefix + '/gruppo/';
  static const String gruppoMembriUrl = baseUrl + apiPrefix + '/gruppi/{gruppo_id}/membri/';
  static const String gruppoInvitiUrl = baseUrl + apiPrefix + '/gruppi/{gruppo_id}/inviti/';
  static const String gruppoApiariUrl = baseUrl + apiPrefix + '/gruppi/{gruppo_id}/apiari/';
  
  // Endpoint inviti
  static const String invitiUrl = baseUrl + apiPrefix + '/inviti/';
  static const String invitiRicevutiUrl = baseUrl + apiPrefix + '/inviti/ricevuti/';
  static const String invitiAccettaUrl = baseUrl + apiPrefix + '/inviti/accetta/{token}/';
  static const String invitiRifiutaUrl = baseUrl + apiPrefix + '/inviti/rifiuta/{token}/';
  
  // Endpoint fioriture
  static const String fioritureUrl = baseUrl + apiPrefix + '/fioriture/';

  // Endpoint pagamenti
  static const String pagamentiUrl = baseUrl + apiPrefix + '/pagamenti/';
  static const String quoteUrl = baseUrl + apiPrefix + '/quote/';

  // Endpoint attrezzature
  static const String attrezzatureUrl = baseUrl + apiPrefix + '/attrezzature/';
  static const String attrezzaturaDetailUrl = baseUrl + apiPrefix + '/attrezzatura/';
  static const String speseAttrezzaturaUrl = baseUrl + apiPrefix + '/spese-attrezzatura/';
  static const String attrezzaturaSpeseUrl = baseUrl + apiPrefix + '/attrezzatura/{attrezzatura_id}/spese/';
  static const String manutenzioniUrl = baseUrl + apiPrefix + '/manutenzioni/';
  static const String attrezzaturaManutenzioniUrl = baseUrl + apiPrefix + '/attrezzatura/{attrezzatura_id}/manutenzioni/';

  // Endpoint sincronizzazione
  static const String syncUrl = baseUrl + apiPrefix + '/sync/';
  
  // Endpoint meteo
  static const String meteoUrl = baseUrl + apiPrefix + '/meteo/';
  static const String apiarioMeteoUrl = baseUrl + apiPrefix + '/apiario/{apiario_id}/meteo/';
  static const String apiarioMeteoGraficiUrl = baseUrl + apiPrefix + '/apiario/{apiario_id}/meteo/grafici/';
  
  // Utility per sostituire parametri nelle URL
  static String replaceParams(String url, Map<String, String> params) {
    String result = url;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
  
  // Timeout per le richieste in secondi
  static const int requestTimeout = 30;
}