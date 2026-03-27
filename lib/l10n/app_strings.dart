// lib/l10n/app_strings.dart
//
// Abstract base class for all UI strings.
// To add a new language: create a new class that extends AppStrings,
// implement every getter, and register it in LanguageService._setFromCode().
// Zero duplication of widgets or screens — only a single new .dart file.

import 'package:flutter/material.dart';

abstract class AppStrings {
  // ── Language metadata ────────────────────────────────────────────────────
  String get languageName;
  Locale get locale;

  // ── Navigation / Drawer ──────────────────────────────────────────────────
  String get navDashboard;
  String get navApiari;
  String get navArnie;
  String get navMappaApiari;
  String get navFioriture;
  String get navRegine;
  String get navTrattamentiSanitari;
  String get navMelariProduzioni;
  String get navAttrezzature;
  String get navVendite;
  String get navStatisticheAI;
  String get navGruppi;
  String get navPagamenti;
  String get navInserimentoVocale;
  String get navOffriciunCaffe;
  String get navLogout;
  String get navSettingsTooltip;
  String get defaultUserName;

  // ── Common buttons / labels ──────────────────────────────────────────────
  String get btnSave;
  String get btnCancel;
  String get btnConfirm;
  String get btnRemove;
  String get btnSaving;
  String get btnLogout;

  // ── Settings Screen ──────────────────────────────────────────────────────
  String get settingsTitle;

  // Profile section
  String get sectionProfile;
  String get fieldFirstName;
  String get fieldLastName;
  String get btnSaveName;
  String get btnExit;
  String get msgProfileUpdated;
  String get msgProfileSaveError;

  // Language section
  String get sectionLanguage;
  String get labelLanguageSubtitle;

  // AI API Keys section
  String get sectionAiApiKeys;
  String get geminiSectionLabel;
  String get geminiDescription;
  String get geminiHowToGet;
  String get groqSectionLabel;
  String get groqDescription;
  String get groqHowToGet;
  String get btnSaveKey;
  String get msgApiKeyRemoved;
  String get msgApiKeySaved;
  String get msgApiKeySaveError;
  String get msgGroqKeySaved;
  String get msgGroqKeyRemoved;

  // Voice input section
  String get sectionVoiceInput;
  String get voiceInputSubtitle;
  String get voiceModeSttTitle;
  String get voiceModeSttSubtitle;
  String get voiceModeAudioTitle;
  String get voiceModeAudioSubtitle;

  // AI Quota section
  String get sectionQuota;
  String get quotaRefreshTooltip;
  String get quotaDataUnavailable;
  String get quotaTranscriptionsToday;
  String get quotaStatsToday;

  // Guide & Tutorial section
  String get sectionGuideTutorial;
  String get tutorialTitle;
  String get tutorialSubtitle;
  String get completeGuideTitle;
  String get completeGuideSubtitle;

  // Info section
  String get sectionInfo;
  String get infoAppVersion;
  String get infoApiServer;
  String get infoDevelopedBy;
  String get infoPrivacyPolicy;

  // Dialogs
  String get clearCacheTitle;
  String get clearCacheMessage;
  String get msgCacheCleared;
  String get logoutConfirmTitle;
  String get logoutConfirmMessage;

  // ── Quota section – detailed labels ──────────────────────────────────────
  String get quotaUsingPersonalKey;
  String get quotaUsingSystemKey;
  String get quotaSystemKeyLabel;
  String get quotaPersonalKeyLabel;
  String get quotaPersonalKeyNotSetLabel;
  String get quotaResetNoData;
  String get quotaResetSoon;
  String get quotaFreePlan;
  String get quotaUsingGroqPersonal;
  String get quotaResetDaily;
  String get quotaResetMidnight;
  String get quotaApiarioAIAssistant;
  String get quotaVoiceInput;
  String get quotaStatsNlQuery;

  /// e.g. "Reset in 2h 15m"
  String quotaResetInHoursMinutes(int hours, int minutes);

  /// e.g. "Reset in 45m"
  String quotaResetInMinutes(int minutes);

  /// e.g. "142 remaining" / "142 rimaste"
  String quotaRemaining(int count);

  /// e.g. "5 today" / "5 oggi"
  String quotaUsedToday(int count);
}
