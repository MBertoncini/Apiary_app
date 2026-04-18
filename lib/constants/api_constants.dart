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
  static const String passwordResetUrl = baseUrl + apiPrefix + "/password-reset/";
  static const String passwordResetConfirmUrl = baseUrl + apiPrefix + "/password-reset/confirm/";
  static const String googleAuthUrl = baseUrl + apiPrefix + "/auth/google/";
  
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
  // FIX #11 - Corretto gruppoDetailUrl: il router Django usa 'gruppi' (plurale), non 'gruppo'
  static const String gruppiUrl = baseUrl + apiPrefix + '/gruppi/';
  static const String gruppoDetailUrl = baseUrl + apiPrefix + '/gruppi/'; // Era '/gruppo/' - corretto a '/gruppi/'
  static const String gruppoMembriUrl = baseUrl + apiPrefix + '/gruppi/{gruppo_id}/membri/';
  static const String gruppoInvitaUrl = baseUrl + apiPrefix + '/gruppi/{gruppo_id}/invita/';
  static const String gruppoInvitiUrl = baseUrl + apiPrefix + '/gruppi/{gruppo_id}/inviti/';
  static const String gruppoApiariUrl = baseUrl + apiPrefix + '/gruppi/{gruppo_id}/apiari/';
  static const String gruppoImmagineUrl = baseUrl + apiPrefix + '/gruppi/{gruppo_id}/immagine/';
  
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

  // Endpoint invasettamenti
  static const String invasettamentiUrl = baseUrl + apiPrefix + '/invasettamenti/';

  // Endpoint cantina (maturatori e contenitori stoccaggio)
  static const String maturatoriUrl = baseUrl + apiPrefix + '/maturatori/';
  static const String contenitoriStoccaggioUrl = baseUrl + apiPrefix + '/contenitori-stoccaggio/';
  static const String preferenzeMaturazionUrl = baseUrl + apiPrefix + '/preferenze-maturazione/';
  static const String preferenzeMaturazionDefaultsUrl = baseUrl + apiPrefix + '/preferenze-maturazione/defaults/';

  // Endpoint clienti
  static const String clientiUrl = baseUrl + apiPrefix + '/clienti/';

  // Endpoint vendite
  static const String venditeUrl = baseUrl + apiPrefix + '/vendite/';

  // Endpoint analisi telaini
  static const String analisiTelainiUrl = baseUrl + apiPrefix + '/analisi-telaini/';

  // Endpoint layout mappa apiario
  static const String apiarioMapLayoutUrl = baseUrl + apiPrefix + '/apiari/{apiario_id}/map_layout/';

  // Endpoint colonie
  static const String colonieUrl = baseUrl + apiPrefix + '/colonie/';
  static const String coloniaDettaglioUrl = baseUrl + apiPrefix + '/colonie/{colonia_id}/';
  static const String coloniaControlliUrl = baseUrl + apiPrefix + '/colonie/{colonia_id}/controlli/';
  static const String coloniaReginaUrl = baseUrl + apiPrefix + '/colonie/{colonia_id}/regina/';
  static const String coloniaChiudiUrl = baseUrl + apiPrefix + '/colonie/{colonia_id}/chiudi/';
  static const String coloniaSpostaUrl = baseUrl + apiPrefix + '/colonie/{colonia_id}/sposta_contenitore/';
  // Azioni sull'arnia relative alle colonie
  static const String arniaColoniaAttivaUrl  = baseUrl + apiPrefix + '/arnie/{arnia_id}/colonia_attiva/';
  static const String arniaStoriaColonieUrl  = baseUrl + apiPrefix + '/arnie/{arnia_id}/storia_colonie/';

  // Endpoint AI
  static const String aiChatUrl = baseUrl + apiPrefix + '/ai/chat/';
  static const String aiQuotaUrl = baseUrl + apiPrefix + '/ai/quota/';
  static const String aiRequestUpgradeUrl = baseUrl + apiPrefix + '/ai/request-upgrade/';
  static const String aiActivateCodeUrl = baseUrl + apiPrefix + '/ai/activate-code/';

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