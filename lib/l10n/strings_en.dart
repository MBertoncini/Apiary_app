// lib/l10n/strings_en.dart
import 'package:flutter/material.dart';
import 'app_strings.dart';

class StringsEn extends AppStrings {
  // ── Language metadata ────────────────────────────────────────────────────
  @override String get languageName => 'English';
  @override Locale get locale => const Locale('en');

  // ── Navigation / Drawer ──────────────────────────────────────────────────
  @override String get navDashboard => 'Dashboard';
  @override String get navApiari => 'Apiaries';
  @override String get navArnie => 'Hives';
  @override String get navMappaApiari => 'Apiaries Map';
  @override String get navFioriture => 'Blooms';
  @override String get navRegine => 'Queens';
  @override String get navTrattamentiSanitari => 'Health Treatments';
  @override String get navMelariProduzioni => 'Honey Supers & Production';
  @override String get navAttrezzature => 'Equipment';
  @override String get navVendite => 'Sales';
  @override String get navStatisticheAI => 'Statistics & AI';
  @override String get navGruppi => 'Groups';
  @override String get navPagamenti => 'Payments';
  @override String get navInserimentoVocale => 'Voice Input';
  @override String get navOffriciunCaffe => 'Buy us a coffee';
  @override String get navLogout => 'Logout';
  @override String get navSettingsTooltip => 'Settings';
  @override String get defaultUserName => 'User';

  // ── Common buttons / labels ──────────────────────────────────────────────
  @override String get btnSave => 'Save';
  @override String get btnCancel => 'CANCEL';
  @override String get btnConfirm => 'CONFIRM';
  @override String get btnRemove => 'Remove';
  @override String get btnSaving => 'Saving...';
  @override String get btnLogout => 'LOGOUT';

  // ── Settings Screen ──────────────────────────────────────────────────────
  @override String get settingsTitle => 'Settings';

  // Profile section
  @override String get sectionProfile => 'Profile';
  @override String get fieldFirstName => 'First name';
  @override String get fieldLastName => 'Last name';
  @override String get btnSaveName => 'Save name';
  @override String get btnExit => 'Logout';
  @override String get msgProfileUpdated => 'Profile updated';
  @override String get msgProfileSaveError => 'Error saving profile';

  // Language section
  @override String get sectionLanguage => 'Language';
  @override String get labelLanguageSubtitle => 'Select app language';

  // AI API Keys section
  @override String get sectionAiApiKeys => 'AI API Keys';
  @override String get geminiSectionLabel => 'Gemini — ApiarioAI & Voice Input';
  @override String get geminiDescription =>
      '• Without a personal key the app uses the shared system key (shared quota).\n'
      '• With your own key you get an independent quota: 20 requests/day (Gemini 2.5 Flash free plan).\n'
      '• Used for: ApiarioAI chat + voice transcription.\n'
      '• The key is stored securely on the server.';
  @override String get geminiHowToGet => 'Get it at aistudio.google.com → "Get API key"';
  @override String get groqSectionLabel => 'Groq — Statistics NL Query';
  @override String get groqDescription =>
      '• Used for AI queries in Statistics (natural language questions).\n'
      '• Without a key the backend uses the shared system key.\n'
      '• Stored locally on the device.';
  @override String get groqHowToGet => 'Get it at console.groq.com → "API Keys"';
  @override String get btnSaveKey => 'Save key';
  @override String get msgApiKeyRemoved => 'API key removed';
  @override String get msgApiKeySaved => 'API key saved';
  @override String get msgApiKeySaveError => 'Error saving API key';
  @override String get msgGroqKeySaved => 'Groq key saved';
  @override String get msgGroqKeyRemoved => 'Groq key removed';

  // Voice input section
  @override String get sectionVoiceInput => 'Voice Input';
  @override String get voiceInputSubtitle => 'Choose how voice data is captured.';
  @override String get voiceModeSttTitle => 'Local speech-to-text';
  @override String get voiceModeSttSubtitle =>
      'The device\'s speech recognition transcribes the text; '
      'Gemini structures it into data. '
      'Recommended: works even on slow connections.';
  @override String get voiceModeAudioTitle => 'Record audio → Gemini multimodal';
  @override String get voiceModeAudioSubtitle =>
      'Audio is sent directly to Gemini which '
      'transcribes and structures it in one step. '
      'More accurate in noisy environments. Requires a connection.';

  // AI Quota section
  @override String get sectionQuota => 'AI Quota — Daily usage';
  @override String get quotaRefreshTooltip => 'Refresh';
  @override String get quotaDataUnavailable => 'Data unavailable (offline or network error)';
  @override String get quotaTranscriptionsToday => 'Transcriptions today';
  @override String get quotaStatsToday => 'Statistics queries today';

  // Guide & Tutorial section
  @override String get sectionGuideTutorial => 'Guide & Tutorial';
  @override String get tutorialTitle => 'Tutorial';
  @override String get tutorialSubtitle => 'Review the introductory tour';
  @override String get completeGuideTitle => 'Complete Guide';
  @override String get completeGuideSubtitle => 'Detailed instructions for all features';

  // Info section
  @override String get sectionInfo => 'Information';
  @override String get infoAppVersion => 'App version';
  @override String get infoApiServer => 'API Server';
  @override String get infoDevelopedBy => 'Developed by';
  @override String get infoPrivacyPolicy => 'Privacy Policy';

  // Dialogs
  @override String get clearCacheTitle => 'Clear cache';
  @override String get clearCacheMessage =>
      'Are you sure you want to clear all locally saved data? '
      'You will need to synchronize again.';
  @override String get msgCacheCleared => 'Cache cleared';
  @override String get logoutConfirmTitle => 'Logout';
  @override String get logoutConfirmMessage => 'Are you sure you want to logout?';

  // Quota section – detailed labels
  @override String get quotaUsingPersonalKey => 'Using your personal key';
  @override String get quotaUsingSystemKey => 'Using the shared system key';
  @override String get quotaSystemKeyLabel => 'System key (shared)';
  @override String get quotaPersonalKeyLabel => 'Your personal key';
  @override String get quotaPersonalKeyNotSetLabel => 'Your personal key (not set)';
  @override String get quotaResetNoData => 'Reset: data not yet available';
  @override String get quotaResetSoon => 'Reset imminent';
  @override String get quotaFreePlan => 'Free plan: 20 requests/day';
  @override String get quotaUsingGroqPersonal => 'Using your personal Groq key';
  @override String get quotaResetDaily => 'Daily reset';
  @override String get quotaResetMidnight => 'Reset at midnight';
  @override String get quotaApiarioAIAssistant => 'ApiarioAI Assistant (Gemini)';
  @override String get quotaVoiceInput => 'Voice Input (Gemini)';
  @override String get quotaStatsNlQuery => 'Statistics NL Query (Groq)';
  @override String quotaResetInHoursMinutes(int hours, int minutes) =>
      'Reset in ${hours}h ${minutes}m';
  @override String quotaResetInMinutes(int minutes) => 'Reset in ${minutes}m';
  @override String quotaRemaining(int count) => '$count remaining';
  @override String quotaUsedToday(int count) => '$count today';
}
