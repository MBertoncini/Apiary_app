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

  // Equipment prompt
  @override String get sectionEquipmentPrompt => 'Attrezzatura';
  @override String get settingsAttrezzaturaPrompt => 'Suggerisci registrazione attrezzatura';
  @override String get settingsAttrezzaturaPromptSub => 'Mostra popup dopo creazione arnie';

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
  @override String get reginaListOfflineTooltip => 'Modalità offline - Dati caricati dalla cache';
  @override String get reginaListEmptyTitle => 'Nessuna regina trovata';
  @override String get reginaListEmptySubtitle => 'Aggiungi regine dalle schede delle singole arnie.';
  // Detail
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
  @override String get reginaDetailTabDettagli => 'Dettagli';
  @override String get reginaDetailTabGenealogia => 'Genealogia';
  @override String get reginaDetailSectionGeneral => 'Informazioni Generali';
  @override String get reginaDetailSectionMarcatura => 'Marcatura';
  @override String get reginaDetailLblDataNascita => 'Data nascita';
  @override String get reginaDetailLblSelezionata => 'Selezionata';
  @override String reginaDetailLblEta(String age) => 'Età: $age';
  @override String get reginaDetailAlberoGenealogia => 'Albero Genealogico';
  @override String reginaDetailAlberoSubtitle(String arniaId) =>
      'Lignaggio della regina dell\'arnia $arniaId';
  @override String get reginaDetailNoGenealogia => 'Nessun dato genealogico disponibile';
  @override String get reginaDetailGenealogiaNonDisp => 'Dati genealogia non disponibili';
  @override String get reginaDetailReginaAttuale => 'Regina Attuale';
  @override String reginaDetailFiglie(int n) => 'Figlie ($n)';
  @override String get reginaDetailStoriaArnie => 'Storia nelle arnie';
  @override String get reginaDetailInfoAggiuntive => 'Informazioni Aggiuntive';
  @override String reginaDetailChipIntrodotta(String date) => 'Introdotta: $date';
  @override String reginaDetailChipNata(String date) => 'Nata: $date';
  @override String reginaDetailDeleteMsg(String arniaId) =>
      'Sei sicuro di voler eliminare la regina dell\'arnia $arniaId?\n\n'
      'Questa azione non può essere annullata.';
  @override String reginaDetailAgeAnni(int n) => '$n ${n == 1 ? 'anno' : 'anni'}';
  @override String reginaDetailAgeMesi(int n) => '$n ${n == 1 ? 'mese' : 'mesi'}';
  @override String reginaDetailAgeGiorni(int n) => '$n ${n == 1 ? 'giorno' : 'giorni'}';
  @override String get reginaDetailColoreBianco => 'Bianco (anni terminanti in 1,6)';
  @override String get reginaDetailColoreGiallo => 'Giallo (anni terminanti in 2,7)';
  @override String get reginaDetailColoreRosso => 'Rosso (anni terminanti in 3,8)';
  @override String get reginaDetailColoreVerde => 'Verde (anni terminanti in 4,9)';
  @override String get reginaDetailColoreBlu => 'Blu (anni terminanti in 5,0)';
  @override String get reginaDetailColoreNonMarcata => 'Non Marcata';
  // Form
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
  @override String get reginaFormHintDataNascitaVuota => 'Non specificata';
  @override String get reginaFormValutazioniTitle => 'Valutazioni (opzionale)';
  @override String get reginaFormValutazioniHint => 'Tocca le stelle per assegnare un punteggio da 1 a 5.';
  @override String get reginaFormLblReginaMadre => 'Regina madre (opzionale)';
  @override String get reginaFormLblNote => 'Note (opzionale)';
  @override String get reginaFormCreatedOk => 'Regina aggiunta con successo';
  @override String get reginaFormUpdatedOk => 'Regina modificata con successo';

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
  // Melari screen extra
  @override String get melariTabAlveari => 'Alveari';
  @override String get melariTabSmielature => 'Smielature';
  @override String get melariSummaryTotale => 'Totale';
  @override String get melariSummarySmielature => 'Smielature';
  @override String get melariSummaryTipi => 'Tipi';
  @override String get melariSummaryInvasettato => 'Invasettato';
  @override String get melariSummaryRaccolto => 'Raccolto';
  @override String get melariHiveLegendNido => 'Nido';
  @override String get melariHiveLegendPosizionato => 'Posizionato';
  @override String get melariHiveLegendInSmielatura => 'In smielatura';
  @override String get melariHiveLblNido => '🐝 NIDO';
  @override String get melariNoMelari => 'nessun melario';
  @override String melariCountMelari(int n) => '$n melar${n == 1 ? 'io' : 'i'}';
  @override String melariArniaNumLabel(int n) => 'Arnia #$n';
  @override String melariFaviLabel(int n) => '🍯 $n favi';
  @override String melariPosTipoLabel(int pos, String tipo) => 'Pos. $pos · $tipo';
  @override String melariTelainiLabel(int n) => '$n telaini';
  @override String melariPesoStimatoLabel(String peso) => 'Peso stimato: $peso kg';
  @override String get melariRemoveMelarioMsg => 'Confermi di voler rimuovere questo melario?';
  @override String melariDeleteMelarioMsg(int id) => 'Eliminare il melario #$id?';
  @override String get melariDeleteMelarioOk => 'Melario eliminato';
  @override String get melariConfirmBtn => 'Conferma';
  // Melario form
  @override String get melarioFormTitle => 'Nuovo Melario';
  @override String get melarioFormSectionId => 'Identificazione e Tracciabilità';
  @override String get melarioFormSectionProd => 'Dati di Produzione';
  @override String get melarioFormLblTipo => 'Tipo Melario';
  @override String get melarioFormLblStatoFavi => 'Stato dei Favi';
  @override String get melarioFormLblNumTelaini => 'Numero Telaini';
  @override String get melarioFormLblPosizione => 'Posizione (dal nido)';
  @override String get melarioFormLblEscludiRegina => 'Escludi Regina';
  @override String get melarioFormSubEscludiRegina => 'Posiziona un escludiregina per evitare covata';
  @override String get melarioFormLblNote => 'Note aggiuntive';
  @override String get melarioFormHintNote => 'Osservazioni, fioritura in corso...';
  @override String get melarioFormBtnAdd => 'Aggiungi Melario';
  @override String get melarioFormFaviCostruiti => 'Già costruiti';
  @override String get melarioFormFaviCerei => 'Fogli cerei';
  @override String get melarioFormLblDataPos => 'Data posizionamento';
  @override String get melarioFormHintSelectApiario => 'Seleziona prima un apiario';
  @override String get melarioFormNoArnie => 'Nessuna arnia disponibile';
  @override String get melarioFormValidateArnia => 'Seleziona un\'arnia';
  @override String melarioFormLoadError(String e) => 'Errore nel caricamento: $e';
  @override String melarioFormArnieLoadError(String e) => 'Errore caricamento arnie: $e';
  @override String get melarioFormCreatedOk => 'Melario aggiunto con successo';
  // Smielatura form extra
  @override String get smielaturaFormLblMelariDisp => 'Melari disponibili';
  @override String get smielaturaFormValidateNumero => 'Inserisci un numero valido';
  @override String get smielaturaFormValidateQuantitaMax => 'La quantità non può superare 99999.99 kg';
  @override String get smielaturaFormSelectMelarioMsg => 'Seleziona almeno un melario';
  @override String get smielaturaFormNoMelariDisp => 'Nessun melario in stato "in smielatura" per questo apiario';
  @override String get smielaturaFormBtnCreate => 'REGISTRA';
  @override String get smielaturaFormBtnUpdate => 'AGGIORNA';
  @override String get smielaturaFormCreatedOk => 'Smielatura registrata';
  @override String get smielaturaFormUpdatedOk => 'Smielatura aggiornata';
  // Smielatura detail
  @override String get smielaturaDetailTitle => 'Dettaglio Smielatura';
  @override String get smielaturaDetailDeleteMsg => 'Sei sicuro di voler eliminare questa smielatura?';
  @override String get smielaturaDetailDeletedOk => 'Smielatura eliminata';
  @override String get smielaturaDetailNotFound => 'Smielatura non trovata';
  @override String smielaturaDetailMelariCount(int n) => '$n melar${n == 1 ? 'io' : 'i'}';
  @override String get smielaturaDetailMelariAssociati => 'Melari associati';
  @override String get smielaturaDetailLblMelari => 'Melari';

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
  // Invasettamento form
  @override String get invasettamentoFormTitleNew => 'Nuovo Invasettamento';
  @override String get invasettamentoFormTitleEdit => 'Modifica Invasettamento';
  @override String get invasettamentoFormLblSmielatura => 'Smielatura *';
  @override String get invasettamentoFormValidateSmielatura => 'Seleziona una smielatura';
  @override String get invasettamentoFormCreatedOk => 'Invasettamento registrato';
  @override String get invasettamentoFormUpdatedOk => 'Invasettamento aggiornato';
  @override String get invasettamentoFormLblFormato => 'Formato vasetto *';
  @override String get invasettamentoFormLblNumVasetti => 'Numero vasetti *';
  @override String get invasettamentoFormValidateNumVasetti => 'Inserisci un numero intero';
  @override String invasettamentoFormLblTotale(String kg) => 'Totale: $kg kg';
  @override String get invasettamentoFormLblLotto => 'Lotto';

  // ── Controllo form (legacy keys) ──────────────────────────────────────────
  @override String get controlloFormDialogTitle => 'Controllo Arnia';
  @override String get controlloFormBtnAutoOrdina => 'Auto-ordina';
  @override String get controlloFormLblNumCelleReali => 'Numero celle reali';
  @override String get controlloFormLblNoteSciamatura => 'Note sciamatura';
  @override String get controlloFormLblDettagliProblemi => 'Dettagli problemi sanitari';
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

  // ── Auth – Login Screen ───────────────────────────────────────────────────
  @override String get loginSubtitle => 'Accedi per gestire i tuoi apiari';
  @override String get loginFieldUsernameLabel => 'Username o Email';
  @override String get loginFieldUsernameHint => 'Inserisci il tuo username o email';
  @override String get loginFieldUsernameValidate => 'Inserisci il tuo username o email';
  @override String get loginFieldPasswordLabel => 'Password';
  @override String get loginFieldPasswordHint => 'Inserisci la tua password';
  @override String get loginFieldPasswordValidate => 'Inserisci la tua password';
  @override String get loginForgotPassword => 'Hai dimenticato la password?';
  @override String get loginBtnAccedi => 'ACCEDI';
  @override String get loginOr => 'oppure';
  @override String get loginBtnGoogle => 'Continua con Google';
  @override String get loginBtnRegister => 'Non hai un account? Registrati';
  @override String get loginErrUserNotFound => 'Username o email non trovati. Non hai ancora un account?';
  @override String get loginErrWrongPassword => 'Password errata.';
  @override String get loginErrWrongCredentials => 'Credenziali non valide. Controlla username/email e password.';
  @override String get loginErrGoogleAuth => 'Accesso con Google fallito. Riprova.';
  @override String get loginErrGoogleToken => 'Impossibile ottenere il token Google. Riprova.';
  @override String get loginErrNetwork => 'Impossibile connettersi al server. Controlla la connessione internet.';
  @override String get loginErrTimeout => 'Il server non risponde. Riprova tra qualche istante.';
  @override String get loginErrServer => 'Errore interno del server. Riprova più tardi.';
  @override String get loginErrDefault => 'Si è verificato un errore. Riprova.';
  @override String get loginHintForgotPassword => 'Hai dimenticato la password?';
  @override String get loginHintRegister => 'Non hai un account? Registrati ora';

  // ── Auth – Register Screen ────────────────────────────────────────────────
  @override String get registerTitle => 'Registrazione';
  @override String get registerCreateAccount => 'Crea un account';
  @override String get registerFieldUsername => 'Username';
  @override String get registerHintUsername => 'Inserisci un username';
  @override String get registerValidateUsername => 'Inserisci un username';
  @override String get registerFieldEmail => 'Email';
  @override String get registerHintEmail => 'Inserisci la tua email';
  @override String get registerValidateEmail => 'Inserisci una email';
  @override String get registerValidateEmailFormat => 'Inserisci una email valida';
  @override String get registerFieldPassword => 'Password';
  @override String get registerHintPassword => 'Inserisci una password';
  @override String get registerValidatePassword => 'Inserisci una password';
  @override String get registerValidatePasswordLength => 'La password deve contenere almeno 8 caratteri';
  @override String get registerFieldConfirmPassword => 'Conferma Password';
  @override String get registerHintConfirmPassword => 'Conferma la tua password';
  @override String get registerValidateConfirmPassword => 'Conferma la tua password';
  @override String get registerValidatePasswordMatch => 'Le password non corrispondono';
  @override String get registerErrPasswordMismatch => 'Le password non corrispondono.';
  @override String get registerErrPrivacyRequired => 'Devi accettare l\'Informativa sulla Privacy per procedere.';
  @override String get registerPrivacyText => 'Ho letto e accetto l\'';
  @override String get registerPrivacyLink => 'Informativa sulla Privacy';
  @override String get registerBtnRegister => 'REGISTRATI';
  @override String get registerBtnLogin => 'Hai già un account? Accedi';
  @override String get registerSuccessMsg => 'Registrazione completata. Ora puoi effettuare il login.';
  @override String get registerErrGeneric => 'Errore durante la registrazione.';
  @override String get registerErrNetwork => 'Errore di connessione. Riprova più tardi.';

  // ── Auth – Forgot Password Screen ─────────────────────────────────────────
  @override String get forgotPasswordTitle => 'Password dimenticata';
  @override String get forgotPasswordResetTitle => 'Reimposta la password';
  @override String get forgotPasswordSubtitle =>
      'Inserisci l\'indirizzo email associato al tuo account. Ti invieremo un link per reimpostare la password.';
  @override String get forgotPasswordFieldEmail => 'Email';
  @override String get forgotPasswordHintEmail => 'Inserisci la tua email';
  @override String get forgotPasswordValidateEmail => 'Inserisci la tua email';
  @override String get forgotPasswordValidateEmailFormat => 'Inserisci un indirizzo email valido';
  @override String get forgotPasswordBtnSend => 'INVIA LINK';
  @override String get forgotPasswordBtnBack => 'Torna al login';
  @override String get forgotPasswordSuccessTitle => 'Email inviata!';
  @override String forgotPasswordSuccessBody(String email) =>
      'Abbiamo inviato le istruzioni per reimpostare la password a:\n$email\n\nControlla anche la cartella spam.';
  @override String get forgotPasswordBtnBackToLogin => 'TORNA AL LOGIN';
  @override String get forgotPasswordBtnRetry => 'Non ho ricevuto l\'email — riprova';

  // ── Colonia screens ───────────────────────────────────────────────────────
  @override String get coloniaDetailTitle => 'Colonia';
  @override String get coloniaDetailNotFound => 'Colonia non trovata';
  @override String get coloniaDetailTabInfo => 'Info';
  @override String get coloniaDetailTabControlli => 'Controlli';
  @override String get coloniaDetailMenuChiudi => 'Chiudi ciclo di vita';
  @override String get coloniaDetailLblContenitore => 'Contenitore';
  @override String get coloniaDetailLblApiario => 'Apiario';
  @override String get coloniaDetailLblInsediataIl => 'Insediata il';
  @override String get coloniaDetailLblChiusaIl => 'Chiusa il';
  @override String get coloniaDetailLblMotivoFine => 'Motivo fine';
  @override String get coloniaDetailSectionRegina => 'Regina';
  @override String get coloniaDetailLblRazza => 'Razza';
  @override String get coloniaDetailLblOrigine => 'Origine';
  @override String get coloniaDetailLblIntrodottaIl => 'Introdotta il';
  @override String get coloniaDetailLblOrigineDa => 'Origine da colonia';
  @override String get coloniaDetailLblConfluitaIn => 'Confluita in';
  @override String get coloniaDetailLblTotaleControlli => 'Totale controlli';
  @override String get coloniaDetailSectionNote => 'Note';
  @override String get coloniaDetailNoControlli => 'Nessun controllo registrato';
  @override String coloniaId(int id) => 'Colonia #$id';
  @override String coloniaOrigineDaId(int id) => 'Colonia #$id';
  @override String coloniaConfluitaInId(int id) => 'Colonia #$id';
  @override String coloniaControlloSubtitle(int scorte, int covata) => 'Scorte: $scorte · Covata: $covata';
  @override String get coloniaControlloSciamatura => ' · ⚠ Sciamatura';

  // Colonia form
  @override String get coloniaFormTitle => 'Insedia nuova colonia';
  @override String get coloniaFormLblData => 'Data insediamento *';
  @override String get coloniaFormHintData => 'Formato: AAAA-MM-GG';
  @override String get coloniaFormValidateData => 'Inserire la data';
  @override String get coloniaFormLblNote => 'Note';
  @override String get coloniaFormCreatedOk => 'Colonia insediata con successo';
  @override String get coloniaFormErrorSave => 'Errore durante il salvataggio';
  @override String coloniaFormError(String e) => 'Errore: $e';

  // Colonia chiudi
  @override String coloniaChiudiTitle(int id) => 'Chiudi Colonia #$id';
  @override String get coloniaChiudiWarning =>
      'Questa operazione chiude il ciclo di vita della colonia. '
      'Tutti i dati storici (controlli, regina, melari) vengono conservati.';
  @override String get coloniaChiudiLblStato => 'Motivo di fine *';
  @override String get coloniaChiudiLblData => 'Data di fine *';
  @override String get coloniaChiudiLblMotivo => 'Descrizione (opzionale)';
  @override String get coloniaChiudiLblNote => 'Note aggiuntive';
  @override String get coloniaChiudiValidateStato => 'Selezionare un motivo';
  @override String get coloniaChiudiValidateData => 'Inserire la data';
  @override String get coloniaChiudiBtn => 'Chiudi';
  @override String get coloniaChiusaOk => 'Ciclo di vita chiuso';
  @override String coloniaChiudiError(String e) => 'Errore: $e';
  @override String get coloniaStatoMorta => 'Colonia morta';
  @override String get coloniaStatoVenduta => 'Ceduta / Venduta';
  @override String get coloniaStatoSciamata => 'Sciamata e non recuperata';
  @override String get coloniaStatoUnita => 'Unita ad altra colonia';
  @override String get coloniaStatoNucleo => 'Ridotta a nucleo';
  @override String get coloniaStatoEliminata => 'Eliminata';

  // Storia colonie
  @override String get storiaColonieTitle => 'Storia colonie';
  @override String get storiaColonieEmpty => 'Nessuna colonia storica';
  @override String storiaColonieItem(int id, String stato) => 'Colonia #$id · $stato';
  @override String storiaColonieDates(String start, String? end) =>
      'Dal $start${end != null ? ' al $end' : ''}';
  @override String get storiaColonieInCorso => ' · in corso';

  // ── Attrezzatura screens ──────────────────────────────────────────────────
  @override String get attrezzatureTitle => 'Attrezzature';
  @override String get attrezzatureFiltriAvanzatiTooltip => 'Filtri avanzati';
  @override String get attrezzatureSincronizzaTooltip => 'Sincronizza';
  @override String get attrezzaturaSearchHint => 'Cerca per nome, marca, modello…';
  @override String get attrezzaturaCatTutti => 'Tutti';
  @override String get attrezzaturaCatTutte => 'Tutte';
  @override String get attrezzaturaCatConsumabili => 'Consumabili';
  @override String get attrezzaturaCatProtezione => 'Protezione';
  @override String get attrezzaturaCatStrumenti => 'Strumenti';
  @override String get attrezzaturaCatAltro => 'Altro';
  @override String attrezzaturaQta(int n) => 'Qtà: $n';
  @override String attrezzaturaAcquistatoDate(String d) => 'Acquistato: $d';
  @override String get attrezzaturaNoRegistrata => 'Nessuna attrezzatura registrata';
  @override String get attrezzaturaNoFiltri => 'Nessuna attrezzatura corrisponde ai filtri';
  @override String get attrezzaturaBtnAggiungi => 'Aggiungi Attrezzatura';
  @override String get attrezzaturaBtnRimuoviFiltri => 'Rimuovi filtri';
  @override String get attrezzaturaFiltriAvanzatiTitle => 'Filtri avanzati';
  @override String get attrezzaturaFiltriReset => 'Reset';
  @override String get attrezzaturaFiltriLblStato => 'Stato';
  @override String get attrezzaturaFiltriLblCondizione => 'Condizione';
  @override String get attrezzaturaFiltriLblDataAcquisto => 'Data acquisto';
  @override String get attrezzaturaFiltriLblPrezzo => 'Prezzo acquisto (€)';
  @override String get attrezzaturaFiltriApplica => 'Applica filtri';
  @override String get attrezzaturaFabTooltip => 'Nuova Attrezzatura';
  @override String get attrezzaturaErrLoading => 'Errore durante il caricamento';

  @override String get attrezzaturaDetailTitle => 'Dettaglio Attrezzatura';
  @override String get attrezzaturaDetailTabInfo => 'Info';
  @override String get attrezzaturaDetailTabSpese => 'Spese';
  @override String get attrezzaturaDetailTabManutenzioni => 'Manutenzioni';
  @override String get attrezzaturaDetailNonCategorizzato => 'Non categorizzato';
  @override String get attrezzaturaDetailLblCondizione => 'Condizione';
  @override String get attrezzaturaDetailLblDescrizione => 'Descrizione';
  @override String get attrezzaturaDetailLblMarca => 'Marca';
  @override String get attrezzaturaDetailLblModello => 'Modello';
  @override String get attrezzaturaDetailLblSerie => 'N. Serie';
  @override String get attrezzaturaDetailLblQuantita => 'Quantità';
  @override String get attrezzaturaDetailLblUnitaMisura => 'Unità Misura';
  @override String get attrezzaturaDetailLblDataAcquisto => 'Data Acquisto';
  @override String get attrezzaturaDetailLblPrezzoAcquisto => 'Prezzo Acquisto';
  @override String get attrezzaturaDetailLblFornitore => 'Fornitore';
  @override String get attrezzaturaDetailLblGaranzia => 'Garanzia fino a';
  @override String get attrezzaturaDetailLblPosizione => 'Posizione';
  @override String get attrezzaturaDetailLblGruppo => 'Gruppo';
  @override String get attrezzaturaDetailStatistiche => 'Statistiche';
  @override String get attrezzaturaDetailSpeseTotali => 'Spese Totali';
  @override String get attrezzaturaDetailNessunaSpesa => 'Nessuna spesa registrata';
  @override String get attrezzaturaDetailBtnAggiungiSpesa => 'Aggiungi Spesa';
  @override String get attrezzaturaDetailNessunaManutenzione => 'Nessuna manutenzione registrata';
  @override String get attrezzaturaDetailBtnAggiungiManutenzione => 'Aggiungi Manutenzione';
  @override String get attrezzaturaDetailInRitardo => ' In ritardo';
  @override String attrezzaturaDetailProgrammata(String d) => 'Programmata: $d';
  @override String get attrezzaturaDetailMenuAddSpesaTitle => 'Aggiungi Spesa';
  @override String get attrezzaturaDetailMenuAddSpesaSubtitle => 'Registra una nuova spesa per questa attrezzatura';
  @override String get attrezzaturaDetailMenuAddManutenzioneTitle => 'Aggiungi Manutenzione';
  @override String get attrezzaturaDetailMenuAddManutenzioneSubtitle => 'Programma o registra una manutenzione';
  @override String get attrezzaturaDeleteTitle => 'Elimina Attrezzatura';
  @override String get attrezzaturaDeletedOk => 'Attrezzatura eliminata con successo';
  @override String attrezzaturaDeleteError(String e) => 'Errore durante l\'eliminazione: $e';
  @override String get attrezzaturaDeleteSpesaTitle => 'Elimina Spesa';
  @override String get attrezzaturaDeleteSpesaOk => 'Spesa eliminata con successo';
  @override String attrezzaturaDeleteSpesaError(String e) => 'Errore durante l\'eliminazione: $e';
  @override String get attrezzaturaDeleteManutenzioneTitle => 'Elimina Manutenzione';
  @override String get attrezzaturaDeleteManutenzioneOk => 'Manutenzione eliminata con successo';
  @override String attrezzaturaDeleteManutenzioneError(String e) => 'Errore durante l\'eliminazione: $e';
  @override String get attrezzaturaErrDetailLoading => 'Errore durante il caricamento';
  @override String get attrezzaturaEliminaSpesaTooltip => 'Elimina spesa';
  @override String get attrezzaturaEliminaManutenzioneTooltip => 'Elimina manutenzione';

  // ── Vendita screens ───────────────────────────────────────────────────────
  @override String get venditeTitle => 'Vendite';
  @override String get venditeTabVendite => 'Vendite';
  @override String get venditeTabClienti => 'Clienti';
  @override String get venditeOfflineMsg => 'Modalità offline — dati aggiornati all\'ultimo accesso';
  @override String get venditeNoVendite => 'Nessuna vendita registrata';
  @override String get venditeNoClienti => 'Nessun cliente registrato';
  @override String get venditeErrLoading => 'Errore nel caricamento';
  @override String venditeArticoli(int n) => '$n articoli';
  @override String venditeClienteVendite(int n) => '$n vendite';
  @override String get venditeTooltipSync => 'Sincronizza';
  @override String get venditeFabTooltip => 'Nuova vendita';
  @override String get venditeClientiFabTooltip => 'Nuovo cliente';

  // ── Gruppo screens ────────────────────────────────────────────────────────
  @override String get gruppiTitle => 'Gruppi';
  @override String get gruppiFabTooltip => 'Crea nuovo gruppo';
  @override String get gruppiInvitoAccettato => 'Invito accettato';
  @override String get gruppiInvitoRifiutato => 'Invito rifiutato';
  @override String gruppiInvitoError(String e) => 'Errore: $e';
  @override String get gruppiBtnRifiuta => 'RIFIUTA';
  @override String get gruppiBtnAccetta => 'ACCETTA';
  @override String get gruppiBtnCrea => 'Crea un nuovo gruppo';
  @override String get gruppiErrLoading => 'Errore nel caricamento del gruppo';
  @override String get gruppiBtnRiprova => 'RIPROVA';
  @override String get gruppiTuoiGruppi => 'I tuoi gruppi';
  @override String get gruppiInvitiRicevuti => 'Inviti ricevuti';
  @override String get gruppiNoMembro => 'Non sei membro di nessun gruppo';
  @override String gruppiInvitatoDa(String user, String ruolo) => 'Sei stato invitato da $user con il ruolo di $ruolo';
  @override String gruppiDataInvio(String d) => 'Data invio: $d';
  @override String gruppiScadeIl(String d) => 'Scade il: $d';
  @override String gruppiMembriCount(int n) => '$n membri';
  @override String gruppiApiariCondivisi(int n) => '$n apiari condivisi';
  @override String get gruppiErrLoadingGruppi => 'Errore nel caricamento dei gruppi';

  // ── Attrezzatura form ─────────────────────────────────────────────────────
  @override String get attrezzaturaFormTitleNew => 'Nuova Attrezzatura';
  @override String get attrezzaturaFormTitleEdit => 'Modifica Attrezzatura';
  @override String get attrezzaturaFormLblNome => 'Nome *';
  @override String get attrezzaturaFormValidateNome => 'Inserisci il nome dell\'attrezzatura';
  @override String get attrezzaturaFormValidateCampoObbligatorio => 'Campo obbligatorio';
  @override String get attrezzaturaFormLblMarca => 'Marca';
  @override String get attrezzaturaFormLblModello => 'Modello';
  @override String get attrezzaturaFormLblQuantita => 'Quantità *';
  @override String get attrezzaturaFormValidateQuantita => 'Inserisci la quantità';
  @override String get attrezzaturaFormValidateNumero => 'Inserisci un numero valido';
  @override String get attrezzaturaFormLblStato => 'Stato';
  @override String get attrezzaturaFormLblCondizione => 'Condizione';
  @override String get attrezzaturaFormLblDataAcquisto => 'Data Acquisto';
  @override String get attrezzaturaFormLblPrezzoAcquisto => 'Prezzo Acquisto (€)';
  @override String get attrezzaturaFormHelperPrezzo => 'Se inserisci un prezzo, verrà creato automaticamente un pagamento';
  @override String get attrezzaturaFormValidateImporto => 'Inserisci un importo valido';
  @override String get attrezzaturaFormLblFornitore => 'Fornitore';
  @override String get attrezzaturaFormSectionCondivisione => 'Condivisione';
  @override String get attrezzaturaFormLblCondividi => 'Condividi con gruppo';
  @override String get attrezzaturaFormSubCondividi => 'Le spese verranno condivise con i membri del gruppo';
  @override String get attrezzaturaFormLblChiHaPagato => 'Chi ha pagato?';
  @override String get attrezzaturaFormHintIoStesso => '— io stesso —';
  @override String get attrezzaturaFormHelperChiPaga => 'Indica il membro del gruppo che ha effettivamente sostenuto la spesa';
  @override String get attrezzaturaFormLblNote => 'Note';
  @override String get attrezzaturaFormInfoPagamento => 'Se inserisci un prezzo di acquisto, verrà creato automaticamente un pagamento.';
  @override String get attrezzaturaFormBtnSalva => 'SALVA';
  @override String get attrezzaturaFormBtnAggiorna => 'AGGIORNA';
  @override String get attrezzaturaFormCreatedOk => 'Attrezzatura creata con successo';
  @override String get attrezzaturaFormUpdatedOk => 'Attrezzatura aggiornata con successo';
  @override String get attrezzaturaFormPagamentoAuto => 'Pagamento registrato automaticamente';
  @override String attrezzaturaFormLoadError(String e) => 'Errore durante il caricamento: $e';
  @override String attrezzaturaFormSaveError(String e) => 'Errore durante il salvataggio: $e';
  @override String get attrezzaturaStatoDisponibile => 'Disponibile';
  @override String get attrezzaturaStatoInUso => 'In Uso';
  @override String get attrezzaturaStatoManutenzione => 'In Manutenzione';
  @override String get attrezzaturaStatoDismesso => 'Dismesso';
  @override String get attrezzaturaStatoPrestato => 'Prestato';
  @override String get attrezzaturaCondizioneNuovo => 'Nuovo';
  @override String get attrezzaturaCondizioneOttimo => 'Ottimo';
  @override String get attrezzaturaCondizioneBuono => 'Buono';
  @override String get attrezzaturaCondizioneDiscreto => 'Discreto';
  @override String get attrezzaturaCondizioneUsurato => 'Usurato';
  @override String get attrezzaturaCondizioneDaRiparare => 'Da Riparare';

  // ── Manutenzione form ─────────────────────────────────────────────────────
  // ── Attrezzatura prompt (popup lite dopo creazione arnia) ────────────────
  @override String get attrezzaturaPromptTitle => 'Registrare come attrezzatura?';
  @override String get attrezzaturaPromptBody => 'Vuoi tracciare questo elemento nel tuo inventario attrezzature?';
  @override String get attrezzaturaPromptNome => 'Nome';
  @override String get attrezzaturaPromptCondizione => 'Condizione';
  @override String get attrezzaturaPromptPrezzo => 'Prezzo acquisto (opzionale)';
  @override String get attrezzaturaPromptSkip => 'Non chiedere più';
  @override String get attrezzaturaPromptBtnNo => 'No grazie';
  @override String get attrezzaturaPromptBtnYes => 'Registra';
  @override String get attrezzaturaPromptSuccess => 'Attrezzatura registrata!';
  @override String attrezzaturaPromptError(String e) => 'Errore registrazione: $e';

  @override String get manutenzioneFormTitle => 'Nuova Manutenzione';
  @override String get manutenzioneFormLblAttrezzatura => 'Attrezzatura';
  @override String get manutenzioneFormLblTipo => 'Tipo Manutenzione *';
  @override String get manutenzioneFormHintDescrizione => 'Es: Sostituzione parti usurate, Pulizia generale...';
  @override String get manutenzioneFormValidateDescrizione => 'Inserisci una descrizione';
  @override String get manutenzioneFormLblDataProgrammata => 'Data Programmata *';
  @override String get manutenzioneFormHintSelezionaData => 'Seleziona data';
  @override String get manutenzioneFormLblDataEsecuzione => 'Data Esecuzione';
  @override String get manutenzioneFormLblDataEsecuzioneReq => 'Data Esecuzione *';
  @override String get manutenzioneFormLblCosto => 'Costo (€)';
  @override String get manutenzioneFormHelperCosto => 'Se inserisci un costo, verrà creato automaticamente un pagamento';
  @override String get manutenzioneFormLblEseguitoDa => 'Eseguito da';
  @override String get manutenzioneFormHintEseguitoDa => 'Nome di chi ha eseguito la manutenzione';
  @override String get manutenzioneFormLblProssimaManutenzione => 'Prossima Manutenzione';
  @override String get manutenzioneFormHintNonProgrammata => 'Non programmata';
  @override String get manutenzioneFormLblNote => 'Note (opzionale)';
  @override String get manutenzioneFormInfoPagamento => 'Verrà creato automaticamente un pagamento e una spesa per questa manutenzione.';
  @override String get manutenzioneFormInfoCondivisa => 'Questa manutenzione sarà condivisa con il gruppo.';
  @override String get manutenzioneFormBtnProgramma => 'PROGRAMMA MANUTENZIONE';
  @override String get manutenzioneFormBtnRegistra => 'REGISTRA MANUTENZIONE';
  @override String get manutenzioneFormCreatedOk => 'Manutenzione registrata con successo';
  @override String get manutenzioneFormValidateDataProgrammata => 'Seleziona la data programmata';
  @override String get manutenzioneFormValidateDataEsecuzione => 'Seleziona la data di esecuzione';
  @override String get manutenzioneFormTipoOrdinaria => 'Manutenzione Ordinaria';
  @override String get manutenzioneFormTipoStraordinaria => 'Manutenzione Straordinaria';
  @override String get manutenzioneFormTipoRiparazione => 'Riparazione';
  @override String get manutenzioneFormTipoPulizia => 'Pulizia';
  @override String get manutenzioneFormTipoRevisione => 'Revisione';
  @override String get manutenzioneFormTipoSostituzioneParti => 'Sostituzione Parti';
  @override String get manutenzioneFormStatoProgrammata => 'Programmata';
  @override String get manutenzioneFormStatoInCorso => 'In Corso';
  @override String get manutenzioneFormStatoCompletata => 'Completata';
  @override String get manutenzioneFormStatoAnnullata => 'Annullata';

  // ── Spesa attrezzatura form ───────────────────────────────────────────────
  @override String get spesaAttrezzaturaFormTitle => 'Nuova Spesa';
  @override String get spesaAttrezzaturaFormLblTipo => 'Tipo Spesa *';
  @override String get spesaAttrezzaturaFormLblImporto => 'Importo (€) *';
  @override String get spesaAttrezzaturaFormValidateImporto => 'Inserisci l\'importo';
  @override String get spesaAttrezzaturaFormLblData => 'Data';
  @override String get spesaAttrezzaturaFormLblFornitore => 'Fornitore';
  @override String get spesaAttrezzaturaFormHintFornitore => 'Es: Nome fornitore';
  @override String get spesaAttrezzaturaFormLblNumFattura => 'Numero Fattura';
  @override String get spesaAttrezzaturaFormHintNumFattura => 'Es: FT-2024-001';
  @override String get spesaAttrezzaturaFormInfoPagamento => 'Verrà creato automaticamente un pagamento per questa spesa.';
  @override String get spesaAttrezzaturaFormInfoCondivisa => 'Questa spesa sarà condivisa con il gruppo.';
  @override String get spesaAttrezzaturaFormBtnSave => 'REGISTRA SPESA';
  @override String get spesaAttrezzaturaFormCreatedOk => 'Spesa registrata e pagamento creato automaticamente';
  @override String get spesaAttrezzaturaFormTipoAcquisto => 'Acquisto';
  @override String get spesaAttrezzaturaFormTipoManutenzione => 'Manutenzione';
  @override String get spesaAttrezzaturaFormTipoRiparazione => 'Riparazione';
  @override String get spesaAttrezzaturaFormTipoAccessori => 'Accessori';
  @override String get spesaAttrezzaturaFormTipoConsumabili => 'Consumabili';
  @override String get spesaAttrezzaturaFormTipoAltro => 'Altro';

  // ── Vendita form / detail ─────────────────────────────────────────────────
  @override String get venditaFormTitleNew => 'Nuova Vendita';
  @override String get venditaFormTitleEdit => 'Modifica Vendita';
  @override String get venditaFormLblAcquirente => 'Acquirente';
  @override String get venditaFormBtnUsaClienteReg => 'Usa cliente registrato';
  @override String get venditaFormBtnNomeLibero => 'Nome libero';
  @override String get venditaFormLblClienteReg => 'Cliente registrato';
  @override String get venditaFormHintNessuno => '— nessuno —';
  @override String get venditaFormLblAcquirenteNome => 'Nome acquirente *';
  @override String get venditaFormValidateNome => 'Inserisci il nome';
  @override String get venditaFormValidateAcquirente => 'Inserisci il nome dell\'acquirente';
  @override String get venditaFormLblData => 'Data *';
  @override String get venditaFormSectionCanale => 'Canale di vendita';
  @override String get venditaFormSectionPagamento => 'Metodo di pagamento';
  @override String get venditaFormSectionArticoli => 'Articoli';
  @override String get venditaFormBtnAddArticolo => 'Aggiungi articolo';
  @override String venditaFormTotale(String amount) => 'Totale: $amount €';
  @override String get venditaFormLblCondividi => 'Condividi con gruppo';
  @override String get venditaFormHintSoloPersonale => '— solo personale —';
  @override String get venditaFormCreatedOk => 'Vendita registrata';
  @override String get venditaFormUpdatedOk => 'Vendita aggiornata';
  @override String venditaFormArticoloLabel(int n) => 'Articolo $n';
  @override String get venditaFormLblTipoMiele => 'Tipo miele *';
  @override String get venditaFormValidateRequired => 'Obbligatorio';
  @override String get venditaFormLblFormatoVasetto => 'Formato vasetto';
  @override String get venditaFormLblQty => 'Qty *';
  @override String get venditaFormLblPrezzo => 'Prezzo € *';
  @override String venditaFormSubtotale(String amount) => 'Subtotale: $amount €';
  @override String get venditaCanaleMercatino => 'Mercatino';
  @override String get venditaCanaleNegozio => 'Negozio';
  @override String get venditaCanalePrivato => 'Privato';
  @override String get venditaCanaleOnline => 'Online';
  @override String get venditaCanaleAltro => 'Altro';
  @override String get venditaPagamentoContanti => 'Contanti';
  @override String get venditaPagamentoBonifico => 'Bonifico';
  @override String get venditaPagamentoCarta => 'Carta';
  @override String get venditaPagamentoAltro => 'Altro';
  @override String get venditaCatMiele => 'Miele';
  @override String get venditaCatPropoli => 'Propoli';
  @override String get venditaCatCera => 'Cera';
  @override String get venditaCatPolline => 'Polline';
  @override String get venditaCatPappaReale => 'Pappa reale';
  @override String get venditaCatNucleo => 'Nucleo';
  @override String get venditaCatRegina => 'Regina';
  @override String get venditaCatAltro => 'Altro';
  @override String get venditaDetailTitle => 'Dettaglio Vendita';
  @override String get venditaDetailNotFound => 'Vendita non trovata';
  @override String get venditaDetailOfflineMsg => 'Modalità offline — dati aggiornati all\'ultimo accesso';
  @override String get venditaDetailDeleteTitle => 'Conferma eliminazione';
  @override String get venditaDetailDeleteMsg => 'Eliminare questa vendita?';
  @override String get venditaDetailDeletedOk => 'Vendita eliminata';
  @override String get venditaDetailLblData => 'Data';
  @override String get venditaDetailLblAcquirente => 'Acquirente';
  @override String get venditaDetailLblCanale => 'Canale';
  @override String get venditaDetailLblPagamento => 'Pagamento';
  @override String get venditaDetailSectionArticoli => 'Articoli';

  // ── Cliente form ──────────────────────────────────────────────────────────
  @override String get clienteFormTitleNew => 'Nuovo Cliente';
  @override String get clienteFormTitleEdit => 'Modifica Cliente';
  @override String get clienteFormDeleteTitle => 'Conferma eliminazione';
  @override String get clienteFormDeleteMsg => 'Eliminare questo cliente?';
  @override String get clienteFormDeletedOk => 'Cliente eliminato';
  @override String get clienteFormLblNome => 'Nome *';
  @override String get clienteFormLblTelefono => 'Telefono';
  @override String get clienteFormLblEmail => 'Email';
  @override String get clienteFormLblIndirizzo => 'Indirizzo';
  @override String get clienteFormLblNote => 'Note';
  @override String get clienteFormLblCondividi => 'Condividi con gruppo';
  @override String get clienteFormHintSoloPersonale => '— solo personale —';
  @override String get clienteFormBtnCreate => 'CREA CLIENTE';
  @override String get clienteFormBtnUpdate => 'AGGIORNA';
  @override String get clienteFormCreatedOk => 'Cliente creato';
  @override String get clienteFormUpdatedOk => 'Cliente aggiornato';

  // ── Gruppo form ───────────────────────────────────────────────────────────
  @override String get gruppoFormTitleNew => 'Nuovo Gruppo';
  @override String get gruppoFormTitleEdit => 'Modifica Gruppo';
  @override String get gruppoFormCreatedOk => 'Gruppo creato con successo';
  @override String get gruppoFormUpdatedOk => 'Gruppo aggiornato con successo';
  @override String get gruppoFormSectionInfo => 'Informazioni sul gruppo';
  @override String get gruppoFormSubtitleNew => 'Crea un nuovo gruppo per collaborare con altri apicoltori. Potrai invitare membri e condividere apiari.';
  @override String get gruppoFormSubtitleEdit => 'Modifica le informazioni del gruppo esistente.';
  @override String get gruppoFormLblNome => 'Nome del gruppo *';
  @override String get gruppoFormHintNome => 'Es. Apicoltura Toscana';
  @override String get gruppoFormHintDescrizione => 'Es. Gruppo per la gestione degli apiari in Toscana';
  @override String get gruppoFormBtnCrea => 'CREA GRUPPO';
  @override String get gruppoFormBtnSalva => 'SALVA MODIFICHE';

  // ── Gruppo invito screen ──────────────────────────────────────────────────
  @override String get gruppoInvitoTitle => 'Invita al gruppo';
  @override String get gruppoInvitoNotFound => 'Gruppo non trovato';
  @override String gruppoInvitoHeader(String nome) => 'Invita al gruppo: $nome';
  @override String get gruppoInvitoSubtitle => 'Inserisci l\'indirizzo email della persona che vuoi invitare.';
  @override String get gruppoInvitoLblEmail => 'Email *';
  @override String get gruppoInvitoHintEmail => 'Inserisci indirizzo email';
  @override String get gruppoInvitoLblRuolo => 'Ruolo del nuovo membro:';
  @override String get gruppoInvitoRuoloAdmin => 'Amministratore';
  @override String get gruppoInvitoRuoloAdminDesc => 'Può gestire membri, inviti e modificare il gruppo';
  @override String get gruppoInvitoRuoloEditor => 'Editor';
  @override String get gruppoInvitoRuoloEditorDesc => 'Può modificare dati ma non gestire membri';
  @override String get gruppoInvitoRuoloViewer => 'Visualizzatore';
  @override String get gruppoInvitoRuoloViewerDesc => 'Può solo visualizzare dati senza modificarli';
  @override String get gruppoInvitoBtnSend => 'INVIA INVITO';
  @override String get gruppoInvitoInfo => 'L\'invito rimarrà valido per 7 giorni. La persona dovrà avere un account per accettarlo.';
  @override String get gruppoInvitoSentOk => 'Invito inviato con successo';

  // ── Gruppo detail screen ──────────────────────────────────────────────────
  @override String get gruppoDetailDefaultTitle => 'Dettaglio Gruppo';
  @override String get gruppoDetailNotFound => 'Gruppo non trovato';
  @override String get gruppoDetailTabMembri => 'Membri';
  @override String get gruppoDetailTabApiari => 'Apiari';
  @override String get gruppoDetailTabInviti => 'Inviti';
  @override String get gruppoDetailTooltipInvita => 'Invita membro';
  @override String get gruppoDetailTooltipModifica => 'Modifica gruppo';
  @override String get gruppoDetailBtnElimina => 'ELIMINA GRUPPO';
  @override String get gruppoDetailBtnLascia => 'LASCIA GRUPPO';
  @override String get gruppoDetailNoMembri => 'Nessun membro trovato';
  @override String get gruppoDetailRuoloAdmin => 'Amministratore';
  @override String get gruppoDetailRuoloEditor => 'Editor';
  @override String get gruppoDetailRuoloViewer => 'Visualizzatore';
  @override String get gruppoDetailRuoloCreatore => 'Creatore';
  @override String get gruppoDetailCambiaRuoloTitle => 'Cambia ruolo';
  @override String get gruppoDetailRuoloAdminDesc => 'Può gestire membri e inviti';
  @override String get gruppoDetailRuoloEditorDesc => 'Può modificare dati';
  @override String get gruppoDetailRuoloViewerDesc => 'Solo lettura';
  @override String get gruppoDetailRuoloUpdated => 'Ruolo aggiornato';
  @override String get gruppoDetailRimuoviTitle => 'Rimuovi membro';
  @override String gruppoDetailRimuoviMsg(String username) => 'Sei sicuro di voler rimuovere $username dal gruppo?';
  @override String get gruppoDetailRimuoviBtnConfirm => 'RIMUOVI';
  @override String gruppoDetailRimosso(String username) => '$username rimosso dal gruppo';
  @override String get gruppoDetailEliminaTitle => 'Elimina gruppo';
  @override String get gruppoDetailEliminaMsg => 'Sei sicuro di voler eliminare questo gruppo? Questa azione non può essere annullata.';
  @override String get gruppoDetailEliminato => 'Gruppo eliminato';
  @override String get gruppoDetailLasciaTitle => 'Lascia gruppo';
  @override String gruppoDetailLasciaMsg(String nome) => 'Sei sicuro di voler lasciare il gruppo "$nome"?';
  @override String get gruppoDetailLasciaBtnConfirm => 'LASCIA';
  @override String get gruppoDetailLasciato => 'Hai lasciato il gruppo';
  @override String get gruppoDetailNoApiariCondivisi => 'Nessun apiario condiviso con questo gruppo';
  @override String get gruppoDetailNoInviti => 'Nessun invito in sospeso';
  @override String get gruppoDetailBtnInvitaMembro => 'Invita membro';
  @override String get gruppoDetailInvitoRuoloLbl => 'Ruolo:';
  @override String get gruppoDetailInvitoScadeLbl => 'Scade:';
  @override String get gruppoDetailTooltipAnnullaInvito => 'Annulla invito';
  @override String get gruppoDetailAnnullaInvitoTitle => 'Annulla invito';
  @override String gruppoDetailAnnullaInvitoMsg(String email) => 'Annullare l\'invito per $email?';
  @override String get gruppoDetailAnnullaBtnConfirm => 'ANNULLA INVITO';
  @override String get gruppoDetailInvitoAnnullato => 'Invito annullato';
  @override String get gruppoDetailApiarioProprietario => 'Proprietario:';
  @override String get gruppoDetailApiarioNoPos => 'Posizione non specificata';
  @override String get gruppoDetailImpossibileTrovareProf => 'Impossibile trovare il tuo profilo nel gruppo';
  @override String get gruppoDetailImmagineAggiornata => 'Immagine gruppo aggiornata';
  @override String get gruppoDetailDataLoadError => 'Errore nel caricamento dei dati';
  @override String get gruppoDetailPopupCambiaRuolo => 'Cambia ruolo';
  @override String get gruppoDetailPopupRimuovi => 'Rimuovi dal gruppo';
  @override String get gruppoDetailMembroNonValido => 'Membro non valido';

  // ── Cantina screen ──
  @override String get cantinaTitle => 'Cantina 🍯';
  @override String get cantinaBtnNuovoMaturatore => 'Nuovo maturatore';
  @override String get cantinaInMaturazione => 'In maturazione';
  @override String get cantinaStoccati => 'Stoccati';
  @override String get cantinaVasetti => 'Vasetti';
  @override String get cantinaSectionMaturatori => '🥛 Maturatori';
  @override String cantinaAttiviLabel(int n) => '$n attivi';
  @override String get cantinaNoMaturatori => 'Nessun maturatore attivo.\nAggiungi uno dopo una smielatura.';
  @override String get cantinaSectionStoccaggio => '🪣 Stoccaggio';
  @override String cantinaContenitoriLabel(int n) => '$n contenitori';
  @override String get cantinaNoContenitori => 'Nessun contenitore con miele.\nTrasferisci da un maturatore.';
  @override String get cantinaSectionInvasettato => '🫙 Invasettato';
  @override String cantinaVasettiLabel(int n) => '$n vasetti';
  @override String get cantinaNoVasetti => 'Nessun vasetto registrato.\nInvasetta da un contenitore.';
  @override String cantinaDeleteMaturatoreMsg(String nome) => 'Eliminare il maturatore "$nome"?';
  @override String cantinaDeleteContenitoreMsg(String nome) => 'Eliminare il contenitore "$nome"?';
  @override String get cantinaVenditaErrVasetti => 'Vendita salvata ma errore aggiornamento vasetti';

  // ── Aggiungi maturatore sheet ──
  @override String get aggiungiMaturatoreTitleNew => 'Nuovo Maturatore';
  @override String get aggiungiMaturatoreTitleEdit => 'Modifica Maturatore';
  @override String get aggiungiMaturatoreHintNome => 'Nome (es. Maturatore 200L)';
  @override String get aggiungiMaturatoreLblTipoMiele => 'Tipo miele';
  @override String get aggiungiMaturatoreLblCapacita => 'Capacità (kg)';
  @override String get aggiungiMaturatoreLblKgAttuali => 'Kg attuali';
  @override String get aggiungiMaturatoreLblGiorniMaturazione => 'Giorni maturazione';
  @override String get aggiungiMaturatoreHelperGiorni => 'Auto da tipo miele';
  @override String get aggiungiMaturatoreLblDataInizio => 'Data inizio';

  // ── Trasferisci sheet ──
  @override String trasferisciTitle(String nome) => 'Trasferisci da "$nome"';
  @override String trasferisciErrSupera(String tot, String disp) => 'Totale (${tot}kg) supera il disponibile (${disp}kg)';
  @override String get trasferisciNoContenitori => 'Nessun contenitore aggiunto';
  @override String get trasferisciBtnAggiungiContenitore => 'Aggiungi contenitore';
  @override String get trasferisciBtnConferma => 'Conferma trasferimento';
  @override String get trasferisciLblTipo => 'Tipo';
  @override String get trasferisciLblKg => 'Kg';
  @override String trasferisciKgAssegnati(String tot, String disp) => '$tot / $disp kg assegnati';
  @override String trasferisciKgDisponibili(String n) => '$n kg disponibili';

  // ── Invasetta sheet ──
  @override String invasettaTitle(String nome) => 'Invasetta da "$nome"';
  @override String get invasettaLblFormato => 'Formato vasetto';
  @override String get invasettaLblNumeroVasetti => 'Numero vasetti:';
  @override String get invasettaBtnMax => 'Max';
  @override String invasettaKgUsati(int n, int formato, String kg) => '$n × ${formato}g = $kg kg usati';
  @override String invasettaRimangono(String kg) => 'Rimangono: $kg kg';
  @override String get invasettaLblLotto => 'Lotto (opzionale)';
  @override String invasettaBtnConferma(int n) => 'Invasetta $n vasett${n == 1 ? "o" : "i"}';

  // ── Maturatore card ──
  @override String get maturatoreCardBtnTrasferisci => 'Trasferisci in contenitori';
  @override String get maturatoreCardProntoOggi => 'Pronto oggi';
  @override String maturatoreCardProntoTra(int n) => 'Pronto tra $n giorn${n == 1 ? "o" : "i"}';
  @override String get maturatoreCardBtnTrasferisciOra => 'Trasferisci ora';
  @override String get maturatoreCardStatoPronto => '✅ Pronto';

  // ── Contenitore card ──
  @override String get contenitoreCardBtnInvasetta => '🫙 Invasetta';

  // ── Lotto vasetti section ──
  @override String lottoVasettiCount(int n) => '$n vasetti';
  @override String lottoVasettiDisponibili(int n) => '$n disp.';
  @override String lottoVasettiiBtnVendi(int n) => 'Vendi $n vasett${n == 1 ? "o" : "i"}';

  // ── Controllo form ──
  @override String get controlloFormTitleNew => 'Nuovo Controllo';
  @override String get controlloFormTitleEdit => 'Modifica Controllo';
  @override String get controlloFormTitleLoading => 'Controllo Arnia';
  @override String controlloFormArniaLabel(int numero) => 'Arnia $numero';
  @override String controlloFormNucleoLabel(int numero) => 'Nucleo $numero';
  @override String get controlloFormBtnSalva => 'SALVA';
  @override String get controlloFormBtnAggiorna => 'AGGIORNA';
  @override String get controlloFormSectionData => 'Data Controllo';
  @override String get controlloFormLblData => 'Data';
  @override String get controlloFormSectionTelaini => 'Configurazione Telaini';
  @override String get controlloFormTelainiCovata => 'Covata';
  @override String get controlloFormTelainiScorte => 'Scorte';
  @override String get controlloFormTelainiFoglioCereo => 'F. Cereo';
  @override String get controlloFormTelainiDiaframma => 'Diaframma';
  @override String get controlloFormTelainiNutritore => 'Nutritore';
  @override String get controlloFormTelainiVuoto => 'Vuoto';
  @override String get controlloFormAutoOrdina => 'Auto-ordina';
  @override String get controlloFormPreCaricato => 'Pre-caricato dall\'ultimo controllo';
  @override String get controlloFormToccaTelaino => 'Tocca un telaino per cambiare il tipo';
  @override String get controlloFormSectionRegina => 'Regina';
  @override String get controlloFormLblStatoRegina => 'Stato regina';
  @override String get controlloFormReginaAssente => 'Assente';
  @override String get controlloFormReginaPresente => 'Presente';
  @override String get controlloFormReginaVista => 'Vista';
  @override String get controlloFormUovaFresche => 'Uova fresche';
  @override String get controlloFormUovaFrescheDesc => 'Sono state viste uova fresche';
  @override String get controlloFormCelleReali => 'Celle reali';
  @override String get controlloFormCelleRealiDesc => 'Sono presenti celle reali';
  @override String get controlloFormLblNumeroCelleReali => 'Numero celle reali';
  @override String get controlloFormReginaSostituita => 'Regina sostituita';
  @override String get controlloFormReginaSostituitaDesc => 'La regina è stata sostituita durante questo controllo';
  @override String get controlloFormReginaColorata => 'Regina colorata';
  @override String get controlloFormReginaColorataDesc => 'La regina è stata colorata/marcata in questo controllo';
  @override String get controlloFormColoreRegina => 'Colore marcatura';
  @override String get controlloFormSectionSciamatura => 'Sciamatura';
  @override String get controlloFormSciamatura => 'Sciamatura rilevata';
  @override String get controlloFormSciamaturaCodice => 'La colonia ha sciamato';
  @override String get controlloFormNoteSciamatura => 'Note sciamatura';
  @override String get controlloFormSectionProblemi => 'Problemi Sanitari';
  @override String get controlloFormProblemi => 'Problemi sanitari rilevati';
  @override String get controlloFormProblemiDesc => 'Sono stati rilevati problemi sanitari';
  @override String get controlloFormDettagliProblemi => 'Dettagli problemi sanitari';
  @override String get controlloFormValidateProblemi => 'Inserisci i dettagli sui problemi sanitari';
  @override String get controlloFormSectionNote => 'Note Generali';
  @override String get controlloFormLblNote => 'Note';
  @override String get controlloFormHintNote => 'Inserisci eventuali note aggiuntive...';
  @override String get controlloFormOfflineMsg => 'Sei offline. Le modifiche saranno salvate localmente e sincronizzate quando sarai di nuovo online.';
  @override String get controlloFormSavedOk => 'Controllo registrato con successo';
  @override String get controlloFormSavedOffline => 'Controllo salvato localmente. Sarà sincronizzato quando tornerai online';
  @override String get controlloFormUpdatedOk => 'Controllo aggiornato con successo';
  @override String get controlloFormUpdatedOffline => 'Aggiornamento salvato localmente. Sarà sincronizzato quando tornerai online';
  @override String get controlloFormErrGeneric => 'Si è verificato un errore. Riprova più tardi.';
  @override String get controlloFormErrCaricoArnia => 'Impossibile caricare i dati dell\'arnia. Verifica la connessione.';
  @override String get controlloFormSyncOk => 'Dati sincronizzati con successo';
  @override String get controlloFormReginaAutoCreata => 'Regina rilevata: scheda base creata automaticamente. Aprila per completare i dettagli.';
  @override String controlloFormLastControllo(String data) => 'Ultimo controllo: $data';
  @override String controlloFormReginaLabel(String stato) => 'Regina: $stato';
  @override String controlloFormCovataCount(int n) => 'Covata $n';
  @override String controlloFormScorteCount(int n) => 'Scorte $n';
  @override String controlloFormDiaframmaCount(int n) => 'Diaframma $n';
  @override String controlloFormFoglioCereoCount(int n) => 'F.Cereo $n';

  // ── Pagamenti screen ──
  @override String get pagamentiTitle => 'Gestione Pagamenti';
  @override String get pagamentiTabPagamenti => 'Pagamenti';
  @override String get pagamentiTabBilancio => 'Bilancio';
  @override String get pagamentiTooltipSync => 'Sincronizza dati';
  @override String get pagamentiTooltipNuovoPagamento => 'Nuovo Pagamento';
  @override String pagamentiErrLoading(String e) => 'Errore durante il caricamento dei dati: $e';
  @override String get pagamentiEmptyTitle => 'Nessun pagamento registrato';
  @override String get pagamentiRegistraPagamento => 'Registra Pagamento';
  @override String get pagamentiLinkRapidi => 'Link Rapidi';
  @override String get pagamentiLinkAttrezzature => 'Gestione Attrezzature';
  @override String get pagamentiAttrezzatureHint => 'Le spese per attrezzature vengono registrate automaticamente nei pagamenti';
  @override String get pagamentiTooltipSaldo => 'Saldo bilancio';
  @override String get pagamentiTooltipAttrezzatura => 'Spesa attrezzatura';
  @override String get pagamentiBilancioEmptyTitle => 'Nessun bilancio disponibile';
  @override String get pagamentiBilancioEmptyHint => 'Per calcolare il bilancio servono quote assegnate ai membri del gruppo e pagamenti registrati.';
  @override String pagamentiBilancioTotale(String amount) => 'Totale spese gruppo: $amount';
  @override String get pagamentiTooltipGestisci => 'Gestisci quote';
  @override String get pagamentiQuoteLabel => 'Quote';
  @override String get pagamentiTrasferimentiNecessari => 'Trasferimenti necessari';
  @override String get pagamentiQuoteGruppo => 'Quote gruppo';
  @override String get pagamentiGestisci => 'Gestisci';
  @override String get pagamentoPagato => 'Pagato';
  @override String get pagamentoDovuto => 'Dovuto';
  @override String get pagamentoSaldo => 'Saldo';
  @override String get pagamentiTooltipRegistraSaldo => 'Registra pagamento di saldo';
  @override String pagamentiSaldoDesc(String da, String a) => 'Saldo bilancio: $da → $a';

  // ── Pagamento detail screen ──
  @override String get pagamentoDetailTitle => 'Dettaglio Pagamento';
  @override String get pagamentoDetailNotFound => 'Pagamento non trovato';
  @override String pagamentoDetailErrLoading(String e) => 'Errore durante il caricamento del pagamento: $e';
  @override String get pagamentoDetailDeleteMsg => 'Sei sicuro di voler eliminare questo pagamento?';
  @override String get pagamentoDetailDeletedOk => 'Pagamento eliminato con successo';
  @override String get pagamentoDetailErrDelete => 'Errore durante l\'eliminazione del pagamento';
  @override String get pagamentoDetailLabelDescrizione => 'Descrizione';
  @override String get pagamentoDetailLabelUtente => 'Utente';
  @override String get pagamentoDetailLabelGruppo => 'Gruppo';

  // ── Pagamento form screen ──
  @override String get pagamentoFormTitleNew => 'Nuovo Pagamento';
  @override String get pagamentoFormTitleEdit => 'Modifica Pagamento';
  @override String get pagamentoFormUpdatedOk => 'Pagamento aggiornato con successo';
  @override String get pagamentoFormCreatedOk => 'Pagamento creato con successo';
  @override String pagamentoFormErrSave(String e) => 'Errore durante il salvataggio del pagamento: $e';
  @override String get pagamentoFormLabelImporto => 'Importo (€)';
  @override String get pagamentoFormValidImportoRequired => 'Inserisci l\'importo';
  @override String get pagamentoFormValidImportoInvalid => 'Inserisci un importo valido';
  @override String get pagamentoFormValidDescRequired => 'Inserisci una descrizione';
  @override String get pagamentoFormLabelGruppo => 'Gruppo (opzionale)';
  @override String get pagamentoFormNoGruppo => 'Nessun gruppo';
  @override String get pagamentoFormLabelChiPaga => 'Chi ha pagato?';
  @override String get pagamentoFormIoStesso => '— io stesso —';
  @override String get pagamentoFormHelperChiPaga => 'Indica il membro che ha effettivamente sostenuto la spesa';
  @override String get pagamentoFormSaldoTitle => 'Pagamento di saldo';
  @override String get pagamentoFormSaldoSubtitle => 'Denaro trasferito direttamente tra due membri per saldare il bilancio';
  @override String get pagamentoFormLabelDestinatario => 'A chi? (destinatario)';
  @override String get pagamentoFormHelperDestinatario => 'Membro che riceve il denaro';
  @override String get pagamentoFormValidDestinatarioRequired => 'Seleziona il destinatario';

  // ── Quote screen ──
  @override String get quoteTitle => 'Gestione Quote';
  @override String quoteErrLoading(String e) => 'Errore durante il caricamento delle quote: $e';
  @override String get quoteUpdatedOk => 'Quota aggiornata con successo';
  @override String quoteErrUpdate(String e) => 'Errore durante l\'aggiornamento della quota: $e';
  @override String get quoteEditTitle => 'Modifica quota';
  @override String quoteEditMsg(String username) => 'Modifica la percentuale per $username';
  @override String get quoteLabelPercentuale => 'Percentuale';
  @override String get quoteValidPercRequired => 'Inserisci una percentuale';
  @override String get quoteValidPercInvalid => 'Inserisci una percentuale valida';
  @override String get quoteDeleteMsg => 'Sei sicuro di voler eliminare questa quota?';
  @override String get quoteDeletedOk => 'Quota eliminata con successo';
  @override String get quoteErrDelete => 'Errore durante l\'eliminazione della quota';
  @override String quoteErrDeleteE(String e) => 'Errore durante l\'eliminazione della quota: $e';
  @override String get quoteAddNoGruppo => 'Seleziona un gruppo prima di aggiungere una quota';
  @override String get quoteAddedOk => 'Quota aggiunta con successo';
  @override String quoteErrAdd(String e) => 'Errore durante l\'aggiunta della quota: $e';
  @override String get quoteAddTitle => 'Aggiungi quota';
  @override String get quoteLabelIdUtente => 'ID Utente';
  @override String get quoteValidIdRequired => 'Inserisci l\'ID utente';
  @override String get quoteValidIdInvalid => 'ID utente non valido';
  @override String get quoteValidPercRange => 'La percentuale deve essere tra 0 e 100';
  @override String get quoteLabelFiltroGruppo => 'Filtra per gruppo';
  @override String get quoteTuttiGruppi => 'Tutti i gruppi';
  @override String get quoteTooltipAdd => 'Aggiungi Quota';
  @override String get quoteEmptyTitle => 'Nessuna quota trovata';

  // ── Statistiche screen ──
  @override String get statisticheTitle => 'Statistiche';
  @override String get statisticheTabDashboard => 'Dashboard';
  @override String get statisticheTabAnalisi => 'Analisi';
  @override String get statisticheTabChiediAI => 'Chiedi AI';

  // ── Dashboard card base ──
  @override String get dashboardErrCaricamento => 'Errore caricamento dati';

  // ── Dashboard widget titles ──
  @override String get dashboardTitleProduzione => 'Produzione Miele per Anno';
  @override String get dashboardTitleSaluteArnie => 'Salute degli Alveari';
  @override String get dashboardTitleRegineStats => 'Regine — Statistiche';
  @override String get dashboardTitleFrequenzaControlli => 'Frequenza Controlli';
  @override String get dashboardTitleFioritureVicine => 'Fioriture Vicine';
  @override String get dashboardTitleAttrezzature => 'Riepilogo Attrezzature';
  @override String get dashboardTitleProduzionePerTipo => 'Produzione per Tipo di Miele';
  @override String get dashboardTitleTrattamenti => 'Trattamenti Sanitari nel Tempo';
  @override String get dashboardTitleAndamentoScorte => 'Andamento Scorte';
  @override String get dashboardTitlePerformanceRegine => 'Performance Regine';
  @override String get dashboardTitleQuoteGruppo => 'Quote Gruppo';
  @override String dashboardTitleBilancio(int anno) => 'Bilancio $anno';

  // ── Salute arnie widget ──
  @override String get dashboardSaluteNoArnie => 'Nessuna arnia trovata';
  @override String get dashboardSaluteOttima => 'Ottima';
  @override String get dashboardSaluteAttenzione => 'Attenzione';
  @override String get dashboardSaluteCritica => 'Critica';
  @override String dashboardSaluteTotale(int n) => 'Totale: $n arnie';
  @override String dashboardSaluteCritiche(String list) => 'Critiche: $list';

  // ── Regine statistiche widget ──
  @override String get dashboardRegineAttive => 'Regine attive';
  @override String get dashboardRegineSostituzioni => 'Sostituzioni';
  @override String get dashboardRegineVitaMedia => 'Vita media';
  @override String dashboardRegineVitaMesiStr(String durata) => '$durata mesi';
  @override String get dashboardRegineMotiviSostituzione => 'Motivi sostituzione:';

  // ── Performance regine widget ──
  @override String get dashboardPerformanceNoRegine => 'Nessuna regina con valutazione';
  @override String get dashboardPerformanceHdrRegina => 'Regina';
  @override String get dashboardPerformanceHdrProd => 'Prod.';
  @override String get dashboardPerformanceHdrDoc => 'Doc.';
  @override String get dashboardPerformanceHdrResist => 'Resist.';
  @override String get dashboardPerformanceHdrSc => 'Sc.';

  // ── Bilancio widget ──
  @override String get dashboardBilancioSaldoAnnuale => 'Saldo annuale: ';
  @override String get dashboardBilancioEntrate => 'Entrate';
  @override String get dashboardBilancioUscite => 'Uscite';

  // ── Frequenza controlli widget ──
  @override String get dashboardFrequenzaMedia => 'Media giorni tra controlli';
  @override String dashboardFrequenzaGiorni(int n) => '$n giorni';
  @override String get dashboardFrequenzaDettaglio => 'Dettaglio per arnia:';

  // ── Fioriture vicine widget ──
  @override String get dashboardFioritureNessuna => 'Nessuna fioritura nel raggio di 5 km';

  // ── Attrezzature widget ──
  @override String get dashboardAttrezzatureNessuna => 'Nessuna attrezzatura registrata';
  @override String get dashboardAttrezzatureCategoria => 'Categoria';
  @override String get dashboardAttrezzatureNumero => 'N°';
  @override String get dashboardAttrezzatureValore => 'Valore';
  @override String get dashboardAttrezzatureInventario => 'Inventario totale';

  // ── Varroa trend widget ──
  @override String get dashboardVarroaNessuno => 'Nessun trattamento nel periodo';

  // ── Andamento scorte widget ──
  @override String get dashboardScorteNessuno => 'Nessun dato scorte disponibile';

  // ── Produzione tipo widget ──
  @override String get dashboardProdTipoNessuno => 'Nessuna smielatura registrata';
  @override String dashboardProdTipoTotale(String kg) => 'Totale: $kg kg';

  // ── Quote gruppo widget ──
  @override String get dashboardQuoteGruppoSoloCoord => 'Visibile solo ai coordinatori di gruppo';

  // ── NL Query tab ──
  @override String get nlQuerySuggerite => 'Domande suggerite:';
  @override String get nlQuerySuggerimento1 => 'Quali arnie non controllo da 30 giorni?';
  @override String get nlQuerySuggerimento2 => 'Quando ho prodotto più miele?';
  @override String get nlQuerySuggerimento3 => 'Quali regine hanno la valutazione più alta?';
  @override String get nlQuerySuggerimento4 => 'Quanti controlli ho fatto quest\'anno?';
  @override String get nlQuerySuggerimento5 => 'Qual è il mio bilancio di quest\'anno?';
  @override String get nlQuerySuggerimento6 => 'Quali trattamenti ho fatto?';
  @override String get nlQueryPensando => 'AI sta pensando…';
  @override String get nlQueryRispostaAI => 'Risposta AI';
  @override String nlQueryRisultati(int n) => '$n risultati';
  @override String get nlQueryErrLento => 'Il server AI è lento, riprova tra poco';
  @override String get nlQueryErrRifiuto => 'Non posso rispondere a questa domanda';
  @override String get nlQueryErrGenerico => 'Errore: si prega di riprovare';
  @override String get nlQueryInputHint => 'Fai una domanda sui tuoi dati…';

  // ── Risultato query widget ──
  @override String nlQueryRighe(int n) => '$n righe';
  @override String get risultatoNessunDato => 'Nessun dato disponibile';
  @override String get risultatoNessunRisultato => 'Nessun risultato';

  // ── Export bottom sheet ──
  @override String get exportTitle => 'Esporta dati';
  @override String get exportExcel => 'Excel';
  @override String get exportPdf => 'PDF';
  @override String get exportExcelSalvato => 'File Excel salvato';
  @override String exportErrExcel(String e) => 'Errore export Excel: $e';
  @override String get exportPdfSalvato => 'File PDF salvato';
  @override String exportErrPdf(String e) => 'Errore export PDF: $e';

  // ── Query builder tab ──
  @override String get queryBuilderEseguiAnalisi => 'Esegui analisi';
  @override String get queryBuilderAvanti => 'Avanti';
  @override String get queryBuilderIndietro => 'Indietro';
  @override String get queryBuilderStepAnalizzare => 'Cosa analizzare?';
  @override String get queryBuilderStepFiltri => 'Filtri e aggregazione';
  @override String get queryBuilderStepRisultati => 'Risultati';
  @override String get queryBuilderEntitaControlli => 'Controlli arnie';
  @override String get queryBuilderEntitaSmielature => 'Smielature';
  @override String get queryBuilderEntitaRegine => 'Regine';
  @override String get queryBuilderEntitaVendite => 'Vendite';
  @override String get queryBuilderEntitaSpese => 'Spese';
  @override String get queryBuilderEntitaFioriture => 'Fioriture';
  @override String get queryBuilderEntitaArnie => 'Arnie';
  @override String get queryBuilderDataDa => 'Data da';
  @override String get queryBuilderDataA => 'Data a';
  @override String get queryBuilderAggregazione => 'Aggregazione';
  @override String get queryBuilderAggCount => 'Conteggio';
  @override String get queryBuilderAggSum => 'Somma';
  @override String get queryBuilderAggAvg => 'Media';
  @override String get queryBuilderAggNone => 'Nessuna (tabella)';
  @override String get queryBuilderRaggruppaPer => 'Raggruppa per';
  @override String get queryBuilderRaggruppaMese => 'Mese';
  @override String get queryBuilderRagruppaAnno => 'Anno';
  @override String queryBuilderErrore(String e) => 'Errore: $e';
  @override String get queryBuilderRunFirst => 'Esegui l\'analisi per vedere i risultati';
  @override String get queryBuilderVizBarre => 'Barre';
  @override String get queryBuilderVizLinea => 'Linea';
  @override String get queryBuilderVizTabella => 'Tabella';

  // ── Voice transcript review screen ──
  @override String voiceReviewTitleCount(int n) => 'Revisione ($n)';
  @override String get voiceReviewBtnDeleteAll => 'Elimina tutto';
  @override String get voiceReviewDeleteAllTitle => 'Eliminare tutto?';
  @override String get voiceReviewDeleteAllMsg => 'Tutte le trascrizioni verranno rimosse dalla lista.';
  @override String get voiceReviewDeleteItemTitle => 'Elimina trascrizione?';
  @override String get voiceReviewInfoBanner => 'Trascina ≡ per riordinare, poi unisci le voci adiacenti.';
  @override String get voiceReviewEmpty => 'Nessuna trascrizione rimasta.';
  @override String get voiceReviewEmptyHint => 'Premi "Mantieni in coda" per uscire o torna indietro.';
  @override String get voiceReviewBtnKeepQueue => 'Mantieni in coda';
  @override String get voiceReviewBtnSendAI => 'Invia all\'elaborazione';
  @override String get voiceReviewProcessing => 'Elaborazione…';
  @override String get voiceReviewMerging => 'Unione in corso…';
  @override String get voiceReviewMergeWith => 'Unisci con la successiva ↓';
  @override String get voiceReviewTooltipEdit => 'Modifica';
  @override String get voiceReviewTooltipSave => 'Salva';
  @override String get voiceReviewTooltipDelete => 'Elimina';

  // ── Voice entry verification screen ──
  @override String get voiceVerifTitle => 'Verifica dati vocali';
  @override String get voiceVerifTooltipRemove => 'Rimuovi registrazione';
  @override String get voiceVerifSaving => 'Salvataggio in corso...';
  @override String get voiceVerifDeleteTitle => 'Elimina scheda';
  @override String voiceVerifDeleteMsg(String label) => 'Vuoi eliminare la scheda di $label?\n\nL\'operazione non può essere annullata.';
  @override String get voiceVerifScheda => 'questa scheda';
  @override String get voiceVerifNewArnieTitolo => 'Nuove arnie rilevate';
  @override String voiceVerifNewArnieMsg(String list) => 'Le seguenti arnie non sono presenti nel database:\n\n$list\n\nVuoi crearle nell\'apiario selezionato e salvare i controlli?';
  @override String get voiceVerifCreateSave => 'CREA E SALVA';
  @override String get voiceVerifErrCreazArnieTitolo => 'Errore creazione arnie';
  @override String voiceVerifSavedOk(int n) => 'Dati salvati con successo ($n record)';
  @override String voiceVerifPartialSaved(int saved, int remaining) => 'Salvati $saved record. $remaining non salvati:\n';
  @override String get voiceVerifNoSaved => 'Nessun record salvato:\n';
  @override String voiceVerifInvalidSkipped(String arnia) => 'Arnia $arnia: dati non validi, saltata.';
  @override String voiceVerifNotFoundCache(String arnia) => 'Arnia $arnia: non trovata in cache. Aggiorna la lista arnie e riprova.';
  @override String get voiceVerifEmptyTitle => 'Nessun dato da verificare';
  @override String get voiceVerifEmptySubtitle => 'Torna indietro e registra nuove ispezioni';
  @override String get voiceVerifBtnGoBack => 'Torna indietro';
  @override String voiceVerifRecordOf(int current, int total) => 'Record $current di $total';
  @override String get voiceVerifSectionPosizione => 'Posizione';
  @override String get voiceVerifSectionRegistrazione => 'Registrazione originale';
  @override String get voiceVerifAudioLabel => 'Audio originale — premi per ascoltare';
  @override String get voiceVerifSectionGenerali => 'Informazioni generali';
  @override String get voiceVerifLblTipo => 'Tipo';
  @override String get voiceVerifSectionRegina => 'Regina';
  @override String get voiceVerifSectionTelaini => 'Telaini';
  @override String get voiceVerifLblTotale => 'Totale';
  @override String get voiceVerifLblForzaFamiglia => 'Forza famiglia';
  @override String get voiceVerifSectionProblemi => 'Problemi';
  @override String get voiceVerifLblProblemiSanitari => 'Problemi sanitari';
  @override String get voiceVerifLblTipoProblema => 'Tipo di problema';
  @override String get voiceVerifSectionColorazione => 'Colorazione regina';
  @override String get voiceVerifLblReginaColorata => 'Regina colorata/marcata';
  @override String get voiceVerifLblColoreRegina => 'Colore marcatura';
  @override String get voiceVerifSectionNote => 'Note';
  @override String get voiceVerifLblNoteAggiuntive => 'Note aggiuntive';
  @override String get voiceVerifTooltipPrecedente => 'Precedente';
  @override String get voiceVerifTooltipSuccessivo => 'Successivo';
  @override String get voiceVerifBtnSaveAll => 'SALVA TUTTO';
  @override String get voiceVerifTooltipPausa => 'Pausa';
  @override String get voiceVerifTooltipRiproduci => 'Riproduci';
  @override String get voiceVerifTooltipStop => 'Stop';

  // ── Voice command screen ──
  @override String get voiceCommandTitle => 'Inserimento vocale';
  @override String get voiceCommandTooltipMenu => 'Menu';
  @override String get voiceCommandTooltipQueue => 'Elabora coda offline';
  @override String get voiceCommandTooltipHideGuide => 'Nascondi guida';
  @override String get voiceCommandTooltipShowTutorial => 'Rivedi tutorial';
  @override String voiceCommandDraftRestored(int n) => '$n trascrizioni recuperate dalla sessione precedente. Premi la coda per elaborarle.';
  @override String get voiceCommandUnsavedTitle => 'Dati non salvati trovati';
  @override String voiceCommandUnsavedMsg(int n) => 'Sono presenti $n schede di controllo elaborate da Gemini che non sono state salvate. Vuoi riprenderle?';
  @override String get voiceCommandBtnScarta => 'SCARTA';
  @override String get voiceCommandBtnRiprendi => 'RIPRENDI';
  @override String voiceCommandRecoveredSaved(int n) => 'Dati recuperati e salvati ($n record)';
  @override String get voiceCommandNoTranscription => 'Nessuna trascrizione da salvare';
  @override String voiceCommandSavedToQueue(int n) => 'Trascrizione salvata in coda ($n in attesa)';
  @override String get voiceCommandNoValidEntry => 'Nessuna entry valida estratta dalla coda';
  @override String get voiceCommandNoValidData => 'Nessun dato valido estratto. Controlla le trascrizioni e riprova.';
  @override String voiceCommandQueueSaved(int n) => 'Dati dalla coda salvati ($n record)';
  @override String voiceCommandSavedWithRemaining(int saved, int remaining) => 'Dati salvati ($saved record). $remaining trascrizioni in coda.';
  @override String voiceCommandSavedOk(int n) => 'Dati salvati con successo ($n record)';
  @override String get voiceCommandBtnSaveLater => 'Salva per dopo';
  @override String get voiceCommandGuideTitle => 'Come funziona l\'inserimento vocale';
  @override String get voiceCommandGuideStep1Title => 'Seleziona apiario';
  @override String get voiceCommandGuideStep1Desc => 'Tocca il banner in cima per scegliere l\'apiario. Poi basta dire solo il numero arnia.';
  @override String get voiceCommandGuideStep2Title => 'Inizia a parlare';
  @override String get voiceCommandGuideStep2Desc => 'Premi il pulsante microfono e parla chiaramente';
  @override String get voiceCommandGuideStep3Title => 'Verifica e salva';
  @override String get voiceCommandGuideStep3Desc => 'Controlla i dati riconosciuti da Gemini prima di salvarli';
  @override String get voiceCommandGuideOffline => 'Senza connessione: usa "Salva per dopo" e riprendi quando sei online.';
  @override String get voiceCommandGuideExamplesTitle => 'Esempi:';
  @override String get voiceCommandGuideKeywordsTitle => 'Parole chiave modalità multipla:';
  @override String get voiceCommandGuideKeyNextCmd => '"avanti" / "ok" / "vai" / "continua" → registra arnia successiva';
  @override String get voiceCommandGuideKeyStopCmd => '"stop" / "fine" / "basta" / "finito" → termina il batch e vai alla revisione';

  // ── Voice tutorial sheet ──
  @override String get voiceTutorialTitle => 'Inserimento vocale';
  @override String get voiceTutorialSubtitle => 'Come registrare un\'ispezione a mani libere';
  @override String get voiceTutorialStep1Title => 'Seleziona l\'apiario';
  @override String get voiceTutorialStep1Body => 'Tocca il banner arancione in cima e scegli l\'apiario su cui stai lavorando. Da quel momento basterà dire solo il numero dell\'arnia — non serve ripeterlo ogni volta.';
  @override String get voiceTutorialStep2Title => 'Parla chiaramente';
  @override String get voiceTutorialStep2Body => 'Premi il pulsante microfono e descrivi l\'ispezione come faresti con un collega. Non serve una sintassi precisa: l\'AI capisce il linguaggio naturale.';
  @override String get voiceTutorialStep3Title => 'Gemini interpreta il testo';
  @override String get voiceTutorialStep3Body => 'Il testo riconosciuto viene inviato a Gemini AI che estrae automaticamente: numero arnia, telaini, stato regina, problemi sanitari e altro ancora.';
  @override String get voiceTutorialStep4Title => 'Verifica e salva';
  @override String get voiceTutorialStep4Body => 'Controlla i dati interpretati nella schermata di verifica, modifica eventuali errori e premi Salva.';
  @override String get voiceTutorialExamplesTitle => 'Esempi di frasi';
  @override String get voiceTutorialMultiTitle => 'Modalità multipla (più arnie di seguito)';
  @override String get voiceTutorialMultiNextKeyword => '"avanti" / "ok" / "vai" / "continua"';
  @override String get voiceTutorialMultiNextDesc => 'registra l\'arnia successiva';
  @override String get voiceTutorialMultiStopKeyword => '"stop" / "fine" / "basta" / "finito"';
  @override String get voiceTutorialMultiStopDesc => 'termina il batch e vai alla revisione';
  @override String get voiceTutorialOfflineMsg => 'Senza connessione usa "Salva per dopo": le trascrizioni vengono messe in coda e puoi elaborarle non appena torni online.';
  @override String get voiceTutorialBtnStart => 'Inizia a registrare';

  // ── Common shared ──
  @override String get btnClose => 'Chiudi';

  // ── Settings screen (remaining) ──
  @override String get settingsPhotoUpdated => 'Foto profilo aggiornata';
  @override String get settingsPhotoError => 'Errore nel caricamento della foto';

  // ── Chat screen ──
  @override String get chatTooltipClear => 'Cancella conversazione';
  @override String get chatClearTitle => 'Cancellare la conversazione?';
  @override String get chatClearMsg => 'Questa azione cancellerà tutti i messaggi e non può essere annullata.';
  @override String get chatClearBtn => 'CANCELLA';
  @override String get chatInfoBanner => 'ApiarioAI ha accesso ai dati dei tuoi apiari e può generare grafici per le tue analisi.';
  @override String get chatEmpty => 'Nessun messaggio. Inizia una conversazione!\nProva a chiedere "Mostrami un grafico della popolazione dell\'arnia 3"';
  @override String get chatLoading => 'ApiarioAI sta elaborando...';
  @override String chatErrMsg(String e) => 'Errore: $e';
  @override String get chatRetrySnackbar => 'Riprovando a inviare il messaggio...';
  @override String get chatHint => 'Scrivi un messaggio...';
  @override String get chatGeneratingChart => 'Generazione grafico in corso...';

  // ── Analisi telaino list screen ──
  @override String get analisiListTitle => 'Analisi Telaini';
  @override String get analisiListTooltipNew => 'Nuova analisi';
  @override String get analisiListEmpty => 'Nessuna analisi registrata';
  @override String get analisiListBtnStart => 'Avvia Analisi';
  @override String analisiListCardTitle(int n, String side) => 'Telaino $n - Facciata $side';
  @override String analisiListTagApi(int n) => 'Api: $n';
  @override String analisiListTagRegine(int n) => 'Regine: $n';
  @override String analisiListTagFuchi(int n) => 'Fuchi: $n';
  @override String analisiListTagCelleR(int n) => 'Celle R.: $n';

  // ── Analisi telaino screen ──
  @override String get analisiTitle => 'Analisi Telaino';
  @override String analisiErrAnalysis(String e) => 'Errore durante l\'analisi: $e';
  @override String get analisiSnackSaved => 'Analisi salvata con successo';
  @override String analisiErrSave(String e) => 'Errore durante il salvataggio: $e';
  @override String get analisiConfigTitle => 'Configurazione';
  @override String get analisiLoadingControllo => 'Caricamento stato arnia...';
  @override String analisiSlotSource(String date, int count) => 'Dati dal controllo del $date ($count telaini presenti)';
  @override String get analisiNoSlot => 'Nessun controllo recente trovato – selezione manuale.';
  @override String get analisiFacciata => 'Facciata';
  @override String analisiTelainoN(int n) => 'Telaino $n';
  @override String get analisiSelectTelaino => 'Seleziona telaino';
  @override String get analisiTelainoLabel => 'Telaino n.';
  @override String get analisiAnalyzing => 'Analisi in corso...';
  @override String analisiProgressLabel(int n, String label) => 'Telaino $n – $label';
  @override String analisiSummaryTitle(int n, String side) => 'Telaino $n – Facciata $side';
  @override String get analisiCountApi => 'Api';
  @override String get analisiCountRegine => 'Regine';
  @override String get analisiCountFuchi => 'Fuchi';
  @override String get analisiCountCelleReali => 'Celle Reali';
  @override String get analisiConfidenzaMedia => 'Confidenza media: ';
  @override String get analisiNoteLbl => 'Note (opzionale)';
  @override String get analisiNoteHint => 'Aggiungi osservazioni...';
  @override String get analisiBtnRipeti => 'Ripeti';
  @override String get analisiBtnSalva => 'Salva';
  @override String get analisiBtnScattaFoto => 'Scatta Foto';
  @override String get analisiBtnGalleria => 'Scegli dalla Galleria';
  @override String get analisiDiagnostica => 'Analisi diagnostica';
  @override String analisiIdentityBadge(int n, String label) => 'Telaino $n – $label';
  @override String analisiIdentityDate(String date) => 'Tipo registrato nell\'ultimo controllo ($date)';
  @override String analisiWarnDiafammaApi(int n) => 'Api rilevate su diaframma ($n): il divisore non dovrebbe essere colonizzato.';
  @override String get analisiWarnDiafammaRegina => 'Regina rilevata sul diaframma: situazione anomala, verifica subito.';
  @override String analisiWarnDiafammaCelle(int n) => 'Celle reali sul diaframma ($n): anomalia grave, intervento necessario.';
  @override String analisiWarnDiafammaFuchi(int n) => 'Molti fuchi sul diaframma ($n): la separazione potrebbe non funzionare.';
  @override String get analisiWarnNutritoreRegina => 'Regina sul nutritore: si è spostata fuori dalla zona covata.';
  @override String analisiWarnNutritoreCelle(int n) => 'Celle reali sul nutritore ($n): la colonia potrebbe prepararsi alla sciamatura.';
  @override String analisiWarnNutritoreApi(int n) => 'Molte api sul nutritore ($n): verifica che il nutritore non ostacoli il movimento.';
  @override String analisiWarnCovataSciamaturaAlta(int n) => 'Celle reali elevate ($n): probabile preparazione alla sciamatura. Intervieni presto.';
  @override String analisiWarnCovataSciamaturaMedia(int n) => 'Celle reali presenti ($n): monitora la colonia nelle prossime settimane.';
  @override String analisiWarnCovataRegine(int n) => 'Più regine rilevate ($n): anomalia – verifica la presenza di celle reali.';
  @override String get analisiWarnCovataVuota => 'Nessuna ape su telaino covata: colonia indebolita, sciamata o cella vuota.';
  @override String analisiWarnCovataFuchi(int n) => 'Alta presenza di fuchi su covata ($n): possibile covata da fuche, colonia orfana?';
  @override String analisiWarnScorteRegina(int n) => 'Regina su telaino scorte ($n): posizione inusuale, verifica lo spazio covata.';
  @override String analisiWarnScorteCelle(int n) => 'Celle reali su telaino scorte ($n): segnale di sciamatura o rimpiazzo della regina.';
  @override String analisiWarnScorteApi(int n) => 'Alta densità api su scorte ($n): possibile accumulo pre-sciamatura.';
  @override String analisiWarnDensitaAltissima(int n) => 'Densità altissima ($n insetti): questo telaino è molto affollato.';

  // ── Mappa screen ──
  @override String get mappaTitle => 'Mappa Apiari';
  @override String get mappaOfflineTooltip => 'Modalità offline - Dati caricati dalla cache';
  @override String get mappaTooltipOsmHide => 'Nascondi vegetazione OSM';
  @override String get mappaTooltipOsmShow => 'Mostra vegetazione OSM';
  @override String get mappaTooltipRaggioHide => 'Nascondi raggio di volo';
  @override String get mappaTooltipRaggioShow => 'Mostra raggio di volo (3 km)';
  @override String get mappaTooltipNomadismo => 'Nomadismo & Flora';
  @override String get mappaTooltipSync => 'Sincronizza dati';
  @override String get mappaErrPermission => 'Permessi di localizzazione negati';
  @override String get mappaErrPermissionPermanent => 'I permessi di localizzazione sono negati permanentemente. Attivali dalle impostazioni.';
  @override String get mappaSnackSettings => 'Impostazioni';
  @override String get mappaErrServiceDisabled => 'Servizio di localizzazione disattivato. Attivalo per usare questa funzione.';
  @override String get mappaSnackActivate => 'Attiva';
  @override String get mappaErrPosition => 'Errore nel recupero della posizione';
  @override String get mappaSnackNord => 'Mappa orientata verso Nord';
  @override String mappaErrData(String e) => 'Errore durante il caricamento dei dati: $e';
  @override String get mappaSnackZoom => 'Avvicinati per vedere la vegetazione OSM (zoom ≥ 10)';
  @override String get mappaErrOsm => 'Errore nel caricamento vegetazione OSM';
  @override String get mappaStatArnie => 'Arnie';
  @override String get mappaStatApicoltore => 'Apicoltore';
  @override String get mappaStatTipo => 'Tipo';
  @override String get mappaStatCommunity => 'Community';
  @override String get mappaStatTuoGruppo => 'Tuo/Gruppo';
  @override String get mappaApprox => 'Posizione approssimata';
  @override String get mappaBtnVisualizza => 'Visualizza';
  @override String get mappaBtnApriApiario => 'Apri Apiario';
  @override String get mappaLegenda => 'Legenda';
  @override String get mappaLegendaMioApiario => 'Mio apiario';
  @override String get mappaLegendaCommunity => 'Apiario community';
  @override String get mappaLegendaGruppo => 'Apiario gruppo';
  @override String get mappaLegendaRaggio => 'Raggio volo (3 km)';
  @override String get mappaLegendaFiorituraAttiva => 'Fioritura attiva';
  @override String get mappaLegendaFiorituraInattiva => 'Fioritura inattiva';
  @override String get mappaLegendaBosco => 'Bosco / Foresta';
  @override String get mappaLegendaMacchia => 'Macchia';
  @override String get mappaLegendaPrato => 'Prato / Pascolo';
  @override String get mappaLegendaFrutteto => 'Frutteto';
  @override String get mappaLegendaColtura => 'Coltura';
  @override String get mappaLegendaPosizione => 'Posizione attuale';
  @override String get mappaTooltipNord => 'Orienta a Nord';
  @override String get mappaTooltipFioritura => 'Aggiungi fioritura';
  @override String get mappaTooltipPosizione => 'Centra sulla posizione attuale';
  @override String get mappaFiorApiario => 'Apiario';
  @override String get mappaFiorPeriodo => 'Periodo';
  @override String get mappaFiorRaggio => 'Raggio';
  @override String get mappaFiorNote => 'Note';
  @override String get mappaFiorConferme => 'Conferme community';
  @override String mappaFiorMetri(int n) => '$n metri';
  @override String mappaFiorConferN(int n) => '$n apicoltori';
  @override String mappaFiorConferNI(int n, String avg) => '$n apicoltori · intensità media $avg/5';
  @override String mappaFiorDalAl(String start, String end) => 'Dal $start al $end';
  @override String mappaFiorDal(String start) => 'Dal $start';
  @override String get mappaFiorDettaglio => 'Dettaglio';
  @override String get mappaApiario => 'Apiario';

  // ── Nomadismo screen ──
  @override String get nomadismoTitle => 'Nomadismo';
  @override String get nomadismoLegendaDensita => 'Densità GBIF (milioni di osservazioni)';
  @override String get nomadismoLegendaApiario => 'Tuo apiario';
  @override String get nomadismoLegendaAreaAnalisi => 'Area analisi (5 km)';
  @override String get nomadismoLegendaDati => 'Dati GBIF 2010–2025';
  @override String get nomadismoSoloApiari => '🗺️ Solo apiari';
  @override String get nomadismoBtnTocca => 'Tocca la mappa…';
  @override String get nomadismoBtnAnalizza => 'Analizza punto (5 km)';
  @override String get nomadismoFloraTitle => 'Flora mellifera — raggio 5 km';
  @override String get nomadismoNessunaSpecie => 'Nessuna specie trovata.';
  @override String get nomadismoAltrePiante => 'Altre piante';
  @override String get nomadismoGbifFooter => 'Dati GBIF · osservazioni 2010–2025 · raggio 5 km';
  @override String nomadismoErrGbif(String e) => 'Errore GBIF: $e';

  // ── Splash screen ──
  @override String get splashSubtitle => 'Gestisci i tuoi apiari ovunque';

  // ── Disclaimer screen ──
  @override String get disclaimerTitle => 'Informativa sulla Sicurezza';
  @override String get disclaimerBody =>
    'ATTENZIONE: Nonostante facciamo del nostro meglio per proteggere i tuoi dati utilizzando protocolli HTTPS, l\'app non garantisce una sicurezza completa delle informazioni.\n\n'
    'Utilizzando questa applicazione, accetti i potenziali rischi di:\n'
    '• Perdita di dati in caso di violazione del database\n'
    '• Accesso non autorizzato alle informazioni degli apiari\n'
    '• Possibili interruzioni del servizio\n\n'
    'Ti consigliamo di non memorizzare informazioni sensibili o dati personali critici all\'interno dell\'applicazione.\n\n'
    'Se rifiuti questi termini, l\'app verrà chiusa. Accettando, confermi di comprendere e accettare i rischi sopra elencati.';
  @override String get disclaimerDontShow => 'Non visualizzare più questo messaggio';
  @override String get disclaimerBtnReject => 'RIFIUTA';
  @override String get disclaimerBtnAccept => 'ACCETTA';

  // ── What's New screen ──
  @override String get whatsNewBadge => 'Aggiornamento';
  @override String get whatsNewTitle => "Cosa c'è di nuovo 🐝";
  @override String get whatsNewSubtitle => 'Apiary è stato aggiornato. Ecco le novità.';
  @override String get whatsNewEmpty => 'Nessuna novità da mostrare.';
  @override String get whatsNewBtnExplore => 'Inizia ad esplorare';
  @override String whatsNewCatLabel(String cat) => cat;

  // ── Onboarding screen ──
  @override String get onboardingSkip => 'Salta';
  @override String get onboardingBack => 'Indietro';
  @override String get onboardingNext => 'Avanti';
  @override String get onboardingBtnCreate => 'Crea il mio primo apiario';
  @override String get onboardingBtnExplore => 'Esplora prima';
  @override String get onboardingStep1Title => 'Benvenuto in Apiary';
  @override String get onboardingStep1Desc => 'Il tuo diario digitale da apicoltore. Registra, monitora e gestisci tutto ciò che riguarda le tue api — dai controlli alle vendite, dalla genealogia delle regine all\'analisi AI dei telai.';
  @override String get onboardingStep2Title => 'I tuoi Apiari';
  @override String get onboardingStep2Desc => 'Un apiario è la tua postazione fisica — un campo, un bosco, un terreno. Dentro ogni apiario trovi le tue arnie. Puoi avere più apiari in luoghi diversi e gestirli tutti da qui.';
  @override String get onboardingStep3Title => 'Arnie & Controlli';
  @override String get onboardingStep3Desc => 'Ogni arnia ha la sua storia: regina, trattamenti, melari, raccolti. Registra i controlli periodici per tenere traccia della forza della colonia, della presenza della regina e dello stato sanitario.';
  @override String get onboardingStep4Title => 'Funzioni Avanzate';
  @override String get onboardingStep4F1Title => 'Controllo Vocale';
  @override String get onboardingStep4F1Desc => 'Registra un\'ispezione completa semplicemente parlando';
  @override String get onboardingStep4F2Title => 'Analisi AI';
  @override String get onboardingStep4F2Desc => 'Fotografa un telaio e scopri subito api, covata e celle reali';
  @override String get onboardingStep4F3Title => 'Statistiche';
  @override String get onboardingStep4F3Desc => 'Grafici di produzione, salute e andamento nel tempo';
  @override String get onboardingStep4F4Title => 'Collaborazione';
  @override String get onboardingStep4F4Desc => 'Condividi gli apiari con soci o collaboratori';
  @override String get onboardingStep5Title => 'Sei pronto!';
  @override String get onboardingStep5Desc => 'Inizia creando il tuo primo apiario. Ci vorranno meno di un minuto. Potrai sempre rivedere questa guida dalla pagina delle impostazioni.';

  // ── Donazione screen ──
  @override String get donazioneTitle => 'Offrici un caffè';
  @override String get donazioneErrLink => 'Impossibile aprire il link.';
  @override String get donazioneTxOk => 'Grazie! Il tuo messaggio è stato preparato.';
  @override String donazioneErrEmail(String email) => 'Nessuna app email trovata. Scrivici a $email';
  @override String get donazioneHeroSubtitle => 'Un progetto aperto, fatto da apicoltori per apicoltori.\nSe ti è utile, offrici un caffè!';
  @override String get donazioneBtnCoffee => 'Offrici un caffè';
  @override String get donazioneCard1Desc => 'Il codice è pubblico e accessibile a tutti. Nessuna funzionalità nascosta.';
  @override String get donazioneCard2Title => 'Fatto da apicoltori';
  @override String get donazioneCard2Desc => 'Ogni funzionalità nasce dall\'esperienza diretta sul campo, per chi davvero alleva api.';
  @override String get donazioneCard3Title => 'Costi infrastruttura';
  @override String get donazioneCard3Desc => 'Server, dominio e archiviazione cloud hanno un costo reale. Il tuo aiuto li copre.';
  @override String get donazioneCard4Title => 'Crescita continua';
  @override String get donazioneCard4Desc => 'Django · Flutter · AI/YOLO · Gemini. Investiamo in tecnologia per te.';
  @override String get donazioneFeedbackTitle => 'Mandaci un messaggio';
  @override String get donazioneFeedbackSubtitle => 'Segnala un bug, proponi una funzionalità o lasciaci il tuo feedback.';
  @override String get donazioneLblNome => 'Nome *';
  @override String get donazioneErrNome => 'Il nome è obbligatorio';
  @override String get donazioneLblEmail => 'Email (opzionale, per risponderti)';
  @override String get donazioneErrEmailInvalid => 'Email non valida';
  @override String get donazioneLblMsg => 'Messaggio *';
  @override String get donazioneErrMsg => 'Il messaggio è obbligatorio';
  @override String get donazioneBtnInvio => 'Invio...';
  @override String get donazioneBtnInvia => 'Invia feedback';

  // ── Guida screen ──
  @override String get guidaTitle => 'Guida Completa';
  @override String get guidaSubtitle => 'Tutto quello che devi sapere per usare Apiary al meglio';
  @override String get guidaBtnReview => 'Rivedi il tutorial';

  // ── Privacy Policy screen ──
  @override String get privacyTitle => 'Informativa sulla Privacy';
  @override String get privacyHeader => 'Informativa sulla Privacy';
  @override String get privacyLastUpdated => 'Ultimo aggiornamento: 12 marzo 2026';
  @override String get privacyIntro =>
      'La presente Informativa sulla Privacy descrive come Apiary '
      'raccoglie, utilizza e protegge i dati degli utenti. '
      'Ti invitiamo a leggerla attentamente prima di utilizzare l\'applicazione.';
  @override String get privacyS1Title => '1. Titolare del trattamento';
  @override String get privacyS1Body =>
      'Il titolare del trattamento è lo sviluppatore dell\'applicazione Apiary.\n'
      'Per qualsiasi richiesta relativa alla privacy puoi contattarci all\'indirizzo:';
  @override String get privacyS2Title => '2. Dati raccolti';
  @override String get privacyS2Body => 'L\'applicazione può raccogliere le seguenti categorie di dati, a seconda delle funzionalità utilizzate:';
  @override String get privacyS2_1Title => '2.1 Dati inseriti volontariamente dall\'utente';
  @override List<String> get privacyS2_1Bullets => [
    'Dati apicoltura: informazioni su apiari, arnie, regine, melari, sciamature, fioriture, controlli periodici e analisi dei telaini (covata, scorte, diaframmi, nutritori).',
    'Dati di account: nome utente e password per l\'autenticazione al servizio backend.',
    'Indirizzo e-mail (funzionalità in arrivo): potrà essere richiesto per la registrazione, il recupero password o l\'invio di notifiche inerenti l\'applicazione.',
  ];
  @override String get privacyS2_2Title => '2.2 Dati raccolti automaticamente';
  @override List<String> get privacyS2_2Bullets => [
    'Dati di utilizzo: informazioni tecniche sull\'uso dell\'app (es. versione, sistema operativo, lingua del dispositivo) per scopi diagnostici e di miglioramento. Questi dati non identificano personalmente l\'utente.',
    'Identificatori del dispositivo: possono essere raccolti in forma anonima o pseudonima per garantire il corretto funzionamento dell\'app.',
  ];
  @override String get privacyS2_3Title => '2.3 Dati raccolti tramite fotocamera';
  @override String get privacyS2_3Body =>
      'L\'applicazione richiede l\'accesso alla fotocamera del dispositivo per la funzionalità '
      'di analisi fotografica dei telaini tramite intelligenza artificiale (rilevamento di api, '
      'fuchi, celle reali e covata). Le immagini scattate vengono elaborate localmente sul '
      'dispositivo e/o inviate al server backend per l\'analisi. '
      'Le immagini non vengono condivise con terze parti né utilizzate per scopi diversi dall\'analisi apistica.';
  @override String get privacyS3Title => '3. Finalità del trattamento';
  @override List<String> get privacyS3Bullets => [
    'Erogazione del servizio: gestione dei dati degli apiari, sincronizzazione tra dispositivi tramite il backend remoto, analisi AI dei telaini.',
    'Miglioramento dell\'app: analisi aggregate e anonime per identificare malfunzionamenti e ottimizzare le funzionalità.',
    'Comunicazioni di servizio: notifiche relative al proprio account o al funzionamento dell\'app.',
    'Marketing e newsletter (previsto): previo consenso esplicito, l\'indirizzo e-mail potrà essere usato per inviare aggiornamenti o offerte relative all\'applicazione.',
    'Pubblicità (prevista): in futuro potranno essere integrati servizi pubblicitari di terze parti (es. Google AdMob). Gli utenti saranno informati e, ove richiesto dalla normativa, sarà richiesto il loro consenso.',
  ];
  @override String get privacyS4Title => '4. Base giuridica del trattamento';
  @override List<String> get privacyS4Bullets => [
    'Esecuzione del contratto (art. 6, par. 1, lett. b GDPR): per i dati necessari al funzionamento dell\'app e alla gestione dell\'account.',
    'Consenso (art. 6, par. 1, lett. a GDPR): per l\'accesso alla fotocamera, per comunicazioni marketing e per la pubblicità personalizzata. Il consenso può essere revocato in qualsiasi momento.',
    'Legittimo interesse (art. 6, par. 1, lett. f GDPR): per scopi diagnostici e di sicurezza del servizio.',
  ];
  @override String get privacyS5Title => '5. Conservazione dei dati';
  @override List<String> get privacyS5Bullets => [
    'I dati dell\'apiario sono conservati sul server backend (cible99.pythonanywhere.com) per tutta la durata dell\'account attivo, più un ulteriore periodo di 30 giorni dopo la cancellazione, salvo obblighi di legge.',
    'I dati memorizzati localmente sul dispositivo (SQLite e SharedPreferences) rimangono sul dispositivo fino alla disinstallazione dell\'app o alla cancellazione manuale da parte dell\'utente.',
    'I dati e-mail raccolti per finalità di marketing saranno conservati fino alla revoca del consenso.',
  ];
  @override String get privacyS6Title => '6. Condivisione con terze parti';
  @override String get privacyS6Body => 'I dati personali non vengono venduti né ceduti a terzi. Possono essere condivisi esclusivamente con:';
  @override List<String> get privacyS6Bullets => [
    'Provider di hosting: PythonAnywhere (server backend), che tratta i dati come responsabile del trattamento nel rispetto del GDPR.',
    'Servizi di analisi e pubblicità (in futuro): es. Google AdMob / Google Analytics, che dispongono di proprie informative sulla privacy.',
    'Autorità competenti: ove richiesto dalla legge o per tutelare diritti legittimi.',
  ];
  @override String get privacyS7Title => '7. Diritti dell\'utente (GDPR)';
  @override String get privacyS7Body => 'In qualità di interessato, hai il diritto di:';
  @override List<String> get privacyS7Bullets => [
    'Accesso – ottenere conferma del trattamento e copia dei tuoi dati.',
    'Rettifica – correggere dati inesatti o incompleti.',
    'Cancellazione ("diritto all\'oblio") – richiedere la cancellazione dei tuoi dati, salvo obblighi di conservazione previsti dalla legge.',
    'Limitazione del trattamento – richiedere la sospensione del trattamento in determinati casi.',
    'Portabilità – ricevere i tuoi dati in formato strutturato e leggibile da macchina.',
    'Opposizione – opporti al trattamento basato su legittimo interesse o per finalità di marketing diretto.',
    'Revoca del consenso – ritirare in qualsiasi momento il consenso precedentemente accordato.',
  ];
  @override String get privacyS7Contact => 'Per esercitare questi diritti, contatta:';
  @override String get privacyS7Garante => 'Hai inoltre il diritto di proporre reclamo all\'Autorità Garante per la protezione dei dati personali:';
  @override String get privacyS8Title => '8. Sicurezza';
  @override String get privacyS8Body =>
      'Adottiamo misure tecniche e organizzative adeguate per proteggere i dati da accesso '
      'non autorizzato, perdita o distruzione, incluso l\'uso di connessioni HTTPS per la '
      'trasmissione dei dati tra app e server.';
  @override String get privacyS9Title => '9. Minori';
  @override String get privacyS9Body =>
      'L\'applicazione non è destinata a minori di 16 anni. Non raccogliamo consapevolmente '
      'dati di minori. Qualora dovessimo venire a conoscenza di una raccolta accidentale di '
      'tali dati, procederemo alla loro cancellazione immediata.';
  @override String get privacyS10Title => '10. Modifiche alla presente informativa';
  @override String get privacyS10Body =>
      'Ci riserviamo il diritto di aggiornare questa informativa. In caso di modifiche '
      'sostanziali, l\'utente sarà informato tramite notifica nell\'app o via e-mail. '
      'L\'uso continuato dell\'app successivo alla pubblicazione delle modifiche '
      'costituisce accettazione delle stesse.';
  @override String get privacyS11Title => '11. Contatti';
  @override String get privacyS11Body => 'Per qualsiasi domanda relativa alla privacy:';
  @override String get privacyCopyright => '© 2026 Apiary – Tutti i diritti riservati.';

  // ── Weather widget ──
  @override String get weatherErrorNoData => 'Impossibile ottenere i dati meteo. Controlla la connessione.';
  @override String weatherUpdatedAt(String time) => 'Aggiornato: $time';
  @override String weatherFeelsLike(String temp) => 'Percepita $temp°C';
  @override String get weatherHumidity => 'Umidità';
  @override String get weatherWind => 'Vento';
  @override String get weatherRain => 'Pioggia';
  @override String get weatherPressure => 'Pressione';
  @override String get weatherForecast7Days => 'Previsioni 7 giorni';
  @override String get weatherToday => 'Oggi';
  @override List<String> get weatherDayNamesShort => ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  // ── QR code ──
  @override String get qrUnsupportedEntity => 'Tipo di entità non supportato per la generazione QR';
  @override String get qrLabelApiario => 'Apiario';
  @override String get qrLabelUnknown => 'Sconosciuto';
  @override String qrLabelPosition(String position) => 'Posizione: $position';
  @override String get qrLabelNotSpecified => 'Non specificata';
  @override String get qrBtnCopy => 'Copia';
  @override String get qrCopiedToClipboard => 'Codice QR copiato negli appunti';
  @override String get qrBtnShare => 'Condividi';
  @override String qrShareText(String title) => '$title - Scansionami per visualizzare i dettagli';
  @override String qrShareError(String error) => 'Errore durante la condivisione: $error';
  @override String get qrNavUnsupportedTitle => 'Tipo QR non supportato';
  @override String get qrNavUnsupportedMsg => 'Il formato del QR code scansionato non è riconosciuto.';
  @override String get qrNavErrorTitle => 'Errore';
  @override String qrNavErrorMsg(String error) => 'Si è verificato un errore: $error';
  @override String get qrNavArniaNonTrovatoTitle => 'Arnia non trovata';
  @override String get qrNavArniaNonTrovatoMsg => 'L\'arnia scansionata non è stata trovata nel sistema. Assicurati di avere i permessi necessari.';
  @override String get qrNavArniaOfflineTitle => 'Arnia non disponibile offline';
  @override String get qrNavArniaOfflineMsg => 'L\'arnia scansionata non è disponibile in modalità offline. Connettiti a internet per scaricare i dati.';
  @override String get qrNavApiarioNonTrovatoTitle => 'Apiario non trovato';
  @override String get qrNavApiarioNonTrovatoMsg => 'L\'apiario scansionato non è stato trovato nel sistema. Assicurati di avere i permessi necessari.';
  @override String get qrNavApiarioOfflineTitle => 'Apiario non disponibile offline';
  @override String get qrNavApiarioOfflineMsg => 'L\'apiario scansionato non è disponibile in modalità offline. Connettiti a internet per scaricare i dati.';

  // ── Minimap / edit mode ──
  @override String mapAddTitle(String label) => 'Aggiungi $label';
  @override String mapAddNumberLabel(String label) => 'Numero $label';
  @override String get mapLabelColor => 'Colore';
  @override String get mapBtnAdd => 'Aggiungi';
  @override String mapNucleoTitle(String num) => 'Nucleo $num';
  @override String get mapNucleoLegacyHint => 'Elemento legacy — rimuovilo dalla mappa se non più in uso.';
  @override String get mapRemoveFromMap => 'Rimuovi dalla mappa';
  @override String get mapNumberConflictTitle => 'Numero già esistente';
  @override String mapNumberConflictMsg(String current) => 'L\'arnia numero $current esiste già.\nScegli un numero per la nuova arnia:';
  @override String get mapArniaNumberLabel => 'Numero arnia';
  @override String get mapSaved => 'Mappa salvata';
  @override String get mapRemoveElementTitle => 'Rimuovi elemento';
  @override String get mapNoArnie => 'Nessuna arnia in questo apiario';
  @override String get mapNoArnieCta => 'Premi + per aggiungerne una';
  @override String get mapEditModeHint => 'Trascina · Tocca vialetto per estenderlo';
  @override String get mapSelectionHint => 'Tocca per selezionare';
  @override String mapSelectedCount(int count) => '$count selezionate';
  @override String get mapLongPressToDelete => 'Tieni premuto per eliminare';
  @override String get mapLabelArnia => 'Arnia';
  @override String get mapLabelApidea => 'Apidea';
  @override String get mapLabelMiniPlus => 'Mini-Plus';
  @override String get mapLabelPortasciami => 'Portasc.';
  @override String get mapLabelAlbero => 'Albero';
  @override String get mapLabelVialetto => 'Vialetto';
  @override String get mapTooltipCenter => 'Centra';
  @override String get mapSnapOn => 'Snap ON';
  @override String get mapSnapOff => 'Snap OFF';
  @override String get mapBtnSave => 'Salva*';
  @override String get mapBtnDone => 'Fine';
  @override String get mapLabelInactive => 'inattivo';
  @override String get mapLabelInactiveFem => 'inattiva';

  // ── Colony data in arnia detail ──
  @override String get arniaColoniaVuota => 'Arnia vuota — nessuna colonia attiva';
  @override String get arniaInsediaColonia => 'Insedia colonia';
  @override String arniaColoniaHeader(int id, String date) => 'Colonia #$id — dal $date';
  @override String arniaColoniaRegina(String razza, String origine) => 'Regina: $razza · $origine';
  @override String get arniaMenuStoriaColonie => 'Storia colonie';
  @override String get arniaMenuInsediaNuovaColonia => 'Insedia nuova colonia';

  // ── Equipment model display ──
  @override String get attrezzaturaStatoNonSpecificato => 'Non specificato';
  @override String get attrezzaturaCondizioneNonSpecificato => 'Non specificato';

  // ── Sales banner ──
  @override List<String> get monthNames => [
    'Gennaio','Febbraio','Marzo','Aprile','Maggio','Giugno',
    'Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre',
  ];
  @override String venditeBannerSummary(int count, String total) => '$count vendite  •  $total €';
  @override String get venditeCanaleMercatino => 'Mercatino';
  @override String get venditeCanaleNegozio => 'Negozio';
  @override String get venditeCanaleOnline => 'Online';
  @override String get venditeCanalePravato => 'Privato';
  @override String get venditeCanaleAltro => 'Altro';

  // ── Voice command examples ──
  @override String get voiceCommandExample1 => '"Arnia 3, regina presente, vista, 4 telaini di covata, 3 scorte"';
  @override String get voiceCommandExample2 => '"Arnia 7, famiglia forte, problemi sanitari, varroa"';
  @override String get voiceCommandExample3 => '"Arnia 2, 7 telaini totali, celle reali 2, rischio sciamatura"';
  @override String voiceCommandGeminiError(String detail) => 'Gemini: $detail';

  // ── Guide sections ──
  @override String get guidaSection1Title => 'Primi Passi — Creare il primo apiario';
  @override String get guidaSection2Title => 'Arnie & Controlli — Registrare un\'ispezione';
  @override String get guidaSection3Title => 'Regine — Gestire e tracciare le regine';
  @override String get guidaSection4Title => 'Melari & Raccolti — Dal melario alla cantina';
  @override String get guidaSection5Title => 'Funzioni AI — Chat, voce, analisi telaino';
  @override String get guidaSection6Title => 'Collaborazione — Condividere con altri apicoltori';
  @override String get guidaSection7Title => 'Esportazioni — PDF e CSV';
  @override List<String> get guidaSection1Items => [
    'Tocca il menu e vai su Apiari → Nuovo Apiario',
    'Inserisci nome, posizione sulla mappa e tipo di apiario',
    'Salva — il tuo apiario è pronto',
    'Dall\'interno dell\'apiario, tocca + per aggiungere le arnie',
    '💡 Dai nomi descrittivi alle arnie (es: "Arnia 1 — Ligustica") per ritrovarle facilmente.',
  ];
  @override List<String> get guidaSection2Items => [
    'Entra nell\'arnia che vuoi controllare',
    'Tocca Nuovo Controllo',
    'Compila: data, forza colonia (1–10), presenza regina, stato sanitario',
    'Aggiungi note libere per osservazioni specifiche',
    '💡 Forza colonia: 1 = debolissima, 5 = media, 10 = fortissima che occupa tutti i favi.',
  ];
  @override List<String> get guidaSection3Items => [
    'Ogni arnia può avere una regina associata — aggiungila dalla scheda dell\'arnia',
    'Registra: data nascita, razza, colore marcatura, origine',
    'Visualizza l\'albero genealogico per tracciare discendenze',
    'Usa Confronta Regine per valutare le prestazioni',
    '💡 Colori internazionali: Bianco (1/6), Giallo (2/7), Rosso (3/8), Verde (4/9), Blu (5/0).',
  ];
  @override List<String> get guidaSection4Items => [
    'Aggiungi un melario all\'arnia quando è il momento della raccolta',
    'Quando è pronto, registra la smielatura: data, peso grezzo, qualità',
    'Il miele estratto va in Cantina: maturatori e contenitori di stoccaggio',
    'Dall\'invasettamento, traccia i vasetti prodotti e il peso finale',
  ];
  @override List<String> get guidaSection5Items => [
    '🗨️ Chat AI — Tocca il widget chat per fare domande all\'assistente Gemini',
    '🎤 Controllo Vocale — Parla e l\'app trascrive automaticamente l\'ispezione',
    '📷 Analisi Telaino — Carica una foto del telaio per rilevare api, covata e celle reali',
    '💡 Per l\'analisi telaino usa luce naturale diffusa e tieni il telaio parallelo alla fotocamera.',
  ];
  @override List<String> get guidaSection6Items => [
    'Vai su Gruppi dal menu principale',
    'Crea un gruppo e invita altri apicoltori via email o link',
    'Assegna ruoli: Proprietario, Collaboratore, Visualizzatore',
    'Condividi uno o più apiari con il gruppo dall\'interno dell\'apiario',
  ];
  @override List<String> get guidaSection7Items => [
    'Ispezioni PDF: dall\'interno di un apiario → Esporta PDF',
    'Trattamenti CSV: da Gestione → Trattamenti → Esporta CSV',
    'Vendite CSV: da Gestione → Vendite → Esporta CSV',
    '💡 I CSV sono compatibili con Excel e Google Sheets per tracciabilità e contabilità.',
  ];

  // ── AI Chat ──
  @override String get chatWelcomeMessage => 'Ciao! Sono ApiarioAI, il tuo assistente per l\'apicoltura. Come posso aiutarti oggi?';
  @override String get chatTitle => 'ApiarioAI Assistant';
  @override String get chatChartDefaultTitle => 'Grafico';
}
