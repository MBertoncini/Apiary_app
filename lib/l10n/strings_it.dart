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
  @override String get voiceModeSttTitle => 'Speech-to-text locale';
  @override String get voiceModeSttSubtitle =>
      'Il riconoscimento vocale del dispositivo trascrive il testo; '
      'Gemini lo struttura in dati. '
      'Consigliato: funziona anche con connessione lenta.';
  @override String get voiceModeAudioTitle => 'Registra audio → Gemini multimodale';
  @override String get voiceModeAudioSubtitle =>
      'L\'audio viene inviato direttamente a Gemini che '
      'trascrive e struttura in un unico passaggio. '
      'Più preciso in ambienti rumorosi. Richiede connessione.';

  // AI Quota section
  @override String get sectionQuota => 'Quota AI — Uso giornaliero';
  @override String get quotaRefreshTooltip => 'Aggiorna';
  @override String get quotaDataUnavailable => 'Dati non disponibili (offline o errore di rete)';
  @override String get quotaTranscriptionsToday => 'Trascrizioni oggi';
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
  @override String get quotaVoiceInput => 'Inserimento Vocale (Gemini)';
  @override String get quotaStatsNlQuery => 'Statistiche NL Query (Groq)';
  @override String quotaResetInHoursMinutes(int hours, int minutes) =>
      'Reset tra ${hours}h ${minutes}m';
  @override String quotaResetInMinutes(int minutes) => 'Reset tra ${minutes}m';
  @override String quotaRemaining(int count) => '$count rimaste';
  @override String quotaUsedToday(int count) => '$count oggi';
}
