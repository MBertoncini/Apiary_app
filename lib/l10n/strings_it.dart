// lib/l10n/strings_it.dart
import 'package:flutter/material.dart';
import 'app_strings.dart';

class StringsIt extends AppStrings {
  // ── Language metadata ────────────────────────────────────────────────────
  @override String get languageName => 'Italiano';
  @override Locale get locale => const Locale('it');

  // ── Navigation / Drawer ──────────────────────────────────────────────────
  @override String get navDashboard => 'Dashboard';
  @override String get navApiari => 'Apiari';
  @override String get navArnie => 'Arnie';
  @override String get navMappaApiari => 'Mappa Apiari';
  @override String get navFioriture => 'Fioriture';
  @override String get navRegine => 'Regine';
  @override String get navTrattamentiSanitari => 'Trattamenti sanitari';
  @override String get navMelariProduzioni => 'Melari e produzioni';
  @override String get navAttrezzature => 'Attrezzature';
  @override String get navVendite => 'Vendite';
  @override String get navStatisticheAI => 'Statistiche & AI';
  @override String get navGruppi => 'Gruppi';
  @override String get navPagamenti => 'Pagamenti';
  @override String get navInserimentoVocale => 'Inserimento vocale';
  @override String get navOffriciunCaffe => 'Offrici un caffè';
  @override String get navLogout => 'Logout';
  @override String get navSettingsTooltip => 'Impostazioni';
  @override String get defaultUserName => 'Utente';

  // ── Common buttons / labels ──────────────────────────────────────────────
  @override String get btnSave => 'Salva';
  @override String get btnCancel => 'ANNULLA';
  @override String get btnConfirm => 'CONFERMA';
  @override String get btnRemove => 'Rimuovi';
  @override String get btnSaving => 'Salvataggio...';
  @override String get btnLogout => 'LOGOUT';

  // ── Settings Screen ──────────────────────────────────────────────────────
  @override String get settingsTitle => 'Impostazioni';

  // Profile section
  @override String get sectionProfile => 'Profilo';
  @override String get fieldFirstName => 'Nome';
  @override String get fieldLastName => 'Cognome';
  @override String get btnSaveName => 'Salva nome';
  @override String get btnExit => 'Esci';
  @override String get msgProfileUpdated => 'Profilo aggiornato';
  @override String get msgProfileSaveError => 'Errore nel salvataggio del profilo';

  // Language section
  @override String get sectionLanguage => 'Lingua';
  @override String get labelLanguageSubtitle => 'Seleziona la lingua dell\'app';

  // AI API Keys section
  @override String get sectionAiApiKeys => 'Chiavi API IA';
  @override String get geminiSectionLabel => 'Gemini — ApiarioAI & Inserimento Vocale';
  @override String get geminiDescription =>
      '• Senza chiave personale l\'app usa la chiave di sistema condivisa (quota condivisa).\n'
      '• Con la tua chiave ottieni quota indipendente: 20 richieste/giorno (piano gratuito Gemini 2.5 Flash).\n'
      '• Usata per: chat ApiarioAI + trascrizione vocale.\n'
      '• La chiave viene salvata sul server in modo sicuro.';
  @override String get geminiHowToGet => 'Ottienila su aistudio.google.com → "Get API key"';
  @override String get groqSectionLabel => 'Groq — Statistiche NL Query';
  @override String get groqDescription =>
      '• Usata per le query AI nelle Statistiche (domande in linguaggio naturale).\n'
      '• Senza chiave il backend usa la chiave di sistema condivisa.\n'
      '• Salvata localmente sul dispositivo.';
  @override String get groqHowToGet => 'Ottienila su console.groq.com → "API Keys"';
  @override String get btnSaveKey => 'Salva chiave';
  @override String get msgApiKeyRemoved => 'Chiave API rimossa';
  @override String get msgApiKeySaved => 'Chiave API salvata';
  @override String get msgApiKeySaveError => 'Errore nel salvataggio della chiave API';
  @override String get msgGroqKeySaved => 'Chiave Groq salvata';
  @override String get msgGroqKeyRemoved => 'Chiave Groq rimossa';

  // Voice input section
  @override String get sectionVoiceInput => 'Inserimento Vocale';
  @override String get voiceInputSubtitle => 'Scegli come vengono catturati i dati vocali.';
  @override String get voiceModeSttTitle => 'Speech-to-text (gratuito)';
  @override String get voiceModeSttSubtitle =>
      'Il microfono del dispositivo trascrive il testo; '
      'i dati vengono estratti localmente senza connessione né API. '
      'Consigliato per uso quotidiano.';
  @override String get voiceModeAudioTitle => 'Registra audio — Gemini AI (premium)';
  @override String get voiceModeAudioSubtitle =>
      'L\'audio viene analizzato da Gemini in un unico passaggio: '
      'più preciso in ambienti rumorosi e con terminologia libera. '
      'Richiede connessione.';
  @override String get voiceAudioPremiumSheetTitle => 'Funzionalità premium';
  @override String get voiceAudioPremiumSheetBody =>
      'La modalità Gemini Audio invia la registrazione a Google Gemini AI '
      'per una trascrizione e strutturazione intelligente del controllo.\n\n'
      '🎉 Durante la beta è inclusa gratuitamente per tutti gli utenti.\n\n'
      'In futuro potrebbe diventare parte di un piano a pagamento.';
  @override String get voiceAudioPremiumSheetActivate => 'Attiva';

  // AI Quota section
  @override String get sectionQuota => 'Quota AI — Uso giornaliero';
  @override String get quotaRefreshTooltip => 'Aggiorna';
  @override String get quotaDataUnavailable => 'Dati non disponibili (offline o errore di rete)';
  @override String get quotaTranscriptionsToday => 'Registrazioni audio oggi';
  @override String get quotaStatsToday => 'Query statistiche oggi';

  // Guide & Tutorial section
  @override String get sectionGuideTutorial => 'Guida & Tutorial';
  @override String get tutorialTitle => 'Tutorial';
  @override String get tutorialSubtitle => 'Rivedi il tour introduttivo';
  @override String get completeGuideTitle => 'Guida Completa';
  @override String get completeGuideSubtitle => 'Istruzioni dettagliate per tutte le funzioni';

  // Info section
  @override String get sectionInfo => 'Informazioni';
  @override String get infoAppVersion => 'Versione app';
  @override String get infoApiServer => 'Server API';
  @override String get infoDevelopedBy => 'Sviluppato da';
  @override String get infoPrivacyPolicy => 'Informativa sulla Privacy';

  // Dialogs
  @override String get clearCacheTitle => 'Cancella cache';
  @override String get clearCacheMessage =>
      'Sei sicuro di voler cancellare tutti i dati salvati localmente? '
      'Dovrai sincronizzare nuovamente.';
  @override String get msgCacheCleared => 'Cache cancellata';
  @override String get logoutConfirmTitle => 'Logout';
  @override String get logoutConfirmMessage => 'Sei sicuro di voler effettuare il logout?';

  // Quota section – detailed labels
  @override String get quotaUsingPersonalKey => 'Usando la tua chiave personale';
  @override String get quotaUsingSystemKey => 'Usando la chiave di sistema condivisa';
  @override String get quotaSystemKeyLabel => 'Chiave di sistema (condivisa)';
  @override String get quotaPersonalKeyLabel => 'Tua chiave personale';
  @override String get quotaPersonalKeyNotSetLabel => 'Tua chiave personale (non impostata)';
  @override String get quotaResetNoData => 'Reset: dati non ancora disponibili';
  @override String get quotaResetSoon => 'Reset imminente';
  @override String get quotaFreePlan => 'Piano gratuito: 20 richieste/giorno';
  @override String get quotaUsingGroqPersonal => 'Usando la tua chiave Groq personale';
  @override String get quotaResetDaily => 'Reset ogni giorno';
  @override String get quotaResetMidnight => 'Reset a mezzanotte';
  @override String get quotaApiarioAIAssistant => 'ApiarioAI Assistant (Gemini)';
  @override String get quotaVoiceInput => 'Gemini Audio (premium)';
  @override String get quotaStatsNlQuery => 'Statistiche NL Query (Groq)';
  @override String quotaResetInHoursMinutes(int hours, int minutes) =>
      'Reset tra ${hours}h ${minutes}m';
  @override String quotaResetInMinutes(int minutes) => 'Reset tra ${minutes}m';
  @override String quotaRemaining(int count) => '$count rimaste';
  @override String quotaUsedToday(int count) => '$count oggi';

  // ── Common extra buttons & labels ────────────────────────────────────────
  @override String get btnDelete => 'Elimina';
  @override String get btnDeleteCaps => 'ELIMINA';
  @override String get btnRetry => 'Riprova';
  @override String get btnEdit => 'Modifica';
  @override String get btnAdd => 'Aggiungi';
  @override String get btnReplace => 'Sostituisci';
  @override String get btnStart => 'Avvia';
  @override String get btnStop => 'Interrompi';
  @override String get btnComplete => 'Completa';
  @override String get btnSearch => 'Cerca';
  @override String get btnSend => 'Invia';
  @override String get labelLoading => 'Caricamento...';
  @override String get labelNotes => 'Note';
  @override String get labelAll => 'Tutti';
  @override String get labelPersonal => 'Personali';
  @override String get labelDate => 'Data';
  @override String get labelDateStart => 'Data inizio';
  @override String get labelDateEnd => 'Data fine';
  @override String get labelDateEndOpt => 'Data fine (opzionale)';
  @override String get labelApiario => 'Apiario';
  @override String get labelArnia => 'Arnia';
  @override String get labelActive => 'Attiva';
  @override String get labelInactive => 'Inattiva';
  @override String get labelOptional => '(opzionale)';
  @override String get labelNa => 'N/D';
  @override String get labelYes => 'Sì';
  @override String get labelNo => 'No';
  @override String get msgErrorLoading => 'Errore durante il caricamento dei dati';
  @override String msgErrorGeneric(String e) => 'Errore: $e';
  @override String get msgOfflineMode => 'Modalità offline — dati aggiornati all\'ultimo accesso';
  @override String get dialogConfirmDeleteTitle => 'Conferma eliminazione';
  @override String get dialogConfirmDeleteBtn => 'ELIMINA';
  @override String get dialogCancelBtn => 'ANNULLA';

  // ── Apiario screens ───────────────────────────────────────────────────────
  @override String get apiarioListTitle => 'I tuoi apiari';
  @override String get apiarioSearchHint => 'Cerca per nome o posizione...';
  @override String apiarioNotFoundForQuery(String q) => 'Nessun apiario trovato con "$q"';
  @override String get apiarioFabTooltip => 'Aggiungi apiario';
  @override String get apiarioBadgeMap => 'Mappa';
  @override String get apiarioBadgeMeteo => 'Meteo';
  @override String get apiarioBadgeShared => 'Condiviso';
  @override String get apiarioDetailLoading => 'Caricamento...';
  @override String get apiarioDetailTooltipEdit => 'Modifica apiario';
  @override String get apiarioDetailTooltipDelete => 'Elimina apiario';
  @override String get apiarioDetailTooltipQr => 'QR Code';
  @override String get apiarioDetailTooltipInfo => 'Informazioni apiario';
  @override String get apiarioDetailTooltipAddArnia => 'Aggiungi arnia';
  @override String get apiarioDetailDeleteTitle => 'Elimina Apiario';
  @override String get apiarioDetailDeletedOk => 'Apiario eliminato con successo';
  @override String apiarioDetailDeleteError(String e) => 'Errore durante l\'eliminazione: $e';
  @override String get apiarioDetailNoPdfArnie => 'Nessuna arnia disponibile per la stampa';
  @override String apiarioDetailPdfError(String e) => 'Errore durante la generazione del PDF: $e';
  @override String get apiarioDetailNoMeteo => 'Monitoraggio meteo non attivato';
  @override String get apiarioDetailActivateMeteo => 'Attiva monitoraggio meteo';
  @override String get apiarioDetailNoCoords => 'Coordinate non impostate per questo apiario';
  @override String get apiarioDetailSetCoords => 'Imposta coordinate';
  @override String get apiarioDetailLblTrattamenti => 'Trattamenti';
  @override String get apiarioDetailNoTrattamenti => 'Nessun trattamento sanitario registrato';
  @override String get apiarioDetailAddTrattamento => 'Aggiungi trattamento';
  @override String get apiarioDetailNewTrattamento => 'Nuovo trattamento';
  @override String get apiarioDetailBtnDettagli => 'Dettagli';
  @override String get apiarioDetailLblNote => 'Note';
  @override String get apiarioDetailLblStatistiche => 'Statistiche';
  @override String get apiarioDetailErrorLoad => 'Errore durante il caricamento dei dati';
  @override String apiarioDetailDeleteMsg(String nome) =>
      'Sei sicuro di voler eliminare "$nome"?\n\nVerranno eliminate anche tutte le arnie, controlli, trattamenti e dati associati.';
  @override String get apiarioTabMeteo => 'Meteo';
  @override String get trattamentoStatusAnnullato => 'Annullato';
  @override String get apiarioDetailInfoPos => 'Posizione';
  @override String get apiarioDetailInfoCoord => 'Coordinate';
  @override String get apiarioDetailInfoMeteoOn => 'Attivo';
  @override String get apiarioDetailInfoMeteoOff => 'Disattivato';
  @override String get apiarioDetailInfoVis => 'Visibilità mappa';
  @override String get apiarioDetailInfoSharing => 'Condivisione gruppi';
  @override String get apiarioDetailInfoShared => 'Condiviso con il gruppo';
  @override String get apiarioDetailInfoNotShared => 'Non condiviso';
  @override String get apiarioFormTitleNew => 'Nuovo apiario';
  @override String get apiarioFormTitleEdit => 'Modifica apiario';
  @override String get apiarioFormLblName => 'Nome apiario';
  @override String get apiarioFormHintName => 'Es. Apiario montagna';
  @override String get apiarioFormLblSearchAddr => 'Cerca indirizzo';
  @override String get apiarioFormHintSearchAddr => 'Es. Via Roma 1, Milano';
  @override String get apiarioFormTooltipSearch => 'Cerca';
  @override String get apiarioFormBtnUsePos => 'Usa posizione attuale';
  @override String get apiarioFormLblLat => 'Latitudine';
  @override String get apiarioFormLblLon => 'Longitudine';
  @override String get apiarioFormVisibOwner => 'Solo proprietario';
  @override String get apiarioFormVisibGroup => 'Membri del gruppo';
  @override String get apiarioFormVisibAll => 'Tutti gli utenti';
  @override String get apiarioFormVisibAllPrivacyNote =>
      'La posizione esatta non verrà mostrata: sulla mappa verrà indicata solo un\'area approssimativa (~500 m). '
      'Questo ti permette di condividere la zona senza rischiare furti, e aiuta altri apicoltori a scoprire dove è già presente attività apistica.';
  @override String get mapaApproxAreaLabel => 'Posizione approssimata';
  @override String get apiarioFormMeteoTitle => 'Monitoraggio meteo';
  @override String get apiarioFormMeteoSubtitle => 'Attiva il monitoraggio delle condizioni meteo';
  @override String get apiarioFormShareTitle => 'Condivisione con gruppo';
  @override String get apiarioFormShareSubtitle => 'Condividi questo apiario con un gruppo';
  @override String get apiarioFormLblGroup => 'Seleziona gruppo';
  @override String get apiarioFormLblNotes => 'Note';
  @override String get apiarioFormHintNotes => 'Inserisci eventuali note su questo apiario...';
  @override String get apiarioFormSectionGeneral => 'Informazioni generali';
  @override String get apiarioFormSectionPos => 'Posizione sulla mappa';
  @override String get apiarioFormSectionVisib => 'Visibilità sulla mappa';
  @override String get apiarioFormSectionFeatures => 'Funzionalità aggiuntive';
  @override String get apiarioFormValidateName => 'Inserisci il nome dell\'apiario';
  @override String get apiarioFormValidateLon => 'Inserisci anche la longitudine';
  @override String get apiarioFormValidateLat => 'Inserisci anche la latitudine';
  @override String get apiarioFormValidateFormat => 'Formato non valido';
  @override String get apiarioFormValidateGroup => 'Seleziona un gruppo';
  @override String get apiarioFormMapHint =>
      'Cerca un indirizzo per navigare sulla mappa, poi tocca il punto esatto.';
  @override String get apiarioFormNoGruppi =>
      'Non fai parte di nessun gruppo. Crea o unisciti a un gruppo per condividere.';
  @override String get apiarioFormBtnCreate => 'CREA APIARIO';
  @override String get apiarioFormBtnUpdate => 'AGGIORNA APIARIO';
  @override String get apiarioCreatedOk => 'Apiario creato con successo';
  @override String get apiarioUpdatedOk => 'Apiario aggiornato con successo';
  @override String get apiarioPermDenied => 'Permessi di localizzazione negati';
  @override String get apiarioPermDeniedPermanent => 'Permessi negati permanentemente. Attivali dalle impostazioni.';
  @override String get apiarioErrorPos => 'Errore nel recupero della posizione';
  @override String get apiarioErrorAddr => 'Errore nella ricerca dell\'indirizzo';

  // ── Arnia screens ─────────────────────────────────────────────────────────
  @override String get arniaListTitle => 'Le mie Arnie';
  @override String get arniaFabTooltip => 'Aggiungi arnia';
  @override String get arniaEmptyTitle => 'Nessuna arnia trovata';
  @override String get arniaEmptySubtitle => 'Non hai ancora creato arnie o non è stato possibile caricarle';
  @override String get arniaBtnCreate => 'Crea arnia';
  @override String get arniaBtnRetry => 'Riprova a caricare';
  @override String arniaItemTitle(int num) => 'Arnia $num';
  @override String get arniaStatusActive => 'Attiva';
  @override String get arniaStatusInactive => 'Inattiva';
  @override String get arniaNoControllo => 'Nessun controllo registrato';
  @override String arniaControlloDate(String d) => 'Controllo: $d';
  @override String get arniaChipProblemi => 'Problemi';
  @override String get arniaChipSciamatura => 'Sciamatura';
  @override String arniaActiveCount(int active, int total) => '$active/$total attive';
  @override String get arniaCatAltri => 'Altri';
  @override String get arniaCatNuclei => 'Nuclei';
  @override String get arniaCatSpeciali => 'Speciali';
  @override String get arniaDetailNotFound => 'Arnia non trovata';
  @override String get arniaDetailErrorLoad => 'Errore durante il caricamento dei dati';
  @override String arniaDetailTitle(int num) => 'Arnia $num';
  @override String get arniaDetailTooltipType => 'Cambia tipo scatola';
  @override String get arniaDetailTooltipEdit => 'Modifica arnia';
  @override String get arniaDetailTooltipDelete => 'Elimina arnia';
  @override String get arniaDetailTooltipQr => 'Genera QR Code';
  @override String get arniaDetailTooltipInfo => 'Informazioni arnia';
  @override String get arniaDetailDeleteTitle => 'Elimina Arnia';
  @override String get arniaDetailDeletedOk => 'Arnia eliminata con successo';
  @override String arniaDetailDeleteError(String e) => 'Errore durante l\'eliminazione: $e';
  @override String get arniaDetailDeleteControlloTitle => 'Elimina Controllo';
  @override String get arniaDetailControlloDeletedOk => 'Controllo eliminato con successo';
  @override String arniaDetailControlloDeleteError(String e) => 'Errore durante l\'eliminazione: $e';
  @override String get arniaDetailReplaceReginaTitle => 'Sostituisci Regina';
  @override String get arniaDetailReplaceReginaBtn => 'CONFERMA SOSTITUZIONE';
  @override String get arniaDetailChangeTypeTitle => 'Cambia tipo scatola';
  @override String arniaDetailTypeUpdated(String tipo) => 'Tipo aggiornato: $tipo';
  @override String arniaDetailTypeError(String e) => 'Errore aggiornamento tipo: $e';
  @override String get arniaDetailBtnRegControllo => 'Registra controllo';
  @override String get arniaDetailBtnAddRegina => 'Aggiungi regina';
  @override String get arniaDetailBtnEditRegina => 'Modifica';
  @override String get arniaDetailBtnReplaceRegina => 'Sostituisci';
  @override String get arniaDetailBtnAvviaAnalisi => 'Avvia Analisi';
  @override String get arniaDetailTooltipEditControllo => 'Modifica controllo';
  @override String get arniaDetailTooltipDeleteControllo => 'Elimina controllo';
  @override String get arniaDetailLblMotivo => 'Motivo';
  @override String get arniaDetailLblDataRimozione => 'Data rimozione';
  @override String get arniaDetailLblGenealogia => 'Genealogia';
  @override String get arniaDetailRegistraControllo => 'Registra Controllo';
  @override String get arniaDetailBtnModifica => 'Modifica';
  @override String get arniaDetailBtnSostituisci => 'Sostituisci';
  @override String arniaDetailError(String e) => 'Errore: $e';
  // Tab labels
  @override String get arniaTabControlli => 'Controlli';
  @override String get arniaTabRegina => 'Regina';
  @override String get arniaTabAnalisi => 'Analisi';
  // Controlli tab content
  @override String get arniaDetailNoControlli => 'Nessun controllo registrato';
  @override String arniaDetailControlloTitle(String date) => 'Controllo del $date';
  @override String arniaDetailControlloBy(String user) => 'Effettuato da $user';
  @override String arniaDetailScorte(int n) => 'Scorte: $n';
  @override String arniaDetailCovata(int n) => 'Covata: $n';
  @override String get arniaDetailReginaPresente => 'Regina presente';
  @override String get arniaDetailReginaAssente => 'Regina assente';
  @override String get arniaDetailReginaVista => 'Regina vista';
  @override String get arniaDetailUovaFresche => 'Uova fresche';
  @override String arniaDetailCelleReali(int n) => 'Celle reali: $n';
  @override String get arniaDetailProblemiSanitari => 'Problemi sanitari';
  // Regina tab content
  @override String get arniaDetailNoRegina => 'Nessuna regina registrata';
  @override String get arniaDetailReginaIncompleta => 'Scheda regina incompleta';
  @override String get arniaDetailReginaAutoMsg =>
      'Regina rilevata automaticamente. Tocca per completare razza, origine e altri dettagli.';
  @override String arniaDetailIntrodottaIl(String date) => 'Introdotta il $date';
  @override String get arniaDetailSectionGeneral => 'Informazioni generali';
  @override String get arniaDetailLblDataNascita => 'Data di nascita';
  @override String get arniaDetailLblValutazioni => 'Valutazioni';
  @override String get arniaDetailRatingDocilita => 'Docilità';
  @override String get arniaDetailRatingProduttivita => 'Produttività';
  @override String get arniaDetailRatingResistenza => 'Resistenza malattie';
  @override String get arniaDetailRatingTendenzaSciamatura => 'Tendenza sciamatura';
  @override String get arniaDetailLblMadre => 'Madre';
  @override String get arniaDetailReginaFondatrice => 'Regina fondatrice';
  @override String get arniaDetailLblFiglie => 'Figlie';
  @override String get arniaDetailLblStoria => 'Storia nell\'arnia';
  @override String get arniaDetailStoriaCorrente => 'in corso';
  // Origine regina
  @override String get arniaDetailOrigineAcquistata => 'Acquistata';
  @override String get arniaDetailOrigineAllevata => 'Allevata';
  @override String get arniaDetailOrigineSciamatura => 'Sciamatura naturale';
  @override String get arniaDetailOrigineEmergenza => 'Celle di emergenza';
  @override String get arniaDetailOrigineSconosciuta => 'Sconosciuta';
  // Analisi tab content
  @override String get arniaDetailNoAnalisi => 'Nessuna analisi registrata';
  @override String get arniaDetailBtnAnalisiTelaino => 'Analisi Telaino';
  @override String arniaDetailAnalisiTagApi(int n) => 'Api: $n';
  @override String arniaDetailAnalisiTagRegine(int n) => 'Regine: $n';
  @override String arniaDetailAnalisiTagFuchi(int n) => 'Fuchi: $n';
  @override String arniaDetailAnalisiTagCelleReali(int n) => 'Celle R.: $n';
  // Info sheet
  @override String get arniaDetailInfoInstallata => 'Installata il';
  @override String get arniaDetailInfoTipo => 'Tipo';
  @override String get arniaDetailInfoColore => 'Colore';
  @override String get arniaDetailInfoNonSpecificata => 'Non specificata';
  // Replace regina dialog
  @override String get arniaDetailReplaceReginaMsg =>
      'La regina attuale verrà rimossa. Potrai subito aggiungerne una nuova.';
  @override String get arniaDetailChangeMotivoSostituzione => 'Sostituzione programmata';
  @override String get arniaDetailChangeMotivoMorte => 'Morte naturale';
  @override String get arniaDetailChangeMotivoSciamatura => 'Sciamatura';
  @override String get arniaDetailChangeMotivoProblemaSanitario => 'Problema sanitario';
  @override String get arniaDetailChangeMotivoAltro => 'Altro';
  // Cambio tipo sheet
  @override String get arniaDetailChangeTypeMsg =>
      'La famiglia rimane invariata — cambia solo il modello della cassetta.';
  // Delete confirm dialogs
  @override String arniaDetailDeleteMsg(String num) =>
      'Sei sicuro di voler eliminare "Arnia $num"?\n\n'
      'Verranno eliminati anche tutti i controlli, la regina e i melari associati.';
  @override String arniaDetailDeleteControlloMsg(String date) =>
      'Sei sicuro di voler eliminare il controllo del $date?';
  @override String get arniaFormTitleNew => 'Nuova Arnia';
  @override String get arniaFormTitleEdit => 'Modifica Arnia';
  @override String get arniaFormLblApiario => 'Apiario';
  @override String get arniaFormHintApiario => 'Seleziona l\'apiario';
  @override String get arniaFormLblNumero => 'Numero arnia';
  @override String get arniaFormHintNumero => 'Inserisci il numero dell\'arnia';
  @override String get arniaFormLblColore => 'Colore arnia';
  @override String get arniaFormLblDataInstall => 'Data installazione';
  @override String get arniaFormActiveTitle => 'Arnia attiva';
  @override String get arniaFormLblNotes => 'Note';
  @override String get arniaFormHintNotes => 'Inserisci eventuali note (opzionale)';
  @override String get arniaFormLblTipoArnia => 'Tipo arnia';
  @override String get arniaFormBtnCreate => 'CREA ARNIA';
  @override String get arniaFormBtnUpdate => 'AGGIORNA ARNIA';
  @override String get arniaFormValidateApiario => 'Seleziona un apiario';
  @override String get arniaFormValidateNumero => 'Inserisci un numero';
  @override String get arniaFormValidateNumeroFormat => 'Inserisci un numero valido';
  @override String arniaFormValidateNumeroUsato(int n) => 'Il numero $n è già usato in questo apiario';
  @override String get arniaCreatedOk => 'Arnia creata con successo';
  @override String get arniaUpdatedOk => 'Arnia aggiornata con successo';
  @override String get arniaLoadApiariError => 'Errore nel caricare gli apiari';
  @override String arniaFormError(String e) => 'Errore: $e';

  // ── Trattamento screens ───────────────────────────────────────────────────
  @override String get trattamentiTitle => 'Trattamenti Sanitari';
  @override String get trattamentiNoData => 'Nessun trattamento sanitario trovato';
  @override String get trattamentiBtnNew => 'Nuovo trattamento';
  @override String trattamentiInizio(String d) => 'Inizio: $d';
  @override String trattamentiFine(String d) => 'Fine: $d';
  @override String trattamentiFineSOSP(String d) => 'Fine sospensione: $d';
  @override String trattamentiNote(String n) => 'Note: $n';
  @override String get trattamentiBtnAvvia => 'Avvia';
  @override String get trattamentiBtnAnnullaStatus => 'Annulla';
  @override String get trattamentiBtnCompleta => 'Completa';
  @override String get trattamentiBtnInterrompi => 'Interrompi';
  @override String get trattamentiDeleteTitle => 'Elimina Trattamento';
  @override String get trattamentiDeletedOk => 'Trattamento eliminato con successo';
  @override String trattamentiDeleteError(String e) => 'Errore durante l\'eliminazione: $e';
  @override String trattamentiError(String e) => 'Errore: $e';
  @override String get trattamentiTabAttivi => 'Attivi';
  @override String get trattamentiTabCompletati => 'Completati';
  @override String get trattamentiNoAttivi => 'Nessun trattamento attivo';
  @override String get trattamentiNoCompletati => 'Nessun trattamento completato';
  @override String trattamentiDeleteMsg(String nome) =>
      'Sei sicuro di voler eliminare il trattamento "$nome"?';
  @override String trattamentiArnieSelezionate(int n) => 'Arnie: $n selezionate';
  @override String get trattamentiMetodoStrisce => 'Strisce';
  @override String get trattamentiMetodoGocciolato => 'Gocciolato';
  @override String get trattamentiMetodoSublimato => 'Sublimato';
  @override String get trattamentoDetailTitle => 'Dettaglio Trattamento';
  @override String get trattamentoDetailDeleteTitle => 'Conferma eliminazione';
  @override String get trattamentoDetailDeleteMsg => 'Sei sicuro di voler eliminare questo trattamento?';
  @override String get trattamentoDetailTooltipEdit => 'Modifica';
  @override String get trattamentoDetailTooltipDelete => 'Elimina';
  @override String get trattamentoDetailDeletedOk => 'Trattamento eliminato';
  @override String trattamentoDetailDeleteError(String e) => 'Errore eliminazione: $e';
  @override String trattamentoDetailArniaLabel(String id) => 'Arnia $id';
  @override String get trattamentoDetailApplicatoTutto => 'Applicato a tutto l\'apiario';
  @override String get trattamentoDetailLblCaricamento => 'Caricamento trattamento...';
  @override String get trattamentoDetailSectionDettagli => 'Dettagli trattamento';
  @override String get trattamentoDetailLblMetodo => 'Metodo di applicazione';
  @override String get trattamentoDetailLblDataInizio => 'Data inizio';
  @override String get trattamentoDetailLblDataFine => 'Data fine';
  @override String get trattamentoDetailLblSospFino => 'Sospensione fino al';
  @override String get trattamentoDetailLblArnieTrattate => 'Arnie trattate';
  @override String get trattamentoDetailLblBloccoCovata => 'Blocco di covata';
  @override String get trattamentoDetailLblInizioBlocko => 'Inizio blocco';
  @override String get trattamentoDetailLblFineBlocko => 'Fine blocco';
  @override String get trattamentoDetailLblMetodoBlocko => 'Metodo';
  @override String get trattamentoDetailLblNoteBlocko => 'Note blocco';
  @override String get trattamentoFormOfflineMsg => 'Modalità offline — dati aggiornati all\'ultimo accesso';
  @override String get trattamentoFormNewProductTitle => 'Nuovo prodotto';
  @override String get trattamentoFormLblProductName => 'Nome prodotto *';
  @override String get trattamentoFormHintProductName => 'Es. Acido ossalico, ApiLife VAR...';
  @override String get trattamentoFormLblPrincipioAttivo => 'Principio attivo *';
  @override String get trattamentoFormHintPrincipioAttivo => 'Es. Acido ossalico, Timolo, Flumetrina...';
  @override String get trattamentoFormLblGiorniSosp => 'Giorni di sospensione';
  @override String get trattamentoFormHintGiorniSosp => '0 = nessuna sospensione';
  @override String get trattamentoFormLblDescrizione => 'Descrizione (opzionale)';
  @override String get trattamentoFormBloccoCovataReq => 'Richiede blocco covata';
  @override String get trattamentoFormLblDurataBlockco => 'Durata consigliata blocco';
  @override String get trattamentoFormLblNote => 'Note';
  @override String get trattamentoFormHintNote => 'Inserisci eventuali note (opzionale)';
  @override String get trattamentoFormApplicaTutto => 'Tutto l\'apiario';
  @override String get trattamentoFormApplicaSpecifiche => 'Arnie specifiche';
  @override String get trattamentoFormSelectPrimaApiario => 'Seleziona prima un apiario';
  @override String get trattamentoFormNoArnie => 'Nessuna arnia trovata in questo apiario';
  @override String get trattamentoFormLblProdotto => 'Prodotto / Tipo trattamento';
  @override String get trattamentoFormDataInizio => 'Data inizio';
  @override String get trattamentoFormDataFine => 'Data fine (opzionale)';
  @override String get trattamentoFormBloccoCovataActive => 'Blocco covata attivo';
  @override String get trattamentoFormCreatedOk => 'Trattamento creato';
  @override String get trattamentoFormUpdatedOk => 'Trattamento aggiornato';
  @override String trattamentoFormNewProductError(String e) => 'Errore creazione prodotto: $e';
  @override String get trattamentoFormSelectApiarioMsg => 'Seleziona un apiario';
  @override String get trattamentoFormSelectTypeMsg => 'Seleziona un tipo di trattamento';
  @override String get trattamentoFormSelectArnieMsg => 'Seleziona almeno un\'arnia';
  @override String trattamentoFormError(String e) => 'Errore: $e';
  @override String get trattamentoFormTitleNew => 'Nuovo Trattamento';
  @override String get trattamentoFormTitleEdit => 'Modifica Trattamento';
  @override String get trattamentoFormBtnCreate => 'CREA TRATTAMENTO';
  @override String get trattamentoFormBtnUpdate => 'AGGIORNA TRATTAMENTO';
  @override String get trattamentoFormBtnCreateProduct => 'Crea';
  @override String get trattamentoFormLblApplica => 'Applica a';
  @override String get trattamentoFormHintProdotto => 'Seleziona un prodotto';
  @override String get trattamentoFormValidateCampoObbligatorio => 'Campo obbligatorio';
  @override String get trattamentoFormValidateNumeroGe0 => 'Inserisci un numero intero ≥ 0';
  @override String get trattamentoFormValidateNumeroGt0 => 'Inserisci un numero intero > 0';
  @override String get trattamentoFormLblDataInizioBlocco => 'Data inizio blocco';
  @override String get trattamentoFormLblDataFineBlocco => 'Data fine blocco';
  @override String get trattamentoFormErrFirstDateBlocco => 'Imposta prima la data di inizio blocco';
  @override String get trattamentoFormLblMetodoBlocco => 'Metodo di blocco';
  @override String get trattamentoFormHintMetodoBlocco => 'Es. ingabbiamento regina, rimozione regina...';
  @override String get trattamentoFormHintNoteBlocco => 'Dettagli aggiuntivi (opzionale)';
  @override String get trattamentoFormLblMetodoApplicazione => 'Metodo di applicazione';
  @override String get trattamentoFormLblNoteBloccoCovata => 'Note blocco covata';

  // ── Fioritura screens ─────────────────────────────────────────────────────
  @override String get fiorituraListTitle => 'Fioriture';
  @override String get fiorituraTabMie => 'Le mie';
  @override String get fiorituraTabCommunity => 'Community';
  @override String get fiorituraFabTooltip => 'Aggiungi fioritura';
  @override String get fiorituraSearchHint => 'Cerca per pianta o apiario...';
  @override String get fiorituraListNoData => 'Nessuna fioritura trovata';
  @override String get fiorituraListLoadError => 'Errore nel caricamento delle fioriture';
  @override String fiorituraListDeleteMsg(String name) => 'Vuoi eliminare la fioritura "$name"?';
  @override String get fiorituraDeleteTitle => 'Elimina fioritura';
  @override String get fiorituraDeletedOk => 'Fioritura eliminata';
  @override String fiorituraDeleteError(String e) => 'Errore eliminazione: $e';
  @override String get fiorituraMenuEdit => 'Modifica';
  @override String get fiorituraMenuDelete => 'Elimina';
  @override String get fiorituraCardAttiva => 'Attiva';
  @override String get fiorituraCardNonAttiva => 'Non attiva';
  @override String get fiorituraCardPubblica => 'Pubblica';
  @override String fiorituraCardConferme(int n) => '$n conferme';
  @override String get fiorituraCardTu => 'Tu';
  @override String fiorituraDateFrom(String date) => 'Dal $date';
  @override String get fiorituraDetailTitle => 'Fioritura';
  @override String get fiorituraDetailNotFound => 'Fioritura non trovata';
  @override String get fiorituraDetailTooltipEdit => 'Modifica';
  @override String get fiorituraDetailConfirmOk => 'Conferma registrata!';
  @override String get fiorituraDetailLblCommunity => 'Community';
  @override String get fiorituraDetailLblIntensity => 'La tua valutazione di intensità:';
  @override String get fiorituraDetailBtnRemove => 'Rimuovi';
  @override String get fiorituraDetailLblPosizione => 'Posizione';
  @override String fiorituraDetailError(String e) => 'Errore: $e';
  @override String get fiorituraDetailLblPeriodo => 'Periodo';
  @override String get fiorituraDetailLblRaggio => 'Raggio';
  @override String get fiorituraDetailLblTipoPianta => 'Tipo pianta';
  @override String get fiorituraDetailLblIntensitaStimata => 'Intensità stimata';
  @override String get fiorituraDetailLblVisibilita => 'Visibilità';
  @override String get fiorituraDetailValPubblica => 'Pubblica (community)';
  @override String get fiorituraDetailValPrivata => 'Privata';
  @override String get fiorituraDetailLblSegnalata => 'Segnalata da';
  @override String get fiorituraDetailStatConfermanti => 'confermanti';
  @override String get fiorituraDetailStatIntensita => 'intensità media';
  @override String get fiorituraDetailConfermata => 'Hai confermato questa fioritura';
  @override String get fiorituraDetailConfermaQuestion => 'Hai visto questa fioritura?';
  @override String get fiorituraDetailHintNota => 'Nota (opzionale)';
  @override String get fiorituraDetailBtnAggiorna => 'Aggiorna conferma';
  @override String get fiorituraDetailBtnConferma => 'Conferma avvistamento';
  @override String get fiorituraFormTitleNew => 'Nuova fioritura';
  @override String get fiorituraFormTitleEdit => 'Modifica fioritura';
  @override String get fiorituraFormTooltipSave => 'Salva';
  @override String get fiorituraFormLblPianta => 'Pianta *';
  @override String get fiorituraFormLblTipoPianta => 'Tipo di pianta';
  @override String get fiorituraFormLblDataInizio => 'Data inizio *';
  @override String get fiorituraFormLblDataFine => 'Data fine';
  @override String get fiorituraFormLblRaggio => 'Raggio (metri)';
  @override String get fiorituraFormLblIntensita => 'Intensità fioritura';
  @override String get fiorituraFormLblNote => 'Note';
  @override String get fiorituraFormVisibilitaTitle => 'Visibile alla community';
  @override String get fiorituraFormBtnUsePos => 'Usa la mia posizione attuale';
  @override String get fiorituraFormHintNonSpecificato => 'Non specificato';
  @override String get fiorituraFormHintNonValutata => 'Non valutata';
  @override String get fiorituraFormErrDataInizio => 'Inserisci la data di inizio';
  @override String get fiorituraFormErrPosition => 'Seleziona la posizione sulla mappa';
  @override String fiorituraFormError(String e) => 'Errore: $e';
  @override String get fiorituraFormVisibilitaSubtitle => 'Condividi questa fioritura con tutti gli apicoltori';
  @override String get fiorituraFormHintSeleziona => 'Seleziona';
  @override String get fiorituraFormHintNessuna => 'Nessuna';
  @override String get fiorituraFormMapHint => 'Tocca la mappa per impostare la posizione della fioritura';
  @override String get fiorituraFormTipoSpontanea => 'Spontanea';
  @override String get fiorituraFormTipoColtivata => 'Coltivata';
  @override String get fiorituraFormTipoAlberata => 'Alberata';
  @override String get fiorituraFormTipoArborea => 'Arborea';
  @override String get fiorituraFormTipoArbustiva => 'Arbustiva';
  @override String get fiorituraFormIntensita1 => 'Scarsa';
  @override String get fiorituraFormIntensita2 => 'Discreta';
  @override String get fiorituraFormIntensita3 => 'Buona';
  @override String get fiorituraFormIntensita4 => 'Ottima';
  @override String get fiorituraFormIntensita5 => 'Eccezionale';

  // ── Regina screens ────────────────────────────────────────────────────────
  @override String get reginaListTitle => 'Le mie Regine';
  @override String get reginaListSyncTooltip => 'Sincronizza dati';
  @override String get reginaListBtnRetry => 'Riprova a caricare';
  @override String reginaListItemTitle(String arniaNr) => 'Regina dell\'arnia $arniaNr';
  @override String get reginaListRazza => 'Razza';
  @override String get reginaListOrigine => 'Origine';
  @override String get reginaListIntrodotta => 'Introdotta';
  @override String get reginaListMarcata => 'Marcata';
  @override String get reginaListDetailError => 'Dettaglio regina non disponibile';
  @override String get reginaDetailTitle => 'Dettaglio Regina';
  @override String get reginaDetailNotFound => 'Nessun dato trovato per questa regina';
  @override String reginaDetailTitleArnia(String arniaId) => 'Regina - Arnia $arniaId';
  @override String get reginaDetailTooltipDelete => 'Elimina regina';
  @override String get reginaDetailBtnEdit => 'Modifica';
  @override String get reginaDetailBtnReplace => 'Sostituisci';
  @override String get reginaDetailBtnRetry => 'Riprova';
  @override String get reginaDetailDeleteTitle => 'Elimina Regina';
  @override String get reginaDetailDeletedOk => 'Regina eliminata con successo';
  @override String reginaDetailDeleteError(String e) => 'Errore durante l\'eliminazione: $e';
  @override String get reginaDetailReplaceTitle => 'Sostituisci Regina';
  @override String get reginaDetailReplaceBtn => 'CONFERMA SOSTITUZIONE';
  @override String get reginaDetailLblMotivo => 'Motivo';
  @override String get reginaDetailLblDataRimozione => 'Data rimozione';
  @override String get reginaDetailStatusAttuale => 'Attuale';
  @override String get reginaDetailLblDal => 'Dal';
  @override String get reginaDetailLblAl => 'Al';
  @override String get reginaDetailLblMotivoCambio => 'Motivo';
  @override String get reginaDetailStatusAttiva => 'Attiva';
  @override String get reginaDetailStatusNonAttiva => 'Non attiva';
  @override String reginaDetailParentela(String parentela, String data) => '$parentela: $data';
  @override String reginaDetailError(String e) => 'Errore: $e';
  @override String get reginaFormTitleNew => 'Aggiungi Regina';
  @override String get reginaFormTitleEdit => 'Modifica Regina';
  @override String get reginaFormLblRazza => 'Razza';
  @override String get reginaFormLblOrigine => 'Origine';
  @override String get reginaFormLblDataIntroduzione => 'Data introduzione';
  @override String get reginaFormLblDataNascita => 'Data nascita (opzionale)';
  @override String get reginaFormMarcataTitle => 'Marcata';
  @override String get reginaFormLblColoreMarcatura => 'Colore marcatura';
  @override String get reginaFormFecondataTitle => 'Fecondata';
  @override String get reginaFormSelezionataTitle => 'Selezionata per allevamento';
  @override String get reginaFormHintNessunaRegina => 'Nessuna (regina fondatrice)';
  @override String get reginaFormBtnSave => 'SALVA REGINA';
  @override String reginaFormError(String e) => 'Errore: $e';

  // ── Melario / Smielatura screens ──────────────────────────────────────────
  @override String get melariTitle => 'Melari e Produzioni';
  @override String get melariTooltipAdd => 'Aggiungi melario';
  @override String get melariBtnNuovaSmielatura => 'Nuova smielatura';
  @override String get melariTabTutti => 'Tutti';
  @override String get melariTabPersonali => 'Personali';
  @override String get melariNoSmielature => 'Nessuna smielatura registrata';
  @override String get melariRiepilogoProd => 'Riepilogo Produzioni';
  @override String get melariKg => 'kg';
  @override String melariSmielaturaItem(String tipo, String qty) => '$tipo - $qty kg';
  @override String melariSmielaturaSubtitle(String date, String apiario, int count) => '$date - $apiario - $count melari';
  @override String get melariCantinaTitolo => 'Cantina del miele';
  @override String get melariCantinaSubtitle => 'Maturatori · Stoccaggio · Invasettamento';
  @override String get melariNoInvasettamento => 'Nessun invasettamento registrato';
  @override String get melariRiepilogoInvasettamento => 'Riepilogo Invasettamento';
  @override String melariVasettiLabel(String formato) => 'Vasetti ${formato}g';
  @override String get melariVasetti => 'vasetti';
  @override String melariInvasettamentoItem(String tipo, String formato, int num) => '$tipo - ${formato}g x$num';
  @override String melariInvasettamentoSubtitle(String date, String kg, String? lotto) =>
      '$date - $kg kg${lotto != null ? ' - Lotto: $lotto' : ''}';
  @override String get melariMenuEdit => 'Modifica';
  @override String get melariMenuDelete => 'Elimina';
  @override String get melariDeleteInvasettTitle => 'Conferma eliminazione';
  @override String get melariDeleteInvasettMsg => 'Eliminare questo invasettamento?';
  @override String get melariDeleteInvasettOk => 'Invasettamento eliminato';
  @override String melariDeleteInvasettError(String e) => 'Errore: $e';
  @override String get melariRemoveMelarioTitle => 'Rimuovi melario';
  @override String get melariRemoveMelarioDialogTitle => 'Rimuovi melario';
  @override String get melariEliminaMelarioTitle => 'Elimina melario';
  @override String get melariLblPesoStimato => 'Peso stimato (kg)';
  @override String get melariNoData => 'Nessun dato disponibile';
  @override String get melariMelarioLabel => 'Melario';
  @override String melariArniaLabel(String num) => 'Arnia #$num';
  @override String get melariPosizionati => 'Posizionati';
  @override String get melariInSmielatura => 'In smielatura';
  @override String melariMelarioId(int id) => 'Melario #$id';
  @override String melariTelainiPosizione(int telaini, int posizione, String tipo) =>
      '$telaini telaini · Posizione $posizione · $tipo';
  @override String get melariSmielBtn => 'Smiel.';
  @override String get melariQeLabel => 'QE';
  @override String get smielaturaFormTitleNew => 'Nuova Smielatura';
  @override String get smielaturaFormTitleEdit => 'Modifica Smielatura';
  @override String get smielaturaFormLblApiario => 'Apiario *';
  @override String get smielaturaFormLblData => 'Data *';
  @override String get smielaturaFormLblTipoMiele => 'Tipo miele *';
  @override String get smielaturaFormLblQuantita => 'Quantità miele (kg) *';
  @override String get smielaturaFormLblNote => 'Note';
  @override String smielaturaFormMelarioItem(int id, String arniaNum) => 'Melario #$id - Arnia $arniaNum';
  @override String smielaturaFormMelarioStato(String stato) => 'Stato: $stato';
  @override String get smielaturaFormSelectApiarioMsg => 'Seleziona un apiario';
  @override String smielaturaFormError(String e) => 'Errore caricamento dati: $e';
  @override String get smielaturaFormOfflineMsg => 'Modalità offline — dati aggiornati all\'ultimo accesso';

  // ── Controllo form ────────────────────────────────────────────────────────
  @override String get controlloFormDialogTitle => 'Controllo Arnia';
  @override String get controlloFormTitleNew => 'Nuovo Controllo';
  @override String get controlloFormTitleEdit => 'Modifica Controllo';
  @override String get controlloFormLblData => 'Data';
  @override String get controlloFormBtnAutoOrdina => 'Auto-ordina';
  @override String get controlloFormLblNumCelleReali => 'Numero celle reali';
  @override String get controlloFormLblNoteSciamatura => 'Note sciamatura';
  @override String get controlloFormLblDettagliProblemi => 'Dettagli problemi sanitari';
  @override String get controlloFormLblNote => 'Note';
  @override String get controlloFormHintNote => 'Inserisci eventuali note aggiuntive...';
  @override String get controlloFormSyncOk => 'Dati sincronizzati con successo';
  @override String get controlloFormLblStatoRegina => 'Stato regina';
  @override String get controlloFormLblColore => 'Colore marcatura';
  @override String get controlloFormToccoTelaino => 'Tocca un telaino per cambiare il tipo';

  // ── Dashboard Screen ─────────────────────────────────────────────────────
  @override String get dashSyncing => 'Sincronizzazione in corso...';
  @override String get dashSyncDone => 'Dati aggiornati!';
  @override String get dashExitTitle => 'Uscire dall\'app?';
  @override String get dashExitMessage => 'Vuoi chiudere l\'applicazione?';
  @override String get dashExitCancel => 'Annulla';
  @override String get dashExitConfirm => 'Esci';
  @override String get dashTitle => 'Dashboard';
  @override String get dashSearchHint => 'Cerca...';
  @override String get dashSearchTooltip => 'Cerca';
  @override String get dashCloseSearchTooltip => 'Chiudi ricerca';
  @override String dashWelcomeUser(String name) => 'Benvenuto, $name';
  @override String get dashContextualHint =>
      '👋 Qui trovi il riepilogo di tutte le attività — arnie, controlli recenti e raccolti. Tocca una sezione per entrare.';
  @override String get dashCalendarTitle => 'Calendario attività';
  @override String get dashCalendarToday => 'Oggi';
  @override String get dashCalendarPrevWeek => 'Settimana precedente';
  @override String get dashCalendarNextWeek => 'Settimana successiva';
  @override String get dashCalendarPrevMonth => 'Mese precedente';
  @override String get dashCalendarNextMonth => 'Mese successivo';
  @override String get dashCalendarViewMonth => 'Mese';
  @override String get dashCalendarViewWeek => 'Settimana';
  @override String get dashCalendarLegendControlli => 'Controlli';
  @override String get dashCalendarLegendTrattamenti => 'Trattamenti';
  @override String get dashCalendarLegendFioriture => 'Fioriture';
  @override String get dashCalendarLegendRegine => 'Regine';
  @override String get dashCalendarLegendMelari => 'Melari';
  @override String get dashCalendarLegendSmielature => 'Smielature';
  @override String get dashCalendarLegendSospensione => 'Sospensione';
  @override String get dashCalendarLegendBloccoCovata => 'Blocco covata';
  @override String dashCalendarTodayDate(String date) => 'Oggi — $date';
  @override String dashCalendarDateEvents(String date) => 'Eventi del $date';
  @override String get dashCalendarNoEventsToday => 'Nessuna attività prevista per oggi.';
  @override String get dashCalendarNoEvents => 'Nessun evento per questa giornata.';
  @override List<String> get dashWeekdayAbbr =>
      ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  @override String get dashEventTrattamento => 'Trattamento';
  @override String get dashEventSospensione => 'Sospensione';
  @override String get dashEventBloccoCovata => 'Blocco covata';
  @override String get dashEventFioritura => 'Fioritura';
  @override String dashEventControlloArnia(String num) => 'Controllo arnia $num';
  @override String get dashEventReginaIntrodotta => 'Regina introdotta';
  @override String get dashEventArniaSep => ' — arnia ';
  @override String get dashEventMelarioPosizionato => 'Melario posizionato';
  @override String get dashEventMelarioRimosso => 'Melario rimosso';
  @override String get dashEventSmielatura => 'Smielatura';
  @override String get dashSectionApiari => 'I tuoi apiari';
  @override String get dashSectionTrattamenti => 'Trattamenti sanitari attivi';
  @override String get dashSectionFioriture => 'Fioriture attive';
  @override String get dashBtnViewAll => 'Vedi tutti';
  @override String get dashBtnCreateApiario => 'Crea nuovo apiario';
  @override String get dashNoApiari => 'Nessun apiario disponibile';
  @override String get dashNoTrattamenti => 'Nessun trattamento attivo';
  @override String get dashNoFioriture => 'Nessuna fioritura attiva';
  @override String dashLoadError(String err) => 'Errore nel caricamento dei dati: $err';
  @override String get dashAlertsTitle => 'Avvisi e suggerimenti';
  @override String get dashAlertViewDetails => 'Vedi dettagli';
  @override String get dashAlertTrattamentoExpiringTitle => 'Trattamento in scadenza';
  @override String dashAlertTrattamentoExpiringMsg(String nome, int days) =>
      'Il trattamento "$nome" scadrà tra $days giorni.';
  @override String get dashAlertApiarioToVisitTitle => 'Apiario da visitare';
  @override String dashAlertApiarioToVisitMsg(String nome) =>
      'L\'apiario "$nome" non viene visitato da più di 14 giorni.';
  @override String get dashWeatherLocal => 'Meteo locale';
  @override String dashWeatherHumidity(String pct) => 'Umidità: $pct%';
  @override String get dashPositionNone => 'Posizione non specificata';
  @override String get dashStatusNd => 'N/D';
  @override String get dashStatusInCorso => 'In corso';
  @override String get dashStatusProgrammato => 'Programmato';
  @override String get dashStatusCompletato => 'Completato';
  @override String get dashStatusApiario => 'Apiario';
  @override String dashTrattamentoDates(String start, String end) => 'Dal $start al $end';
  @override String get dashFiorituraAttiva => 'Attiva';
  @override String get dashFiorituraTerminata => 'Terminata';
  @override String dashFiorituraDates(String start, String? end) =>
      'Dal $start${end != null ? ' al $end' : ''}';
  @override String dashSearchNoResults(String query) =>
      'Nessun risultato trovato per "$query"';
  @override String dashSearchSection(String label, int count) => '$label ($count)';
  @override String get dashFabVoiceInput => 'Input vocale';
  @override String get dashFabAiAssistant => 'ApiarioAI Assistant';
  @override String get dashFabScanQr => 'Scansiona QR';
  @override String get dashFabNewApiario => 'Nuovo apiario';
}
