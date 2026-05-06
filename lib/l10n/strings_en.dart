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
  @override String get geminiSectionLabel => 'Gemini - ApiarioAI & Voice Input';
  @override String get geminiDescription =>
      '• Without a personal key the app uses the shared system key (shared quota).\n'
      '• With your own key you get an independent quota: 20 requests/day (Gemini 2.5 Flash free plan).\n'
      '• Used for: ApiarioAI chat + voice transcription.\n'
      '• The key is stored securely on the server.';
  @override String get geminiHowToGet => 'Get it at aistudio.google.com → "Get API key"';
  @override String get groqSectionLabel => 'Groq - Statistics NL Query';
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
  @override String get voiceModeSttTitle => 'Speech-to-text (free)';
  @override String get voiceModeSttSubtitle =>
      'Your device microphone transcribes speech; '
      'data is extracted locally with no connection or API needed. '
      'Recommended for everyday use.';
  @override String get voiceModeAudioTitle => 'Record audio - Gemini AI (premium)';
  @override String get voiceModeAudioSubtitle =>
      'Audio is analysed by Gemini in one step: '
      'more accurate in noisy environments and with free-form speech. '
      'Requires an internet connection.';
  @override String get voiceAudioPremiumSheetTitle => 'AI audio mode';
  @override String get voiceAudioPremiumSheetBody =>
      'Gemini Audio mode sends your recording to Google Gemini '
      'for more accurate transcription and structured data extraction.\n\n'
      'During the testing phase it is available with a daily limit '
      'that depends on your account tier.';
  @override String get voiceAudioPremiumSheetActivate => 'Use this mode';

  // ── Voice input: extended access block (settings) ──
  @override String get voiceExtendedAccessTitle => 'Extended access';
  @override String get voiceExtendedAccessDesc =>
      'The app is in testing phase. Higher tiers are currently '
      'available via access code.';
  @override String get voiceExtendedAccessCta => 'See details';

  // ── Advanced API options block (settings, collapsed) ──
  @override String get settingsAdvancedOptions => 'Advanced options';
  @override String get settingsAdvancedOptionsSubtitle =>
      'Personal API keys';
  @override String get settingsAdvancedOptionsDesc =>
      'When you provide your own key, tier limits no longer apply '
      'and usage remains billed to you by the provider.';

  // Equipment prompt
  @override String get sectionEquipmentPrompt => 'Equipment';
  @override String get settingsAttrezzaturaPrompt => 'Suggest equipment registration';
  @override String get settingsAttrezzaturaPromptSub => 'Show popup after creating hives';

  // AI Quota section
  @override String get sectionQuota => 'AI Quota - Daily usage';
  @override String get quotaRefreshTooltip => 'Refresh';
  @override String get quotaDataUnavailable => 'Data unavailable (offline or network error)';
  @override String get quotaTranscriptionsToday => 'Audio recordings today';
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
  @override String get quotaVoiceInput => 'Gemini Audio (premium)';
  @override String get quotaStatsNlQuery => 'Statistics NL Query (Groq)';
  @override String quotaResetInHoursMinutes(int hours, int minutes) =>
      'Reset in ${hours}h ${minutes}m';
  @override String quotaResetInMinutes(int minutes) => 'Reset in ${minutes}m';
  @override String quotaRemaining(int count) => '$count remaining';
  @override String quotaUsedToday(int count) => '$count today';

  // ── Common extra buttons & labels ────────────────────────────────────────
  @override String get btnDelete => 'Delete';
  @override String get btnDeleteCaps => 'DELETE';
  @override String get btnRetry => 'Retry';
  @override String get btnEdit => 'Edit';
  @override String get btnAdd => 'Add';
  @override String get btnReplace => 'Replace';
  @override String get btnStart => 'Start';
  @override String get btnStop => 'Stop';
  @override String get btnComplete => 'Complete';
  @override String get btnSearch => 'Search';
  @override String get btnSend => 'Send';
  @override String get labelLoading => 'Loading...';
  @override String get labelNotes => 'Notes';
  @override String get labelAll => 'All';
  @override String get labelPersonal => 'Personal';
  @override String get labelDate => 'Date';
  @override String get labelDateStart => 'Start date';
  @override String get labelDateEnd => 'End date';
  @override String get labelDateEndOpt => 'End date (optional)';
  @override String get labelApiario => 'Apiary';
  @override String get labelArnia => 'Hive';
  @override String get labelActive => 'Active';
  @override String get labelInactive => 'Inactive';
  @override String get labelOptional => '(optional)';
  @override String get labelNa => 'N/A';
  @override String get labelYes => 'Yes';
  @override String get labelNo => 'No';
  @override String get msgErrorLoading => 'Error loading data';
  @override String msgErrorGeneric(String e) => 'Error: $e';
  @override String get msgOfflineMode => 'Offline mode - data updated at last access';
  @override String get dialogConfirmDeleteTitle => 'Confirm deletion';
  @override String get dialogConfirmDeleteBtn => 'DELETE';
  @override String get dialogCancelBtn => 'CANCEL';

  // ── Apiario screens ───────────────────────────────────────────────────────
  // List
  @override String get apiarioListTitle => 'Your apiaries';
  @override String get apiarioSearchHint => 'Search by name or location...';
  @override String apiarioNotFoundForQuery(String q) => 'No apiary found with "$q"';
  @override String get apiarioFabTooltip => 'Add apiary';
  @override String get apiarioBadgeMap => 'Map';
  @override String get apiarioBadgeMeteo => 'Weather';
  @override String get apiarioBadgeShared => 'Shared';

  // Detail
  @override String get apiarioDetailLoading => 'Loading...';
  @override String get apiarioDetailTooltipEdit => 'Edit apiary';
  @override String get apiarioDetailTooltipDelete => 'Delete apiary';
  @override String get apiarioDetailTooltipQr => 'QR Code';
  @override String get apiarioDetailTooltipInfo => 'Apiary info';
  @override String get apiarioDetailTooltipAddArnia => 'Add hive';
  @override String get apiarioDetailDeleteTitle => 'Delete Apiary';
  @override String get apiarioDetailDeletedOk => 'Apiary deleted successfully';
  @override String apiarioDetailDeleteError(String e) => 'Error deleting: $e';
  @override String get apiarioDetailNoPdfArnie => 'No hives available for printing';
  @override String apiarioDetailPdfError(String e) => 'Error generating PDF: $e';
  @override String get apiarioDetailNoMeteo => 'Weather monitoring not activated';
  @override String get apiarioDetailActivateMeteo => 'Activate weather monitoring';
  @override String get apiarioDetailNoCoords => 'Coordinates not set for this apiary';
  @override String get apiarioDetailSetCoords => 'Set coordinates';
  @override String get apiarioDetailLblTrattamenti => 'Treatments';
  @override String get apiarioDetailNoTrattamenti => 'No health treatments recorded';
  @override String get apiarioDetailAddTrattamento => 'Add treatment';
  @override String get apiarioDetailNewTrattamento => 'New treatment';
  @override String get apiarioDetailBtnDettagli => 'Details';
  @override String get apiarioDetailLblNote => 'Notes';
  @override String get apiarioDetailLblStatistiche => 'Statistics';
  @override String get apiarioDetailErrorLoad => 'Error loading data';
  @override String apiarioDetailDeleteMsg(String nome) =>
      'Are you sure you want to delete "$nome"?\n\nAll associated hives, inspections, treatments and data will also be deleted.';
  @override String get apiarioTabMeteo => 'Weather';
  @override String get trattamentoStatusAnnullato => 'Cancelled';
  @override String get apiarioDetailInfoPos => 'Location';
  @override String get apiarioDetailInfoCoord => 'Coordinates';
  @override String get apiarioDetailInfoMeteoOn => 'Active';
  @override String get apiarioDetailInfoMeteoOff => 'Disabled';
  @override String get apiarioDetailInfoVis => 'Map visibility';
  @override String get apiarioDetailInfoSharing => 'Group sharing';
  @override String get apiarioDetailInfoShared => 'Shared with group';
  @override String get apiarioDetailInfoNotShared => 'Not shared';

  // Form
  @override String get apiarioFormTitleNew => 'New apiary';
  @override String get apiarioFormTitleEdit => 'Edit apiary';
  @override String get apiarioFormLblName => 'Apiary name';
  @override String get apiarioFormHintName => 'E.g. Mountain apiary';
  @override String get apiarioFormLblSearchAddr => 'Search address';
  @override String get apiarioFormHintSearchAddr => 'E.g. 1 Main St, London';
  @override String get apiarioFormTooltipSearch => 'Search';
  @override String get apiarioFormBtnUsePos => 'Use current location';
  @override String get apiarioFormLblLat => 'Latitude';
  @override String get apiarioFormLblLon => 'Longitude';
  @override String get apiarioFormVisibOwner => 'Owner only';
  @override String get apiarioFormVisibGroup => 'Group members';
  @override String get apiarioFormVisibAll => 'All users';
  @override String get apiarioFormVisibAllPrivacyNote =>
      'Your exact location will not be shown: only an approximate area (~500 m) will appear on the map. '
      'This lets you share your area without risking theft, while helping other beekeepers discover active beekeeping zones.';
  @override String get mapaApproxAreaLabel => 'Approximate location';
  @override String get apiarioFormMeteoTitle => 'Weather monitoring';
  @override String get apiarioFormMeteoSubtitle => 'Enable weather condition monitoring';
  @override String get apiarioFormShareTitle => 'Group sharing';
  @override String get apiarioFormShareSubtitle => 'Share this apiary with a group';
  @override String get apiarioFormLblGroup => 'Select group';
  @override String get apiarioFormLblNotes => 'Notes';
  @override String get apiarioFormHintNotes => 'Enter any notes about this apiary...';
  @override String get apiarioFormSectionGeneral => 'General information';
  @override String get apiarioFormSectionPos => 'Position on map';
  @override String get apiarioFormSectionVisib => 'Map visibility';
  @override String get apiarioFormSectionFeatures => 'Additional features';
  @override String get apiarioFormValidateName => 'Enter the apiary name';
  @override String get apiarioFormValidateLon => 'Also enter the longitude';
  @override String get apiarioFormValidateLat => 'Also enter the latitude';
  @override String get apiarioFormValidateFormat => 'Invalid format';
  @override String get apiarioFormValidateGroup => 'Select a group';
  @override String get apiarioFormMapHint =>
      'Search an address to navigate the map, then tap the exact spot.';
  @override String get apiarioFormNoGruppi =>
      'You are not part of any group. Create or join a group to share.';
  @override String get apiarioFormBtnCreate => 'CREATE APIARY';
  @override String get apiarioFormBtnUpdate => 'UPDATE APIARY';
  @override String get apiarioCreatedOk => 'Apiary created successfully';
  @override String get apiarioUpdatedOk => 'Apiary updated successfully';
  @override String get apiarioPermDenied => 'Location permissions denied';
  @override String get apiarioPermDeniedPermanent =>
      'Permissions permanently denied. Enable them in settings.';
  @override String get apiarioErrorPos => 'Error retrieving location';
  @override String get apiarioErrorAddr => 'Error searching address';

  // ── Arnia screens ─────────────────────────────────────────────────────────
  // List
  @override String get arniaListTitle => 'My Hives';
  @override String get arniaFabTooltip => 'Add hive';
  @override String get arniaEmptyTitle => 'No hives found';
  @override String get arniaEmptySubtitle =>
      'You have not created any hives yet or they could not be loaded';
  @override String get arniaBtnCreate => 'Create hive';
  @override String get arniaBtnRetry => 'Retry loading';
  @override String arniaItemTitle(int num) => 'Hive $num';
  @override String get arniaStatusActive => 'Active';
  @override String get arniaStatusInactive => 'Inactive';
  @override String get arniaNoControllo => 'No inspection recorded';
  @override String arniaControlloDate(String d) => 'Inspection: $d';
  @override String get arniaChipProblemi => 'Issues';
  @override String get arniaChipSciamatura => 'Swarm';
  @override String arniaActiveCount(int active, int total) => '$active/$total active';
  @override String get arniaCatAltri => 'Others';
  @override String get arniaCatNuclei => 'Nucs';
  @override String get arniaCatSpeciali => 'Special';

  // Detail
  @override String get arniaDetailNotFound => 'Hive not found';
  @override String get arniaDetailErrorLoad => 'Error loading data';
  @override String arniaDetailTitle(int num) => 'Hive $num';
  @override String get arniaDetailTooltipType => 'Change box type';
  @override String get arniaDetailTooltipEdit => 'Edit hive';
  @override String get arniaDetailTooltipDelete => 'Delete hive';
  @override String get arniaDetailTooltipQr => 'Generate QR Code';
  @override String get arniaDetailTooltipInfo => 'Hive info';
  @override String get arniaDetailDeleteTitle => 'Delete Hive';
  @override String get arniaDetailDeletedOk => 'Hive deleted successfully';
  @override String arniaDetailDeleteError(String e) => 'Error deleting: $e';
  @override String get arniaDetailDeleteControlloTitle => 'Delete Inspection';
  @override String get arniaDetailControlloDeletedOk => 'Inspection deleted successfully';
  @override String arniaDetailControlloDeleteError(String e) => 'Error deleting: $e';
  @override String get arniaDetailReplaceReginaTitle => 'Replace Queen';
  @override String get arniaDetailReplaceReginaBtn => 'CONFIRM REPLACEMENT';
  @override String get arniaDetailChangeTypeTitle => 'Change box type';
  @override String arniaDetailTypeUpdated(String tipo) => 'Type updated: $tipo';
  @override String arniaDetailTypeError(String e) => 'Error updating type: $e';
  @override String get arniaDetailBtnRegControllo => 'Record inspection';
  @override String get arniaDetailBtnAddRegina => 'Add queen';
  @override String get arniaDetailBtnEditRegina => 'Edit';
  @override String get arniaDetailBtnReplaceRegina => 'Replace';
  @override String get arniaDetailBtnAvviaAnalisi => 'Start Analysis';
  @override String get arniaDetailTooltipEditControllo => 'Edit inspection';
  @override String get arniaDetailTooltipDeleteControllo => 'Delete inspection';
  @override String get arniaDetailLblMotivo => 'Reason';
  @override String get arniaDetailLblDataRimozione => 'Removal date';
  @override String get arniaDetailLblGenealogia => 'Genealogy';
  @override String get arniaDetailRegistraControllo => 'Record Inspection';
  @override String get arniaDetailBtnModifica => 'Edit';
  @override String get arniaDetailBtnSostituisci => 'Replace';
  @override String arniaDetailError(String e) => 'Error: $e';
  // Tab labels
  @override String get arniaTabControlli => 'Inspections';
  @override String get arniaTabRegina => 'Queen';
  @override String get arniaTabAnalisi => 'Analysis';
  // Controlli tab content
  @override String get arniaDetailNoControlli => 'No inspections recorded';
  @override String arniaDetailControlloTitle(String date) => 'Inspection of $date';
  @override String arniaDetailControlloBy(String user) => 'By $user';
  @override String arniaDetailScorte(int n) => 'Stores: $n';
  @override String arniaDetailCovata(int n) => 'Brood: $n';
  @override String get arniaDetailReginaPresente => 'Queen present';
  @override String get arniaDetailReginaAssente => 'Queen absent';
  @override String get arniaDetailReginaVista => 'Queen spotted';
  @override String get arniaDetailUovaFresche => 'Fresh eggs';
  @override String arniaDetailCelleReali(int n) => 'Queen cells: $n';
  @override String get arniaDetailProblemiSanitari => 'Health issues';
  // Regina tab content
  @override String get arniaDetailNoRegina => 'No queen registered';
  @override String get arniaDetailReginaIncompleta => 'Incomplete queen record';
  @override String get arniaDetailReginaAutoMsg =>
      'Queen detected automatically. Tap to complete breed, origin and other details.';
  @override String arniaDetailIntrodottaIl(String date) => 'Introduced on $date';
  @override String get arniaDetailSectionGeneral => 'General information';
  @override String get arniaDetailLblDataNascita => 'Date of birth';
  @override String get arniaDetailLblValutazioni => 'Ratings';
  @override String get arniaDetailRatingDocilita => 'Docility';
  @override String get arniaDetailRatingProduttivita => 'Productivity';
  @override String get arniaDetailRatingResistenza => 'Disease resistance';
  @override String get arniaDetailRatingTendenzaSciamatura => 'Swarming tendency';
  @override String get arniaDetailLblMadre => 'Mother';
  @override String get arniaDetailReginaFondatrice => 'Founding queen';
  @override String get arniaDetailLblFiglie => 'Daughters';
  @override String get arniaDetailLblStoria => 'History in hive';
  @override String get arniaDetailStoriaCorrente => 'ongoing';
  // Origine regina
  @override String get arniaDetailOrigineAcquistata => 'Purchased';
  @override String get arniaDetailOrigineAllevata => 'Bred';
  @override String get arniaDetailOrigineSciamatura => 'Natural swarm';
  @override String get arniaDetailOrigineEmergenza => 'Emergency cells';
  @override String get arniaDetailOrigineSconosciuta => 'Unknown';
  // Analisi tab content
  @override String get arniaDetailNoAnalisi => 'No analysis recorded';
  @override String get arniaDetailBtnAnalisiTelaino => 'Frame Analysis';
  @override String arniaDetailAnalisiTagApi(int n) => 'Bees: $n';
  @override String arniaDetailAnalisiTagRegine(int n) => 'Queens: $n';
  @override String arniaDetailAnalisiTagFuchi(int n) => 'Drones: $n';
  @override String arniaDetailAnalisiTagCelleReali(int n) => 'Q. Cells: $n';
  // Info sheet
  @override String get arniaDetailInfoInstallata => 'Installed on';
  @override String get arniaDetailInfoTipo => 'Type';
  @override String get arniaDetailInfoColore => 'Colour';
  @override String get arniaDetailInfoNonSpecificata => 'Not specified';
  // Replace regina dialog
  @override String get arniaDetailReplaceReginaMsg =>
      'The current queen will be removed. You can immediately add a new one.';
  @override String get arniaDetailChangeMotivoSostituzione => 'Scheduled replacement';
  @override String get arniaDetailChangeMotivoMorte => 'Natural death';
  @override String get arniaDetailChangeMotivoSciamatura => 'Swarming';
  @override String get arniaDetailChangeMotivoProblemaSanitario => 'Health issue';
  @override String get arniaDetailChangeMotivoAltro => 'Other';
  // Cambio tipo sheet
  @override String get arniaDetailChangeTypeMsg =>
      'The colony stays the same - only the box model changes.';
  // Delete confirm dialogs
  @override String arniaDetailDeleteMsg(String num) =>
      'Are you sure you want to delete "Hive $num"?\n\n'
      'All associated inspections, queen and honey supers will also be deleted.';
  @override String arniaDetailDeleteControlloMsg(String date) =>
      'Are you sure you want to delete the inspection of $date?';

  // Form
  @override String get arniaFormTitleNew => 'New Hive';
  @override String get arniaFormTitleEdit => 'Edit Hive';
  @override String get arniaFormLblApiario => 'Apiary';
  @override String get arniaFormHintApiario => 'Select the apiary';
  @override String get arniaFormLblNumero => 'Hive number';
  @override String get arniaFormHintNumero => 'Enter the hive number';
  @override String get arniaFormLblColore => 'Hive colour';
  @override String get arniaFormLblDataInstall => 'Installation date';
  @override String get arniaFormActiveTitle => 'Active hive';
  @override String get arniaFormLblNotes => 'Notes';
  @override String get arniaFormHintNotes => 'Enter any notes (optional)';
  @override String get arniaFormLblTipoArnia => 'Hive type';
  @override String get arniaFormBtnCreate => 'CREATE HIVE';
  @override String get arniaFormBtnUpdate => 'UPDATE HIVE';
  @override String get arniaFormValidateApiario => 'Select an apiary';
  @override String get arniaFormValidateNumero => 'Enter a number';
  @override String get arniaFormValidateNumeroFormat => 'Enter a valid number';
  @override String arniaFormValidateNumeroUsato(int n) => 'Number $n is already used in this apiary';
  @override String get arniaCreatedOk => 'Hive created successfully';
  @override String get arniaUpdatedOk => 'Hive updated successfully';
  @override String get arniaLoadApiariError => 'Error loading apiaries';
  @override String arniaFormError(String e) => 'Error: $e';

  // ── Trattamento screens ───────────────────────────────────────────────────
  // List
  @override String get trattamentiTitle => 'Health Treatments';
  @override String get trattamentiNoData => 'No health treatments found';
  @override String get trattamentiBtnNew => 'New treatment';
  @override String trattamentiInizio(String d) => 'Start: $d';
  @override String trattamentiFine(String d) => 'End: $d';
  @override String trattamentiFineSOSP(String d) => 'End of suspension: $d';
  @override String trattamentiNote(String n) => 'Notes: $n';
  @override String get trattamentiBtnAvvia => 'Start';
  @override String get trattamentiBtnAnnullaStatus => 'Cancel';
  @override String get trattamentiBtnCompleta => 'Complete';
  @override String get trattamentiBtnInterrompi => 'Stop';
  @override String get trattamentiBtnRipristina => 'Restore';
  @override String get trattamentoRestoredOk => 'Treatment restored';
  @override String trattamentoRestoreError(String e) => 'Error restoring: $e';
  @override String get trattamentiDeleteTitle => 'Delete Treatment';
  @override String get trattamentiDeletedOk => 'Treatment deleted successfully';
  @override String trattamentiDeleteError(String e) => 'Error deleting: $e';
  @override String trattamentiError(String e) => 'Error: $e';
  @override String get trattamentiTabAttivi => 'Active';
  @override String get trattamentiTabCompletati => 'Completed';
  @override String get trattamentiNoAttivi => 'No active treatments';
  @override String get trattamentiNoCompletati => 'No completed treatments';
  @override String trattamentiDeleteMsg(String nome) =>
      'Are you sure you want to delete the treatment "$nome"?';
  @override String trattamentiArnieSelezionate(int n) => 'Hives: $n selected';
  @override String get trattamentiMetodoStrisce => 'Strips';
  @override String get trattamentiMetodoGocciolato => 'Drizzle';
  @override String get trattamentiMetodoSublimato => 'Vaporized';

  // Detail
  @override String get trattamentoDetailTitle => 'Treatment Detail';
  @override String get trattamentoDetailDeleteTitle => 'Confirm deletion';
  @override String get trattamentoDetailDeleteMsg =>
      'Are you sure you want to delete this treatment?';
  @override String get trattamentoDetailTooltipEdit => 'Edit';
  @override String get trattamentoDetailTooltipDelete => 'Delete';
  @override String get trattamentoDetailTooltipRestore => 'Restore';
  @override String get trattamentoDetailDeletedOk => 'Treatment deleted';
  @override String trattamentoDetailDeleteError(String e) => 'Deletion error: $e';
  @override String trattamentoDetailArniaLabel(String id) => 'Hive $id';
  @override String get trattamentoDetailApplicatoTutto => 'Applied to the entire apiary';
  @override String get trattamentoDetailLblCaricamento => 'Loading treatment...';
  @override String get trattamentoDetailSectionDettagli => 'Treatment details';
  @override String get trattamentoDetailLblMetodo => 'Application method';
  @override String get trattamentoDetailLblDataInizio => 'Start date';
  @override String get trattamentoDetailLblDataFine => 'End date';
  @override String get trattamentoDetailLblSospFino => 'Suspension until';
  @override String get trattamentoDetailLblArnieTrattate => 'Treated hives';
  @override String get trattamentoDetailLblBloccoCovata => 'Brood block';
  @override String get trattamentoDetailLblInizioBlocko => 'Block start';
  @override String get trattamentoDetailLblFineBlocko => 'Block end';
  @override String get trattamentoDetailLblMetodoBlocko => 'Method';
  @override String get trattamentoDetailLblNoteBlocko => 'Block notes';

  // Form
  @override String get trattamentoFormOfflineMsg =>
      'Offline mode - data updated at last access';
  @override String get trattamentoFormNewProductTitle => 'New product';
  @override String get trattamentoFormLblProductName => 'Product name *';
  @override String get trattamentoFormHintProductName => 'E.g. Oxalic acid, ApiLife VAR...';
  @override String get trattamentoFormLblPrincipioAttivo => 'Active ingredient *';
  @override String get trattamentoFormHintPrincipioAttivo =>
      'E.g. Oxalic acid, Thymol, Flumethrin...';
  @override String get trattamentoFormLblGiorniSosp => 'Suspension days';
  @override String get trattamentoFormHintGiorniSosp => '0 = no suspension';
  @override String get trattamentoFormLblDescrizione => 'Description (optional)';
  @override String get trattamentoFormBloccoCovataReq => 'Requires brood block';
  @override String get trattamentoFormLblDurataBlockco => 'Recommended block duration';
  @override String get trattamentoFormLblNote => 'Notes';
  @override String get trattamentoFormHintNote => 'Enter any notes (optional)';
  @override String get trattamentoFormApplicaTutto => 'Entire apiary';
  @override String get trattamentoFormApplicaSpecifiche => 'Specific hives';
  @override String get trattamentoFormSelectPrimaApiario => 'Select an apiary first';
  @override String get trattamentoFormNoArnie => 'No hives found in this apiary';
  @override String get trattamentoFormLblProdotto => 'Product / Treatment type';
  @override String get trattamentoFormDataInizio => 'Start date';
  @override String get trattamentoFormDataFine => 'End date (optional)';
  @override String get trattamentoFormBloccoCovataActive => 'Brood block active';
  @override String get trattamentoFormCreatedOk => 'Treatment created';
  @override String get trattamentoFormUpdatedOk => 'Treatment updated';
  @override String trattamentoFormNewProductError(String e) => 'Error creating product: $e';
  @override String get trattamentoFormSelectApiarioMsg => 'Select an apiary';
  @override String get trattamentoFormSelectTypeMsg => 'Select a treatment type';
  @override String get trattamentoFormSelectArnieMsg => 'Select at least one hive';
  @override String trattamentoFormError(String e) => 'Error: $e';
  @override String get trattamentoFormTitleNew => 'New Treatment';
  @override String get trattamentoFormTitleEdit => 'Edit Treatment';
  @override String get trattamentoFormBtnCreate => 'CREATE TREATMENT';
  @override String get trattamentoFormBtnUpdate => 'UPDATE TREATMENT';
  @override String get trattamentoFormBtnCreateProduct => 'Create';
  @override String get trattamentoFormLblApplica => 'Apply to';
  @override String get trattamentoFormHintProdotto => 'Select a product';
  @override String get trattamentoFormValidateCampoObbligatorio => 'Required field';
  @override String get trattamentoFormValidateNumeroGe0 => 'Enter an integer ≥ 0';
  @override String get trattamentoFormValidateNumeroGt0 => 'Enter an integer > 0';
  @override String get trattamentoFormLblDataInizioBlocco => 'Brood block start date';
  @override String get trattamentoFormLblDataFineBlocco => 'Brood block end date';
  @override String get trattamentoFormErrFirstDateBlocco => 'Set the block start date first';
  @override String get trattamentoFormLblMetodoBlocco => 'Block method';
  @override String get trattamentoFormHintMetodoBlocco => 'E.g. queen caging, queen removal...';
  @override String get trattamentoFormHintNoteBlocco => 'Additional details (optional)';
  @override String get trattamentoFormLblMetodoApplicazione => 'Application method';
  @override String get trattamentoFormLblNoteBloccoCovata => 'Brood block notes';

  // ── Fioritura screens ─────────────────────────────────────────────────────
  // List
  @override String get fiorituraListTitle => 'Blooms';
  @override String get fiorituraTabMie => 'My blooms';
  @override String get fiorituraTabCommunity => 'Community';
  @override String get fiorituraFabTooltip => 'Add bloom';
  @override String get fiorituraSearchHint => 'Search by plant or apiary...';
  @override String get fiorituraListNoData => 'No blooms found';
  @override String get fiorituraListLoadError => 'Error loading blooms';
  @override String fiorituraListDeleteMsg(String name) => 'Delete the bloom "$name"?';
  @override String get fiorituraDeleteTitle => 'Delete bloom';
  @override String get fiorituraDeletedOk => 'Bloom deleted';
  @override String fiorituraDeleteError(String e) => 'Deletion error: $e';
  @override String get fiorituraMenuEdit => 'Edit';
  @override String get fiorituraMenuDelete => 'Delete';
  @override String get fiorituraCardAttiva => 'Active';
  @override String get fiorituraCardNonAttiva => 'Inactive';
  @override String get fiorituraCardPubblica => 'Public';
  @override String fiorituraCardConferme(int n) => '$n confirmations';
  @override String get fiorituraCardTu => 'You';
  @override String fiorituraDateFrom(String date) => 'From $date';

  // Detail
  @override String get fiorituraDetailTitle => 'Bloom';
  @override String get fiorituraDetailNotFound => 'Bloom not found';
  @override String get fiorituraDetailTooltipEdit => 'Edit';
  @override String get fiorituraDetailConfirmOk => 'Confirmation recorded!';
  @override String get fiorituraDetailLblCommunity => 'Community';
  @override String get fiorituraDetailLblIntensity => 'Your intensity rating:';
  @override String get fiorituraDetailBtnRemove => 'Remove';
  @override String get fiorituraDetailLblPosizione => 'Location';
  @override String fiorituraDetailError(String e) => 'Error: $e';
  @override String get fiorituraDetailLblPeriodo => 'Period';
  @override String get fiorituraDetailLblRaggio => 'Radius';
  @override String get fiorituraDetailLblTipoPianta => 'Plant type';
  @override String get fiorituraDetailLblIntensitaStimata => 'Estimated intensity';
  @override String get fiorituraDetailLblVisibilita => 'Visibility';
  @override String get fiorituraDetailValPubblica => 'Public (community)';
  @override String get fiorituraDetailValPrivata => 'Private';
  @override String get fiorituraDetailLblSegnalata => 'Reported by';
  @override String get fiorituraDetailStatConfermanti => 'confirmers';
  @override String get fiorituraDetailStatIntensita => 'avg. intensity';
  @override String get fiorituraDetailConfermata => 'You confirmed this bloom';
  @override String get fiorituraDetailConfermaQuestion => 'Have you seen this bloom?';
  @override String get fiorituraDetailHintNota => 'Note (optional)';
  @override String get fiorituraDetailBtnAggiorna => 'Update confirmation';
  @override String get fiorituraDetailBtnConferma => 'Confirm sighting';

  // Form
  @override String get fiorituraFormTitleNew => 'New bloom';
  @override String get fiorituraFormTitleEdit => 'Edit bloom';
  @override String get fiorituraFormTooltipSave => 'Save';
  @override String get fiorituraFormLblPianta => 'Plant *';
  @override String get fiorituraFormLblTipoPianta => 'Plant type';
  @override String get fiorituraFormLblDataInizio => 'Start date *';
  @override String get fiorituraFormLblDataFine => 'End date';
  @override String get fiorituraFormLblRaggio => 'Radius (metres)';
  @override String get fiorituraFormLblIntensita => 'Bloom intensity';
  @override String get fiorituraFormLblNote => 'Notes';
  @override String get fiorituraFormVisibilitaTitle => 'Visible to community';
  @override String get fiorituraFormBtnUsePos => 'Use my current location';
  @override String get fiorituraFormHintNonSpecificato => 'Not specified';
  @override String get fiorituraFormHintNonValutata => 'Not rated';
  @override String get fiorituraFormErrDataInizio => 'Enter the start date';
  @override String get fiorituraFormErrPosition => 'Select the position on the map';
  @override String fiorituraFormError(String e) => 'Error: $e';
  @override String get fiorituraFormVisibilitaSubtitle => 'Share this bloom with all beekeepers';
  @override String get fiorituraFormHintSeleziona => 'Select';
  @override String get fiorituraFormHintNessuna => 'None';
  @override String get fiorituraFormMapHint => 'Tap the map to set the bloom location';
  @override String get fiorituraFormTipoSpontanea => 'Wild';
  @override String get fiorituraFormTipoColtivata => 'Cultivated';
  @override String get fiorituraFormTipoAlberata => 'Tree-lined';
  @override String get fiorituraFormTipoArborea => 'Arboreal';
  @override String get fiorituraFormTipoArbustiva => 'Shrub';
  @override String get fiorituraFormIntensita1 => 'Poor';
  @override String get fiorituraFormIntensita2 => 'Decent';
  @override String get fiorituraFormIntensita3 => 'Good';
  @override String get fiorituraFormIntensita4 => 'Excellent';
  @override String get fiorituraFormIntensita5 => 'Exceptional';

  // ── Regina screens ────────────────────────────────────────────────────────
  // List
  @override String get reginaListTitle => 'My Queens';
  @override String get reginaListSyncTooltip => 'Sync data';
  @override String get reginaListBtnRetry => 'Retry loading';
  @override String reginaListItemTitle(String arniaNr) => 'Queen of hive $arniaNr';
  @override String get reginaListRazza => 'Breed';
  @override String get reginaListOrigine => 'Origin';
  @override String get reginaListIntrodotta => 'Introduced';
  @override String get reginaListMarcata => 'Marked';
  @override String get reginaListDetailError => 'Queen detail unavailable';
  @override String get reginaListOfflineTooltip => 'Offline mode - Data loaded from cache';
  @override String get reginaListEmptyTitle => 'No queens found';
  @override String get reginaListEmptySubtitle => 'Add queens from individual hive screens.';

  // Detail
  @override String get reginaDetailTitle => 'Queen Detail';
  @override String get reginaDetailNotFound => 'No data found for this queen';
  @override String reginaDetailTitleArnia(String arniaId) => 'Queen - Hive $arniaId';
  @override String get reginaDetailTooltipDelete => 'Delete queen';
  @override String get reginaDetailBtnEdit => 'Edit';
  @override String get reginaDetailBtnReplace => 'Replace';
  @override String get reginaDetailBtnRetry => 'Retry';
  @override String get reginaDetailDeleteTitle => 'Delete Queen';
  @override String get reginaDetailDeletedOk => 'Queen deleted successfully';
  @override String reginaDetailDeleteError(String e) => 'Error deleting: $e';
  @override String get reginaDetailReplaceTitle => 'Replace Queen';
  @override String get reginaDetailReplaceBtn => 'CONFIRM REPLACEMENT';
  @override String get reginaDetailLblMotivo => 'Reason';
  @override String get reginaDetailLblDataRimozione => 'Removal date';
  @override String get reginaDetailStatusAttuale => 'Current';
  @override String get reginaDetailLblDal => 'From';
  @override String get reginaDetailLblAl => 'To';
  @override String get reginaDetailLblMotivoCambio => 'Reason';
  @override String get reginaDetailStatusAttiva => 'Active';
  @override String get reginaDetailStatusNonAttiva => 'Inactive';
  @override String reginaDetailParentela(String parentela, String data) => '$parentela: $data';
  @override String reginaDetailError(String e) => 'Error: $e';
  @override String get reginaDetailTabDettagli => 'Details';
  @override String get reginaDetailTabGenealogia => 'Genealogy';
  @override String get reginaDetailSectionGeneral => 'General Information';
  @override String get reginaDetailSectionMarcatura => 'Marking';
  @override String get reginaDetailLblDataNascita => 'Birth date';
  @override String get reginaDetailLblSelezionata => 'Selected';
  @override String reginaDetailLblEta(String age) => 'Age: $age';
  @override String get reginaDetailAlberoGenealogia => 'Family Tree';
  @override String reginaDetailAlberoSubtitle(String arniaId) =>
      'Lineage of the queen in hive $arniaId';
  @override String get reginaDetailNoGenealogia => 'No genealogical data available';
  @override String get reginaDetailGenealogiaNonDisp => 'Genealogy data unavailable';
  @override String get reginaDetailReginaAttuale => 'Current Queen';
  @override String reginaDetailFiglie(int n) => 'Daughters ($n)';
  @override String get reginaDetailStoriaArnie => 'History in hives';
  @override String get reginaDetailInfoAggiuntive => 'Additional Information';
  @override String reginaDetailChipIntrodotta(String date) => 'Introduced: $date';
  @override String reginaDetailChipNata(String date) => 'Born: $date';
  @override String reginaDetailDeleteMsg(String arniaId) =>
      'Are you sure you want to delete the queen of hive $arniaId?\n\n'
      'This action cannot be undone.';
  @override String reginaDetailAgeAnni(int n) => '$n ${n == 1 ? 'year' : 'years'}';
  @override String reginaDetailAgeMesi(int n) => '$n ${n == 1 ? 'month' : 'months'}';
  @override String reginaDetailAgeGiorni(int n) => '$n ${n == 1 ? 'day' : 'days'}';
  @override String get reginaDetailColoreBianco => 'White (years ending in 1, 6)';
  @override String get reginaDetailColoreGiallo => 'Yellow (years ending in 2, 7)';
  @override String get reginaDetailColoreRosso => 'Red (years ending in 3, 8)';
  @override String get reginaDetailColoreVerde => 'Green (years ending in 4, 9)';
  @override String get reginaDetailColoreBlu => 'Blue (years ending in 5, 0)';
  @override String get reginaDetailColoreNonMarcata => 'Unmarked';

  // Form
  @override String get reginaFormTitleNew => 'Add Queen';
  @override String get reginaFormTitleEdit => 'Edit Queen';
  @override String get reginaFormLblRazza => 'Breed';
  @override String get reginaFormLblOrigine => 'Origin';
  @override String get reginaFormLblDataIntroduzione => 'Introduction date';
  @override String get reginaFormLblDataNascita => 'Birth date (optional)';
  @override String get reginaFormMarcataTitle => 'Marked';
  @override String get reginaFormLblColoreMarcatura => 'Marking colour';
  @override String get reginaFormFecondataTitle => 'Mated';
  @override String get reginaFormSelezionataTitle => 'Selected for breeding';
  @override String get reginaFormHintNessunaRegina => 'None (founder queen)';
  @override String get reginaFormBtnSave => 'SAVE QUEEN';
  @override String reginaFormError(String e) => 'Error: $e';
  @override String get reginaFormHintDataNascitaVuota => 'Not specified';
  @override String get reginaFormValutazioniTitle => 'Ratings (optional)';
  @override String get reginaFormValutazioniHint => 'Tap the stars to assign a score from 1 to 5.';
  @override String get reginaFormLblReginaMadre => 'Mother queen (optional)';
  @override String get reginaFormLblNote => 'Notes (optional)';
  @override String get reginaFormCreatedOk => 'Queen added successfully';
  @override String get reginaFormUpdatedOk => 'Queen updated successfully';
  @override String get reginaDetailSospettaAssenteMsg => 'WARNING: this queen has been reported absent in the last two controls. She may be dead.';
  @override String get reginaDetailLblCodiceMarcatura => 'Marking code';

  // ── Melario / Smielatura screens ──────────────────────────────────────────
  @override String get melariTitle => 'Honey Supers & Production';
  @override String get melariTooltipAdd => 'Add honey super';
  @override String get melariBtnNuovaSmielatura => 'New extraction';
  @override String get melariTabTutti => 'All';
  @override String get melariTabPersonali => 'Personal';
  @override String get melariNoSmielature => 'No extractions recorded';
  @override String get melariRiepilogoProd => 'Production Summary';
  @override String get melariKg => 'kg';
  @override String melariSmielaturaItem(String tipo, String qty) => '$tipo - $qty kg';
  @override String melariSmielaturaSubtitle(String date, String apiario, int count) =>
      '$date - $apiario - $count supers';
  @override String get melariCantinaTitolo => 'Honey cellar';
  @override String get melariCantinaSubtitle => 'Ripening · Storage · Jarring';
  @override String get melariNoInvasettamento => 'No jarring recorded';
  @override String get melariRiepilogoInvasettamento => 'Jarring Summary';
  @override String melariVasettiLabel(String formato) => '${formato}g jars';
  @override String get melariVasetti => 'jars';
  @override String melariInvasettamentoItem(String tipo, String formato, int num) =>
      '$tipo - ${formato}g x$num';
  @override String melariInvasettamentoSubtitle(String date, String kg, String? lotto) =>
      '$date - $kg kg${lotto != null ? ' - Batch: $lotto' : ''}';
  @override String get melariMenuEdit => 'Edit';
  @override String get melariMenuDelete => 'Delete';
  @override String get melariDeleteInvasettTitle => 'Confirm deletion';
  @override String get melariDeleteInvasettMsg => 'Delete this jarring record?';
  @override String get melariDeleteInvasettOk => 'Jarring deleted';
  @override String melariDeleteInvasettError(String e) => 'Error: $e';
  @override String get melariRemoveMelarioTitle => 'Remove honey super';
  @override String get melariRemoveMelarioDialogTitle => 'Remove honey super';
  @override String get melariEliminaMelarioTitle => 'Delete honey super';
  @override String get melariLblPesoStimato => 'Estimated weight (kg)';
  @override String get melariNoData => 'No data available';
  @override String get melariMelarioLabel => 'Honey super';
  @override String melariArniaLabel(String num) => 'Hive #$num';
  @override String get melariPosizionati => 'Placed';
  @override String get melariInSmielatura => 'In extraction';
  @override String melariMelarioId(int id) => 'Super #$id';
  @override String melariTelainiPosizione(int telaini, int posizione, String tipo) =>
      '$telaini frames · Position $posizione · $tipo';
  @override String get melariSmielBtn => 'Extract';
  @override String get melariQeLabel => 'QE';
  // Melari screen extra
  @override String get melariTabAlveari => 'Hives';
  @override String get melariTabSmielature => 'Extractions';
  @override String get melariSummaryTotale => 'Total';
  @override String get melariSummarySmielature => 'Extractions';
  @override String get melariSummaryTipi => 'Types';
  @override String get melariSummaryInvasettato => 'Jarred';
  @override String get melariSummaryRaccolto => 'Harvested';
  @override String get melariAnnoTutti => 'All';
  @override String get melariSummaryVasetti => 'Jars';
  @override String melariSummaryVasettiFormato(int formato, int n) => '${formato}g: $n jars';
  @override String get melariHiveLegendNido => 'Brood';
  @override String get melariHiveLegendPosizionato => 'Placed';
  @override String get melariHiveLegendInSmielatura => 'In extraction';
  @override String get melariHiveLblNido => '🐝 BROOD';
  @override String get melariNoMelari => 'no supers';
  @override String melariCountMelari(int n) => '$n super${n == 1 ? '' : 's'}';
  @override String melariArniaNumLabel(int n) => 'Hive #$n';
  @override String melariFaviLabel(int n) => '🍯 $n frames';
  @override String melariPosTipoLabel(int pos, String tipo) => 'Pos. $pos · $tipo';
  @override String melariTelainiLabel(int n) => '$n frames';
  @override String melariPesoStimatoLabel(String peso) => 'Est. weight: $peso kg';
  @override String get melariRemoveMelarioMsg => 'Confirm removing this super?';
  @override String melariDeleteMelarioMsg(int id) => 'Delete super #$id?';
  @override String get melariDeleteMelarioOk => 'Super deleted';
  @override String melariDeleteMelarioError(String e) => 'Super deletion error: $e';
  @override String melariRemoveMelarioError(String e) => 'Super removal error: $e';
  @override String get melariConfirmBtn => 'Confirm';
  @override String get melariMiniMapTitle => 'Hive positions';
  @override String get melariMiniMapNoLayout => 'No layout: open the apiary map to place hives';
  @override String get melariMiniMapTapHint => 'Tap a hive to highlight it';
  // Melario form
  @override String get melarioFormTitle => 'New Super';
  @override String get melarioFormSectionId => 'Identification & Traceability';
  @override String get melarioFormSectionProd => 'Production Data';
  @override String get melarioFormLblTipo => 'Super Type';
  @override String get melarioFormLblStatoFavi => 'Frame Condition';
  @override String get melarioFormLblNumTelaini => 'Number of Frames';
  @override String get melarioFormLblPosizione => 'Position (from brood box)';
  @override String get melarioFormLblEscludiRegina => 'Queen Excluder';
  @override String get melarioFormSubEscludiRegina => 'Place a queen excluder to prevent brood';
  @override String get melarioFormLblNote => 'Additional notes';
  @override String get melarioFormHintNote => 'Observations, ongoing bloom...';
  @override String get melarioFormBtnAdd => 'Add Super';
  @override String get melarioFormFaviCostruiti => 'Already built';
  @override String get melarioFormFaviCerei => 'Wax foundation';
  @override String get melarioFormLblDataPos => 'Placement date';
  @override String get melarioFormHintSelectApiario => 'Select an apiary first';
  @override String get melarioFormNoArnie => 'No hives available';
  @override String get melarioFormValidateArnia => 'Select a hive';
  @override String melarioFormLoadError(String e) => 'Loading error: $e';
  @override String melarioFormArnieLoadError(String e) => 'Hive loading error: $e';
  @override String get melarioFormCreatedOk => 'Super added successfully';
  @override String get melarioFormTitleEdit => 'Edit Super';
  @override String get melarioFormBtnUpdate => 'Save changes';
  @override String get melarioFormUpdatedOk => 'Super updated successfully';
  @override String get melarioFormNoColoniaError => 'No active colony on the selected hive: the super cannot be placed.';
  @override String smielaturaFormMelarioDates(String immissione, String rimozione) => 'Placement: $immissione - Removal: $rimozione';
  // Smielatura form extra
  @override String get smielaturaFormLblMelariDisp => 'Available supers';
  @override String get smielaturaFormValidateNumero => 'Enter a valid number';
  @override String get smielaturaFormValidateQuantitaMax => 'Quantity cannot exceed 99999.99 kg';
  @override String get smielaturaFormSelectMelarioMsg => 'Select at least one super';
  @override String get smielaturaFormNoMelariDisp => 'No supers in "in extraction" state for this apiary. To make one available, open a placed super from the Supers screen and tap "Remove".';
  @override String get smielaturaFormBtnCreate => 'REGISTER';
  @override String get smielaturaFormBtnUpdate => 'UPDATE';
  @override String get smielaturaFormCreatedOk => 'Extraction registered';
  @override String get smielaturaFormUpdatedOk => 'Extraction updated';
  // Smielatura detail
  @override String get smielaturaDetailTitle => 'Extraction Detail';
  @override String get smielaturaDetailDeleteTitle => 'Delete extraction';
  @override String get smielaturaDetailDeleteMsg => 'Are you sure you want to delete this extraction?';
  @override String get smielaturaDetailDeletedOk => 'Extraction deleted';
  @override String get smielaturaDetailNotFound => 'Extraction not found';
  @override String smielaturaDetailMelariCount(int n) => '$n super${n == 1 ? '' : 's'}';
  @override String get smielaturaDetailMelariAssociati => 'Associated supers';
  @override String get smielaturaDetailLblMelari => 'Supers';

  // Smielatura form
  @override String get smielaturaFormTitleNew => 'New Extraction';
  @override String get smielaturaFormTitleEdit => 'Edit Extraction';
  @override String get smielaturaFormLblApiario => 'Apiary *';
  @override String get smielaturaFormLblData => 'Date *';
  @override String get smielaturaFormLblTipoMiele => 'Honey type *';
  @override String get smielaturaFormLblQuantita => 'Honey quantity (kg) *';
  @override String get smielaturaFormLblNote => 'Notes';
  @override String smielaturaFormMelarioItem(int id, String arniaNum) =>
      'Super #$id - Hive $arniaNum';
  @override String smielaturaFormMelarioStato(String stato) => 'Status: $stato';
  @override String get smielaturaFormSelectApiarioMsg => 'Select an apiary';
  @override String smielaturaFormError(String e) => 'Error loading data: $e';
  @override String get smielaturaFormOfflineMsg =>
      'Offline mode - data updated at last access';
  // Invasettamento form
  @override String get invasettamentoFormTitleNew => 'New Jarring';
  @override String get invasettamentoFormTitleEdit => 'Edit Jarring';
  @override String get invasettamentoFormLblSmielatura => 'Extraction *';
  @override String get invasettamentoFormValidateSmielatura => 'Select an extraction';
  @override String get invasettamentoFormCreatedOk => 'Jarring registered';
  @override String get invasettamentoFormUpdatedOk => 'Jarring updated';
  @override String get invasettamentoFormLblFormato => 'Jar format *';
  @override String get invasettamentoFormLblNumVasetti => 'Number of jars *';
  @override String get invasettamentoFormValidateNumVasetti => 'Enter a whole number';
  @override String invasettamentoFormLblTotale(String kg) => 'Total: $kg kg';
  @override String get invasettamentoFormLblLotto => 'Batch';

  // ── Controllo form (legacy keys) ──────────────────────────────────────────
  @override String get controlloFormDialogTitle => 'Hive Inspection';
  @override String get controlloFormBtnAutoOrdina => 'Auto-arrange';
  @override String get controlloFormLblNumCelleReali => 'Number of queen cells';
  @override String get controlloFormLblNoteSciamatura => 'Swarm notes';
  @override String get controlloFormLblDettagliProblemi => 'Health issue details';
  @override String get controlloFormLblColore => 'Marking colour';
  @override String get controlloFormToccoTelaino => 'Tap a frame to change its type';

  // ── Dashboard Screen ─────────────────────────────────────────────────────
  @override String get dashSyncing => 'Syncing...';
  @override String get dashSyncDone => 'Data updated!';
  @override String get dashExitTitle => 'Exit app?';
  @override String get dashExitMessage => 'Do you want to close the application?';
  @override String get dashExitCancel => 'Cancel';
  @override String get dashExitConfirm => 'Exit';
  @override String get dashTitle => 'Dashboard';
  @override String get dashSearchHint => 'Search...';
  @override String get dashSearchTooltip => 'Search';
  @override String get dashCloseSearchTooltip => 'Close search';
  @override String dashWelcomeUser(String name) => 'Welcome, $name';
  @override String get dashContextualHint =>
      '👋 Here you\'ll find a summary of all activities - hives, recent inspections and harvests. Tap a section to open it.';
  @override String get dashCalendarTitle => 'Activity calendar';
  @override String get dashCalendarToday => 'Today';
  @override String get dashCalendarPrevWeek => 'Previous week';
  @override String get dashCalendarNextWeek => 'Next week';
  @override String get dashCalendarPrevMonth => 'Previous month';
  @override String get dashCalendarNextMonth => 'Next month';
  @override String get dashCalendarViewMonth => 'Month';
  @override String get dashCalendarViewWeek => 'Week';
  @override String get dashCalendarLegendControlli => 'Inspections';
  @override String get dashCalendarLegendTrattamenti => 'Treatments';
  @override String get dashCalendarLegendFioriture => 'Blooms';
  @override String get dashCalendarLegendRegine => 'Queens';
  @override String get dashCalendarLegendMelari => 'Honey supers';
  @override String get dashCalendarLegendSmielature => 'Extractions';
  @override String get dashCalendarLegendSospensione => 'Suspension';
  @override String get dashCalendarLegendBloccoCovata => 'Brood block';
  @override String dashCalendarTodayDate(String date) => 'Today - $date';
  @override String dashCalendarDateEvents(String date) => 'Events on $date';
  @override String get dashCalendarNoEventsToday => 'No activities planned for today.';
  @override String get dashCalendarNoEvents => 'No events for this day.';
  @override List<String> get dashWeekdayAbbr =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  @override String get dashEventTrattamento => 'Treatment';
  @override String get dashEventSospensione => 'Suspension';
  @override String get dashEventBloccoCovata => 'Brood block';
  @override String get dashEventFioritura => 'Bloom';
  @override String dashEventControlloArnia(String num) => 'Hive inspection $num';
  @override String get dashEventReginaIntrodotta => 'Queen introduced';
  @override String get dashEventArniaSep => ' - hive ';
  @override String get dashEventMelarioPosizionato => 'Honey super placed';
  @override String get dashEventMelarioRimosso => 'Honey super removed';
  @override String get dashEventSmielatura => 'Extraction';
  @override String get dashSectionApiari => 'Your apiaries';
  @override String get dashSectionTrattamenti => 'Active health treatments';
  @override String get dashSectionFioriture => 'Active blooms';
  @override String get dashBtnViewAll => 'View all';
  @override String get dashBtnCreateApiario => 'Create new apiary';
  @override String get dashNoApiari => 'No apiaries available';
  @override String get dashNoTrattamenti => 'No active treatments';
  @override String get dashNoFioriture => 'No active blooms';
  @override String dashLoadError(String err) => 'Error loading data: $err';
  @override String get dashAlertsTitle => 'Alerts & suggestions';
  @override String get dashAlertViewDetails => 'View details';
  @override String get dashAlertTrattamentoExpiringTitle => 'Treatment expiring soon';
  @override String dashAlertTrattamentoExpiringMsg(String nome, int days) =>
      'The treatment "$nome" will expire in $days day${days == 1 ? '' : 's'}.';
  @override String get dashAlertApiarioToVisitTitle => 'Apiary needs a visit';
  @override String dashAlertApiarioToVisitMsg(String nome) =>
      'Apiary "$nome" has not been visited for over 14 days.';
  @override String get dashWeatherLocal => 'Local weather';
  @override String dashWeatherHumidity(String pct) => 'Humidity: $pct%';
  @override String get dashPositionNone => 'Location not specified';
  @override String get dashStatusNd => 'N/A';
  @override String get dashStatusInCorso => 'Active';
  @override String get dashStatusProgrammato => 'Scheduled';
  @override String get dashStatusCompletato => 'Completed';
  @override String get dashStatusApiario => 'Apiary';
  @override String dashTrattamentoDates(String start, String end) => 'From $start to $end';
  @override String get dashFiorituraAttiva => 'Active';
  @override String get dashFiorituraTerminata => 'Ended';
  @override String dashFiorituraDates(String start, String? end) =>
      'From $start${end != null ? ' to $end' : ''}';
  @override String dashSearchNoResults(String query) =>
      'No results found for "$query"';
  @override String dashSearchSection(String label, int count) => '$label ($count)';
  @override String get dashFabVoiceInput => 'Voice input';
  @override String get dashFabAiAssistant => 'ApiarioAI Assistant';
  @override String get dashFabScanQr => 'Scan QR';
  @override String get dashFabScanNfc => 'Scan NFC';
  @override String get nfcNotAvailable => 'NFC not available on this device';
  @override String get nfcScanning => 'Bring the tag near the device…';
  @override String get nfcTagNotFound => 'No hive associated with this tag';
  @override String get nfcError => 'Error reading NFC tag';
  @override String get dashFabNewApiario => 'New Apiary';

  @override String get sectionNfc => 'NFC Action';
  @override String get nfcSettingsSubtitle => 'What the app does when you scan an NFC chip on a hive';
  @override String get nfcActionManual => 'Manual inspection';
  @override String get nfcActionManualDesc => 'Opens the manual inspection entry form';
  @override String get nfcActionVoice => 'Voice inspection';
  @override String get nfcActionVoiceDesc => 'Starts voice recording with the hive number already set';

  @override String get nfcChipPairing => 'NFC Chip';
  @override String get nfcChipAssigned => 'Chip assigned';
  @override String get nfcChipNone => 'No chip assigned';
  @override String get nfcScanToAssign => 'Assign chip';
  @override String get nfcChipRemoveBtn => 'Remove';
  @override String get nfcChipAssignSuccess => 'NFC chip assigned successfully';
  @override String get nfcChipScanFailed => 'No chip detected';

  @override String nfcVoiceBanner(int arniaNumero, String apiarioNome) =>
      'Voice inspection · Hive $arniaNumero · $apiarioNome';
  @override String get nfcVoiceBannerHint => 'Hive number will be added automatically to your dictation';

  // ── Auth – Login Screen ───────────────────────────────────────────────────
  @override String get loginSubtitle => 'Sign in to manage your apiaries';
  @override String get loginFieldUsernameLabel => 'Username or Email';
  @override String get loginFieldUsernameHint => 'Enter your username or email';
  @override String get loginFieldUsernameValidate => 'Enter your username or email';
  @override String get loginFieldPasswordLabel => 'Password';
  @override String get loginFieldPasswordHint => 'Enter your password';
  @override String get loginFieldPasswordValidate => 'Enter your password';
  @override String get loginForgotPassword => 'Forgot your password?';
  @override String get loginBtnAccedi => 'SIGN IN';
  @override String get loginOr => 'or';
  @override String get loginBtnGoogle => 'Continue with Google';
  @override String get loginBtnRegister => 'Don\'t have an account? Register';
  @override String get loginErrUserNotFound => 'Username or email not found. Don\'t have an account yet?';
  @override String get loginErrWrongPassword => 'Incorrect password.';
  @override String get loginErrWrongCredentials => 'Invalid credentials. Check your username/email and password.';
  @override String get loginErrGoogleAuth => 'Google sign-in failed. Please try again.';
  @override String get loginErrGoogleToken => 'Could not obtain Google token. Please try again.';
  @override String get loginErrNetwork => 'Cannot connect to server. Check your internet connection.';
  @override String get loginErrTimeout => 'Server is not responding. Please try again in a moment.';
  @override String get loginErrServer => 'Internal server error. Please try again later.';
  @override String get loginErrDefault => 'An error occurred. Please try again.';
  @override String get loginHintForgotPassword => 'Forgot your password?';
  @override String get loginHintRegister => 'Don\'t have an account? Register now';

  // ── Auth – Register Screen ────────────────────────────────────────────────
  @override String get registerTitle => 'Register';
  @override String get registerCreateAccount => 'Create an account';
  @override String get registerFieldUsername => 'Username';
  @override String get registerHintUsername => 'Enter a username';
  @override String get registerValidateUsername => 'Enter a username';
  @override String get registerFieldEmail => 'Email';
  @override String get registerHintEmail => 'Enter your email';
  @override String get registerValidateEmail => 'Enter an email';
  @override String get registerValidateEmailFormat => 'Enter a valid email';
  @override String get registerFieldPassword => 'Password';
  @override String get registerHintPassword => 'Enter a password';
  @override String get registerValidatePassword => 'Enter a password';
  @override String get registerValidatePasswordLength => 'Password must be at least 8 characters';
  @override String get registerFieldConfirmPassword => 'Confirm Password';
  @override String get registerHintConfirmPassword => 'Confirm your password';
  @override String get registerValidateConfirmPassword => 'Confirm your password';
  @override String get registerValidatePasswordMatch => 'Passwords do not match';
  @override String get registerErrPasswordMismatch => 'Passwords do not match.';
  @override String get registerErrPrivacyRequired => 'You must accept the Privacy Policy to proceed.';
  @override String get registerPrivacyText => 'I have read and accept the ';
  @override String get registerPrivacyLink => 'Privacy Policy';
  @override String get registerBtnRegister => 'REGISTER';
  @override String get registerBtnLogin => 'Already have an account? Sign in';
  @override String get registerSuccessMsg => 'Registration complete. You can now sign in.';
  @override String get registerErrGeneric => 'Error during registration.';
  @override String get registerErrNetwork => 'Connection error. Please try again later.';

  // ── Auth – Forgot Password Screen ─────────────────────────────────────────
  @override String get forgotPasswordTitle => 'Forgot password';
  @override String get forgotPasswordResetTitle => 'Reset your password';
  @override String get forgotPasswordSubtitle =>
      'Enter the email address associated with your account. We\'ll send you a link to reset your password.';
  @override String get forgotPasswordFieldEmail => 'Email';
  @override String get forgotPasswordHintEmail => 'Enter your email';
  @override String get forgotPasswordValidateEmail => 'Enter your email';
  @override String get forgotPasswordValidateEmailFormat => 'Enter a valid email address';
  @override String get forgotPasswordBtnSend => 'SEND LINK';
  @override String get forgotPasswordBtnBack => 'Back to login';
  @override String get forgotPasswordSuccessTitle => 'Email sent!';
  @override String forgotPasswordSuccessBody(String email) =>
      'We\'ve sent password reset instructions to:\n$email\n\nAlso check your spam folder.';
  @override String get forgotPasswordBtnBackToLogin => 'BACK TO LOGIN';
  @override String get forgotPasswordBtnRetry => 'I didn\'t receive the email - try again';

  // ── Colonia screens ───────────────────────────────────────────────────────
  @override String get coloniaDetailTitle => 'Colony';
  @override String get coloniaDetailNotFound => 'Colony not found';
  @override String get coloniaDetailTabInfo => 'Info';
  @override String get coloniaDetailTabControlli => 'Inspections';
  @override String get coloniaDetailMenuChiudi => 'Close lifecycle';
  @override String get coloniaDetailLblContenitore => 'Container';
  @override String get coloniaDetailLblApiario => 'Apiary';
  @override String get coloniaDetailLblInsediataIl => 'Established on';
  @override String get coloniaDetailLblChiusaIl => 'Closed on';
  @override String get coloniaDetailLblMotivoFine => 'Reason for closure';
  @override String get coloniaDetailSectionRegina => 'Queen';
  @override String get coloniaDetailLblRazza => 'Breed';
  @override String get coloniaDetailLblOrigine => 'Origin';
  @override String get coloniaDetailLblIntrodottaIl => 'Introduced on';
  @override String get coloniaDetailLblOrigineDa => 'Origin from colony';
  @override String get coloniaDetailLblConfluitaIn => 'Merged into';
  @override String get coloniaDetailLblTotaleControlli => 'Total inspections';
  @override String get coloniaDetailSectionNote => 'Notes';
  @override String get coloniaDetailNoControlli => 'No inspections recorded';
  @override String coloniaId(int id) => 'Colony #$id';
  @override String coloniaOrigineDaId(int id) => 'Colony #$id';
  @override String coloniaConfluitaInId(int id) => 'Colony #$id';
  @override String coloniaControlloSubtitle(int scorte, int covata) => 'Stores: $scorte · Brood: $covata';
  @override String get coloniaControlloSciamatura => ' · ⚠ Swarm';

  // Colonia form
  @override String get coloniaFormTitle => 'Establish new colony';
  @override String get coloniaFormLblData => 'Establishment date *';
  @override String get coloniaFormHintData => 'Format: YYYY-MM-DD';
  @override String get coloniaFormValidateData => 'Enter the date';
  @override String get coloniaFormLblNote => 'Notes';
  @override String get coloniaFormCreatedOk => 'Colony established successfully';
  @override String get coloniaFormErrorSave => 'Error while saving';
  @override String coloniaFormError(String e) => 'Error: $e';

  // Colonia chiudi
  @override String coloniaChiudiTitle(int id) => 'Close Colony #$id';
  @override String get coloniaChiudiWarning =>
      'This operation closes the lifecycle of the colony. '
      'All historical data (inspections, queen, honey supers) will be preserved.';
  @override String get coloniaChiudiLblStato => 'Reason for closure *';
  @override String get coloniaChiudiLblData => 'Closure date *';
  @override String get coloniaChiudiLblMotivo => 'Description (optional)';
  @override String get coloniaChiudiLblNote => 'Additional notes';
  @override String get coloniaChiudiValidateStato => 'Select a reason';
  @override String get coloniaChiudiValidateData => 'Enter the date';
  @override String get coloniaChiudiBtn => 'Close';
  @override String get coloniaChiusaOk => 'Lifecycle closed';
  @override String coloniaChiudiError(String e) => 'Error: $e';
  @override String get coloniaStatoMorta => 'Colony dead';
  @override String get coloniaStatoVenduta => 'Transferred / Sold';
  @override String get coloniaStatoSciamata => 'Swarmed and not recovered';
  @override String get coloniaStatoUnita => 'Merged with another colony';
  @override String get coloniaStatoNucleo => 'Reduced to nucleus';
  @override String get coloniaStatoEliminata => 'Eliminated';

  // Storia colonie
  @override String get storiaColonieTitle => 'Colony history';
  @override String get storiaColonieEmpty => 'No historical colonies';
  @override String storiaColonieItem(int id, String stato) => 'Colony #$id · $stato';
  @override String storiaColonieDates(String start, String? end) =>
      'From $start${end != null ? ' to $end' : ''}';
  @override String get storiaColonieInCorso => ' · ongoing';

  // ── Attrezzatura screens ──────────────────────────────────────────────────
  @override String get attrezzatureTitle => 'Equipment';
  @override String get attrezzatureFiltriAvanzatiTooltip => 'Advanced filters';
  @override String get attrezzatureSincronizzaTooltip => 'Sync';
  @override String get attrezzaturaSearchHint => 'Search by name, brand, model…';
  @override String get attrezzaturaCatTutti => 'All';
  @override String get attrezzaturaCatTutte => 'All';
  @override String get attrezzaturaCatConsumabili => 'Consumables';
  @override String get attrezzaturaCatProtezione => 'Protection';
  @override String get attrezzaturaCatStrumenti => 'Tools';
  @override String get attrezzaturaCatAltro => 'Other';
  @override String attrezzaturaQta(int n) => 'Qty: $n';
  @override String attrezzaturaAcquistatoDate(String d) => 'Purchased: $d';
  @override String get attrezzaturaNoRegistrata => 'No equipment registered';
  @override String get attrezzaturaNoFiltri => 'No equipment matches the filters';
  @override String get attrezzaturaBtnAggiungi => 'Add Equipment';
  @override String get attrezzaturaBtnRimuoviFiltri => 'Remove filters';
  @override String get attrezzaturaFiltriAvanzatiTitle => 'Advanced filters';
  @override String get attrezzaturaFiltriReset => 'Reset';
  @override String get attrezzaturaFiltriLblStato => 'Status';
  @override String get attrezzaturaFiltriLblCondizione => 'Condition';
  @override String get attrezzaturaFiltriLblDataAcquisto => 'Purchase date';
  @override String get attrezzaturaFiltriLblPrezzo => 'Purchase price (€)';
  @override String get attrezzaturaFiltriApplica => 'Apply filters';
  @override String get attrezzaturaFabTooltip => 'New Equipment';
  @override String get attrezzaturaErrLoading => 'Error loading data';

  @override String get attrezzaturaDetailTitle => 'Equipment Detail';
  @override String get attrezzaturaDetailTabInfo => 'Info';
  @override String get attrezzaturaDetailTabSpese => 'Expenses';
  @override String get attrezzaturaDetailTabManutenzioni => 'Maintenance';
  @override String get attrezzaturaDetailNonCategorizzato => 'Uncategorized';
  @override String get attrezzaturaDetailLblCondizione => 'Condition';
  @override String get attrezzaturaDetailLblDescrizione => 'Description';
  @override String get attrezzaturaDetailLblMarca => 'Brand';
  @override String get attrezzaturaDetailLblModello => 'Model';
  @override String get attrezzaturaDetailLblSerie => 'Serial No.';
  @override String get attrezzaturaDetailLblQuantita => 'Quantity';
  @override String get attrezzaturaDetailLblUnitaMisura => 'Unit of measure';
  @override String get attrezzaturaDetailLblDataAcquisto => 'Purchase date';
  @override String get attrezzaturaDetailLblPrezzoAcquisto => 'Purchase price';
  @override String get attrezzaturaDetailLblFornitore => 'Supplier';
  @override String get attrezzaturaDetailLblGaranzia => 'Warranty until';
  @override String get attrezzaturaDetailLblPosizione => 'Location';
  @override String get attrezzaturaDetailLblGruppo => 'Group';
  @override String get attrezzaturaDetailStatistiche => 'Statistics';
  @override String get attrezzaturaDetailSpeseTotali => 'Total Expenses';
  @override String get attrezzaturaDetailNessunaSpesa => 'No expenses recorded';
  @override String get attrezzaturaDetailBtnAggiungiSpesa => 'Add Expense';
  @override String get attrezzaturaDetailNessunaManutenzione => 'No maintenance recorded';
  @override String get attrezzaturaDetailBtnAggiungiManutenzione => 'Add Maintenance';
  @override String get attrezzaturaDetailInRitardo => ' Overdue';
  @override String attrezzaturaDetailProgrammata(String d) => 'Scheduled: $d';
  @override String get attrezzaturaDetailMenuAddSpesaTitle => 'Add Expense';
  @override String get attrezzaturaDetailMenuAddSpesaSubtitle => 'Record a new expense for this equipment';
  @override String get attrezzaturaDetailMenuAddManutenzioneTitle => 'Add Maintenance';
  @override String get attrezzaturaDetailMenuAddManutenzioneSubtitle => 'Schedule or record a maintenance';
  @override String get attrezzaturaDeleteTitle => 'Delete Equipment';
  @override String get attrezzaturaDeletedOk => 'Equipment deleted successfully';
  @override String attrezzaturaDeleteError(String e) => 'Error during deletion: $e';
  @override String get attrezzaturaDeleteSpesaTitle => 'Delete Expense';
  @override String get attrezzaturaDeleteSpesaOk => 'Expense deleted successfully';
  @override String attrezzaturaDeleteSpesaError(String e) => 'Error during deletion: $e';
  @override String get attrezzaturaDeleteManutenzioneTitle => 'Delete Maintenance';
  @override String get attrezzaturaDeleteManutenzioneOk => 'Maintenance deleted successfully';
  @override String attrezzaturaDeleteManutenzioneError(String e) => 'Error during deletion: $e';
  @override String get attrezzaturaErrDetailLoading => 'Error loading data';
  @override String get attrezzaturaEliminaSpesaTooltip => 'Delete expense';
  @override String get attrezzaturaEliminaManutenzioneTooltip => 'Delete maintenance';

  // ── Vendita screens ───────────────────────────────────────────────────────
  @override String get venditeTitle => 'Sales';
  @override String get venditeTabVendite => 'Sales';
  @override String get venditeTabClienti => 'Clients';
  @override String get venditeOfflineMsg => 'Offline mode - data from last access';
  @override String get venditeNoVendite => 'No sales recorded';
  @override String get venditeNoClienti => 'No clients registered';
  @override String get venditeErrLoading => 'Error loading data';
  @override String venditeArticoli(int n) => '$n item${n == 1 ? '' : 's'}';
  @override String venditeClienteVendite(int n) => '$n sale${n == 1 ? '' : 's'}';
  @override String get venditeTooltipSync => 'Sync';
  @override String get venditeFabTooltip => 'New sale';
  @override String get venditeClientiFabTooltip => 'New client';

  // ── Gruppo screens ────────────────────────────────────────────────────────
  @override String get gruppiTitle => 'Groups';
  @override String get gruppiFabTooltip => 'Create new group';
  @override String get gruppiInvitoAccettato => 'Invitation accepted';
  @override String get gruppiInvitoRifiutato => 'Invitation declined';
  @override String gruppiInvitoError(String e) => 'Error: $e';
  @override String get gruppiBtnRifiuta => 'DECLINE';
  @override String get gruppiBtnAccetta => 'ACCEPT';
  @override String get gruppiBtnCrea => 'Create a new group';
  @override String get gruppiErrLoading => 'Error loading group';
  @override String get gruppiBtnRiprova => 'RETRY';
  @override String get gruppiTuoiGruppi => 'Your groups';
  @override String get gruppiInvitiRicevuti => 'Received invitations';
  @override String get gruppiNoMembro => 'You are not a member of any group';
  @override String gruppiInvitatoDa(String user, String ruolo) => 'You were invited by $user with the role of $ruolo';
  @override String gruppiDataInvio(String d) => 'Sent on: $d';
  @override String gruppiScadeIl(String d) => 'Expires on: $d';
  @override String gruppiMembriCount(int n) => '$n member${n == 1 ? '' : 's'}';
  @override String gruppiApiariCondivisi(int n) => '$n shared apiar${n == 1 ? 'y' : 'ies'}';
  @override String get gruppiErrLoadingGruppi => 'Error loading groups';

  // ── Attrezzatura form ─────────────────────────────────────────────────────
  @override String get attrezzaturaFormTitleNew => 'New Equipment';
  @override String get attrezzaturaFormTitleEdit => 'Edit Equipment';
  @override String get attrezzaturaFormLblNome => 'Name *';
  @override String get attrezzaturaFormValidateNome => 'Enter the equipment name';
  @override String get attrezzaturaFormValidateCampoObbligatorio => 'Required field';
  @override String get attrezzaturaFormLblMarca => 'Brand';
  @override String get attrezzaturaFormLblModello => 'Model';
  @override String get attrezzaturaFormLblQuantita => 'Quantity *';
  @override String get attrezzaturaFormValidateQuantita => 'Enter the quantity';
  @override String get attrezzaturaFormValidateNumero => 'Enter a valid number';
  @override String get attrezzaturaFormLblStato => 'Status';
  @override String get attrezzaturaFormLblCondizione => 'Condition';
  @override String get attrezzaturaFormLblDataAcquisto => 'Purchase Date';
  @override String get attrezzaturaFormLblPrezzoAcquisto => 'Purchase Price (€)';
  @override String get attrezzaturaFormHelperPrezzo => 'If you enter a price, a payment will be created automatically';
  @override String get attrezzaturaFormValidateImporto => 'Enter a valid amount';
  @override String get attrezzaturaFormLblFornitore => 'Supplier';
  @override String get attrezzaturaFormSectionCondivisione => 'Sharing';
  @override String get attrezzaturaFormLblCondividi => 'Share with group';
  @override String get attrezzaturaFormSubCondividi => 'Expenses will be shared with group members';
  @override String get attrezzaturaFormLblChiHaPagato => 'Who paid?';
  @override String get attrezzaturaFormHintIoStesso => '- myself -';
  @override String get attrezzaturaFormHelperChiPaga => 'Indicate the group member who actually paid the expense';
  @override String get attrezzaturaFormLblNote => 'Notes';
  @override String get attrezzaturaFormInfoPagamento => 'If you enter a purchase price, a payment will be created automatically.';
  @override String get attrezzaturaFormBtnSalva => 'SAVE';
  @override String get attrezzaturaFormBtnAggiorna => 'UPDATE';
  @override String get attrezzaturaFormCreatedOk => 'Equipment created successfully';
  @override String get attrezzaturaFormUpdatedOk => 'Equipment updated successfully';
  @override String get attrezzaturaFormPagamentoAuto => 'Payment registered automatically';
  @override String attrezzaturaFormLoadError(String e) => 'Error loading data: $e';
  @override String attrezzaturaFormSaveError(String e) => 'Error saving data: $e';
  @override String get attrezzaturaStatoDisponibile => 'Available';
  @override String get attrezzaturaStatoInUso => 'In Use';
  @override String get attrezzaturaStatoManutenzione => 'Under Maintenance';
  @override String get attrezzaturaStatoDismesso => 'Decommissioned';
  @override String get attrezzaturaStatoPrestato => 'Loaned';
  @override String get attrezzaturaCondizioneNuovo => 'New';
  @override String get attrezzaturaCondizioneOttimo => 'Excellent';
  @override String get attrezzaturaCondizioneBuono => 'Good';
  @override String get attrezzaturaCondizioneDiscreto => 'Fair';
  @override String get attrezzaturaCondizioneUsurato => 'Worn';
  @override String get attrezzaturaCondizioneDaRiparare => 'Needs Repair';

  // ── Attrezzatura prompt (popup lite dopo creazione arnia) ────────────────
  @override String get attrezzaturaPromptTitle => 'Register as equipment?';
  @override String get attrezzaturaPromptBody => 'Track this item in your equipment inventory?';
  @override String get attrezzaturaPromptNome => 'Name';
  @override String get attrezzaturaPromptCondizione => 'Condition';
  @override String get attrezzaturaPromptPrezzo => 'Purchase price (optional)';
  @override String get attrezzaturaPromptSkip => 'Don\'t ask again';
  @override String get attrezzaturaPromptBtnNo => 'No thanks';
  @override String get attrezzaturaPromptBtnYes => 'Register';
  @override String get attrezzaturaPromptSuccess => 'Equipment registered!';
  @override String attrezzaturaPromptError(String e) => 'Registration error: $e';

  // ── Manutenzione form ─────────────────────────────────────────────────────
  @override String get manutenzioneFormTitle => 'New Maintenance';
  @override String get manutenzioneFormLblAttrezzatura => 'Equipment';
  @override String get manutenzioneFormLblTipo => 'Maintenance Type *';
  @override String get manutenzioneFormHintDescrizione => 'E.g.: Replace worn parts, General cleaning...';
  @override String get manutenzioneFormValidateDescrizione => 'Enter a description';
  @override String get manutenzioneFormLblDataProgrammata => 'Scheduled Date *';
  @override String get manutenzioneFormHintSelezionaData => 'Select date';
  @override String get manutenzioneFormLblDataEsecuzione => 'Execution Date';
  @override String get manutenzioneFormLblDataEsecuzioneReq => 'Execution Date *';
  @override String get manutenzioneFormLblCosto => 'Cost (€)';
  @override String get manutenzioneFormHelperCosto => 'If you enter a cost, a payment will be created automatically';
  @override String get manutenzioneFormLblEseguitoDa => 'Performed by';
  @override String get manutenzioneFormHintEseguitoDa => 'Name of who performed the maintenance';
  @override String get manutenzioneFormLblProssimaManutenzione => 'Next Maintenance';
  @override String get manutenzioneFormHintNonProgrammata => 'Not scheduled';
  @override String get manutenzioneFormLblNote => 'Notes (optional)';
  @override String get manutenzioneFormInfoPagamento => 'A payment and an expense will be created automatically for this maintenance.';
  @override String get manutenzioneFormInfoCondivisa => 'This maintenance will be shared with the group.';
  @override String get manutenzioneFormBtnProgramma => 'SCHEDULE MAINTENANCE';
  @override String get manutenzioneFormBtnRegistra => 'RECORD MAINTENANCE';
  @override String get manutenzioneFormCreatedOk => 'Maintenance recorded successfully';
  @override String get manutenzioneFormValidateDataProgrammata => 'Select the scheduled date';
  @override String get manutenzioneFormValidateDataEsecuzione => 'Select the execution date';
  @override String get manutenzioneFormTipoOrdinaria => 'Routine Maintenance';
  @override String get manutenzioneFormTipoStraordinaria => 'Extraordinary Maintenance';
  @override String get manutenzioneFormTipoRiparazione => 'Repair';
  @override String get manutenzioneFormTipoPulizia => 'Cleaning';
  @override String get manutenzioneFormTipoRevisione => 'Overhaul';
  @override String get manutenzioneFormTipoSostituzioneParti => 'Parts Replacement';
  @override String get manutenzioneFormStatoProgrammata => 'Scheduled';
  @override String get manutenzioneFormStatoInCorso => 'In Progress';
  @override String get manutenzioneFormStatoCompletata => 'Completed';
  @override String get manutenzioneFormStatoAnnullata => 'Cancelled';

  // ── Spesa attrezzatura form ───────────────────────────────────────────────
  @override String get spesaAttrezzaturaFormTitle => 'New Expense';
  @override String get spesaAttrezzaturaFormLblTipo => 'Expense Type *';
  @override String get spesaAttrezzaturaFormLblImporto => 'Amount (€) *';
  @override String get spesaAttrezzaturaFormValidateImporto => 'Enter the amount';
  @override String get spesaAttrezzaturaFormLblData => 'Date';
  @override String get spesaAttrezzaturaFormLblFornitore => 'Supplier';
  @override String get spesaAttrezzaturaFormHintFornitore => 'E.g.: Supplier name';
  @override String get spesaAttrezzaturaFormLblNumFattura => 'Invoice Number';
  @override String get spesaAttrezzaturaFormHintNumFattura => 'E.g.: INV-2024-001';
  @override String get spesaAttrezzaturaFormInfoPagamento => 'A payment will be created automatically for this expense.';
  @override String get spesaAttrezzaturaFormInfoCondivisa => 'This expense will be shared with the group.';
  @override String get spesaAttrezzaturaFormBtnSave => 'RECORD EXPENSE';
  @override String get spesaAttrezzaturaFormCreatedOk => 'Expense recorded and payment created automatically';
  @override String get spesaAttrezzaturaFormTipoAcquisto => 'Purchase';
  @override String get spesaAttrezzaturaFormTipoManutenzione => 'Maintenance';
  @override String get spesaAttrezzaturaFormTipoRiparazione => 'Repair';
  @override String get spesaAttrezzaturaFormTipoAccessori => 'Accessories';
  @override String get spesaAttrezzaturaFormTipoConsumabili => 'Consumables';
  @override String get spesaAttrezzaturaFormTipoAltro => 'Other';

  // ── Vendita form / detail ─────────────────────────────────────────────────
  @override String get venditaFormTitleNew => 'New Sale';
  @override String get venditaFormTitleEdit => 'Edit Sale';
  @override String get venditaFormLblAcquirente => 'Buyer';
  @override String get venditaFormBtnUsaClienteReg => 'Use registered client';
  @override String get venditaFormBtnNomeLibero => 'Free name';
  @override String get venditaFormLblClienteReg => 'Registered client';
  @override String get venditaFormHintNessuno => '- none -';
  @override String get venditaFormLblAcquirenteNome => 'Buyer name *';
  @override String get venditaFormValidateNome => 'Enter the name';
  @override String get venditaFormValidateAcquirente => 'Enter the buyer\'s name';
  @override String get venditaFormLblData => 'Date *';
  @override String get venditaFormSectionCanale => 'Sales channel';
  @override String get venditaFormSectionPagamento => 'Payment method';
  @override String get venditaFormSectionArticoli => 'Items';
  @override String get venditaFormBtnAddArticolo => 'Add item';
  @override String venditaFormTotale(String amount) => 'Total: $amount €';
  @override String get venditaFormLblCondividi => 'Share with group';
  @override String get venditaFormHintSoloPersonale => '- personal only -';
  @override String get venditaFormCreatedOk => 'Sale recorded';
  @override String get venditaFormUpdatedOk => 'Sale updated';
  @override String venditaFormArticoloLabel(int n) => 'Item $n';
  @override String get venditaFormLblTipoMiele => 'Honey type *';
  @override String get venditaFormValidateRequired => 'Required';
  @override String get venditaFormLblFormatoVasetto => 'Jar format';
  @override String get venditaFormLblQty => 'Qty *';
  @override String get venditaFormLblPrezzo => 'Price € *';
  @override String venditaFormSubtotale(String amount) => 'Subtotal: $amount €';
  @override String get venditaCanaleMercatino => 'Market';
  @override String get venditaCanaleNegozio => 'Shop';
  @override String get venditaCanalePrivato => 'Private';
  @override String get venditaCanaleOnline => 'Online';
  @override String get venditaCanaleAltro => 'Other';
  @override String get venditaPagamentoContanti => 'Cash';
  @override String get venditaPagamentoBonifico => 'Bank transfer';
  @override String get venditaPagamentoCarta => 'Card';
  @override String get venditaPagamentoAltro => 'Other';
  @override String get venditaCatMiele => 'Honey';
  @override String get venditaCatPropoli => 'Propolis';
  @override String get venditaCatCera => 'Wax';
  @override String get venditaCatPolline => 'Pollen';
  @override String get venditaCatPappaReale => 'Royal jelly';
  @override String get venditaCatNucleo => 'Nucleus';
  @override String get venditaCatRegina => 'Queen';
  @override String get venditaCatAltro => 'Other';
  @override String get venditaDetailTitle => 'Sale Detail';
  @override String get venditaDetailNotFound => 'Sale not found';
  @override String get venditaDetailOfflineMsg => 'Offline mode - data from last access';
  @override String get venditaDetailDeleteTitle => 'Confirm deletion';
  @override String get venditaDetailDeleteMsg => 'Delete this sale?';
  @override String get venditaDetailDeletedOk => 'Sale deleted';
  @override String get venditaDetailLblData => 'Date';
  @override String get venditaDetailLblAcquirente => 'Buyer';
  @override String get venditaDetailLblCanale => 'Channel';
  @override String get venditaDetailLblPagamento => 'Payment';
  @override String get venditaDetailSectionArticoli => 'Items';

  // ── Cliente form ──────────────────────────────────────────────────────────
  @override String get clienteFormTitleNew => 'New Client';
  @override String get clienteFormTitleEdit => 'Edit Client';
  @override String get clienteFormDeleteTitle => 'Confirm deletion';
  @override String get clienteFormDeleteMsg => 'Delete this client?';
  @override String get clienteFormDeletedOk => 'Client deleted';
  @override String get clienteFormLblNome => 'Name *';
  @override String get clienteFormLblTelefono => 'Phone';
  @override String get clienteFormLblEmail => 'Email';
  @override String get clienteFormLblIndirizzo => 'Address';
  @override String get clienteFormLblNote => 'Notes';
  @override String get clienteFormLblCondividi => 'Share with group';
  @override String get clienteFormHintSoloPersonale => '- personal only -';
  @override String get clienteFormBtnCreate => 'CREATE CLIENT';
  @override String get clienteFormBtnUpdate => 'UPDATE';
  @override String get clienteFormCreatedOk => 'Client created';
  @override String get clienteFormUpdatedOk => 'Client updated';

  // ── Gruppo form ───────────────────────────────────────────────────────────
  @override String get gruppoFormTitleNew => 'New Group';
  @override String get gruppoFormTitleEdit => 'Edit Group';
  @override String get gruppoFormCreatedOk => 'Group created successfully';
  @override String get gruppoFormUpdatedOk => 'Group updated successfully';
  @override String get gruppoFormSectionInfo => 'Group information';
  @override String get gruppoFormSubtitleNew => 'Create a new group to collaborate with other beekeepers. You can invite members and share apiaries.';
  @override String get gruppoFormSubtitleEdit => 'Edit the existing group\'s information.';
  @override String get gruppoFormLblNome => 'Group name *';
  @override String get gruppoFormHintNome => 'E.g. Tuscany Beekeeping';
  @override String get gruppoFormHintDescrizione => 'E.g. Group for managing apiaries in Tuscany';
  @override String get gruppoFormBtnCrea => 'CREATE GROUP';
  @override String get gruppoFormBtnSalva => 'SAVE CHANGES';

  // ── Gruppo invito screen ──────────────────────────────────────────────────
  @override String get gruppoInvitoTitle => 'Invite to group';
  @override String get gruppoInvitoNotFound => 'Group not found';
  @override String gruppoInvitoHeader(String nome) => 'Invite to group: $nome';
  @override String get gruppoInvitoSubtitle => 'Enter the email address of the person you want to invite.';
  @override String get gruppoInvitoLblEmail => 'Email *';
  @override String get gruppoInvitoHintEmail => 'Enter email address';
  @override String get gruppoInvitoLblRuolo => 'New member\'s role:';
  @override String get gruppoInvitoRuoloAdmin => 'Administrator';
  @override String get gruppoInvitoRuoloAdminDesc => 'Can manage members, invitations and edit the group';
  @override String get gruppoInvitoRuoloEditor => 'Editor';
  @override String get gruppoInvitoRuoloEditorDesc => 'Can edit data but not manage members';
  @override String get gruppoInvitoRuoloViewer => 'Viewer';
  @override String get gruppoInvitoRuoloViewerDesc => 'Can only view data without editing';
  @override String get gruppoInvitoBtnSend => 'SEND INVITATION';
  @override String get gruppoInvitoInfo => 'The invitation will be valid for 7 days. The person must have an account to accept it.';
  @override String get gruppoInvitoSentOk => 'Invitation sent successfully';

  // ── Gruppo detail screen ──────────────────────────────────────────────────
  @override String get gruppoDetailDefaultTitle => 'Group Detail';
  @override String get gruppoDetailNotFound => 'Group not found';
  @override String get gruppoDetailTabMembri => 'Members';
  @override String get gruppoDetailTabApiari => 'Apiaries';
  @override String get gruppoDetailTabInviti => 'Invitations';
  @override String get gruppoDetailTooltipInvita => 'Invite member';
  @override String get gruppoDetailTooltipModifica => 'Edit group';
  @override String get gruppoDetailBtnElimina => 'DELETE GROUP';
  @override String get gruppoDetailBtnLascia => 'LEAVE GROUP';
  @override String get gruppoDetailNoMembri => 'No members found';
  @override String get gruppoDetailRuoloAdmin => 'Administrator';
  @override String get gruppoDetailRuoloEditor => 'Editor';
  @override String get gruppoDetailRuoloViewer => 'Viewer';
  @override String get gruppoDetailRuoloCreatore => 'Creator';
  @override String get gruppoDetailCambiaRuoloTitle => 'Change role';
  @override String get gruppoDetailRuoloAdminDesc => 'Can manage members and invitations';
  @override String get gruppoDetailRuoloEditorDesc => 'Can edit data';
  @override String get gruppoDetailRuoloViewerDesc => 'Read only';
  @override String get gruppoDetailRuoloUpdated => 'Role updated';
  @override String get gruppoDetailRimuoviTitle => 'Remove member';
  @override String gruppoDetailRimuoviMsg(String username) => 'Are you sure you want to remove $username from the group?';
  @override String get gruppoDetailRimuoviBtnConfirm => 'REMOVE';
  @override String gruppoDetailRimosso(String username) => '$username removed from group';
  @override String get gruppoDetailEliminaTitle => 'Delete group';
  @override String get gruppoDetailEliminaMsg => 'Are you sure you want to delete this group? This action cannot be undone.';
  @override String get gruppoDetailEliminato => 'Group deleted';
  @override String get gruppoDetailLasciaTitle => 'Leave group';
  @override String gruppoDetailLasciaMsg(String nome) => 'Are you sure you want to leave the group "$nome"?';
  @override String get gruppoDetailLasciaBtnConfirm => 'LEAVE';
  @override String get gruppoDetailLasciato => 'You left the group';
  @override String get gruppoDetailNoApiariCondivisi => 'No apiaries shared with this group';
  @override String get gruppoDetailNoInviti => 'No pending invitations';
  @override String get gruppoDetailBtnInvitaMembro => 'Invite member';
  @override String get gruppoDetailInvitoRuoloLbl => 'Role:';
  @override String get gruppoDetailInvitoScadeLbl => 'Expires:';
  @override String get gruppoDetailTooltipAnnullaInvito => 'Cancel invitation';
  @override String get gruppoDetailAnnullaInvitoTitle => 'Cancel invitation';
  @override String gruppoDetailAnnullaInvitoMsg(String email) => 'Cancel the invitation for $email?';
  @override String get gruppoDetailAnnullaBtnConfirm => 'CANCEL INVITATION';
  @override String get gruppoDetailInvitoAnnullato => 'Invitation cancelled';
  @override String get gruppoDetailApiarioProprietario => 'Owner:';
  @override String get gruppoDetailApiarioNoPos => 'Location not specified';
  @override String get gruppoDetailImpossibileTrovareProf => 'Could not find your profile in the group';
  @override String get gruppoDetailImmagineAggiornata => 'Group image updated';
  @override String get gruppoDetailDataLoadError => 'Error loading data';
  @override String get gruppoDetailPopupCambiaRuolo => 'Change role';
  @override String get gruppoDetailPopupRimuovi => 'Remove from group';
  @override String get gruppoDetailMembroNonValido => 'Invalid member';

  // ── Cantina screen ──
  @override String get cantinaTitle => 'Cellar 🍯';
  @override String get cantinaBtnNuovoMaturatore => 'New ripening tank';
  @override String get cantinaInMaturazione => 'Ripening';
  @override String get cantinaStoccati => 'Stored';
  @override String get cantinaVasetti => 'Jars';
  @override String get cantinaSectionMaturatori => '🥛 Ripening tanks';
  @override String cantinaAttiviLabel(int n) => '$n active';
  @override String get cantinaNoMaturatori => 'No active ripening tanks.\nAdd one after honey extraction.';
  @override String get cantinaSectionStoccaggio => '🪣 Storage';
  @override String cantinaContenitoriLabel(int n) => '$n containers';
  @override String get cantinaNoContenitori => 'No containers with honey.\nTransfer from a ripening tank.';
  @override String get cantinaSectionInvasettato => '🫙 Jarred';
  @override String cantinaVasettiLabel(int n) => '$n jars';
  @override String get cantinaNoVasetti => 'No jars recorded.\nJar honey from a container.';
  @override String cantinaDeleteMaturatoreMsg(String nome) => 'Delete ripening tank "$nome"?';
  @override String cantinaDeleteContenitoreMsg(String nome) => 'Delete container "$nome"?';
  @override String get cantinaVenditaErrVasetti => 'Sale saved but error updating jars';
  @override String get cantinaStoricoMaturatori => '📦 Ripening Tank History';
  @override String cantinaStoricoLabel(int n) => '$n emptied';
  @override String cantinaMaturatoreStoricoPeriodo(String da, String a) => '$da → $a';
  @override String cantinaMaturatoreStoricoKg(String kg, int giorni) => '$kg kg · $giorni days';

  // ── Aggiungi maturatore sheet ──
  @override String get aggiungiMaturatoreTitleNew => 'New Ripening Tank';
  @override String get aggiungiMaturatoreTitleEdit => 'Edit Ripening Tank';
  @override String get aggiungiMaturatoreHintNome => 'Name (e.g. 200L tank)';
  @override String get aggiungiMaturatoreLblTipoMiele => 'Honey type';
  @override String get aggiungiMaturatoreLblCapacita => 'Capacity (kg)';
  @override String get aggiungiMaturatoreLblKgAttuali => 'Current kg';
  @override String get aggiungiMaturatoreLblGiorniMaturazione => 'Ripening days';
  @override String get aggiungiMaturatoreHelperGiorni => 'Auto from honey type';
  @override String get aggiungiMaturatoreLblDataInizio => 'Start date';

  // ── Trasferisci sheet ──
  @override String trasferisciTitle(String nome) => 'Transfer from "$nome"';
  @override String trasferisciErrSupera(String tot, String disp) => 'Total (${tot}kg) exceeds available (${disp}kg)';
  @override String get trasferisciNoContenitori => 'No containers added';
  @override String get trasferisciBtnAggiungiContenitore => 'Add container';
  @override String get trasferisciBtnConferma => 'Confirm transfer';
  @override String get trasferisciLblTipo => 'Type';
  @override String get trasferisciLblKg => 'Kg';
  @override String trasferisciKgAssegnati(String tot, String disp) => '$tot / $disp kg assigned';
  @override String trasferisciKgDisponibili(String n) => '$n kg available';

  // ── Invasetta sheet ──
  @override String invasettaTitle(String nome) => 'Jar honey from "$nome"';
  @override String get invasettaLblFormato => 'Jar size';
  @override String get invasettaLblNumeroVasetti => 'Number of jars:';
  @override String get invasettaBtnMax => 'Max';
  @override String invasettaKgUsati(int n, int formato, String kg) => '$n × ${formato}g = $kg kg used';
  @override String invasettaRimangono(String kg) => 'Remaining: $kg kg';
  @override String get invasettaLblLotto => 'Batch (optional)';
  @override String invasettaBtnConferma(int n) => 'Jar $n jar${n == 1 ? "" : "s"}';

  // ── Maturatore card ──
  @override String get maturatoreCardBtnTrasferisci => 'Transfer to containers';
  @override String get maturatoreCardProntoOggi => 'Ready today';
  @override String maturatoreCardProntoTra(int n) => 'Ready in $n day${n == 1 ? "" : "s"}';
  @override String get maturatoreCardBtnTrasferisciOra => 'Transfer now';
  @override String get maturatoreCardStatoPronto => '✅ Ready';

  // ── Contenitore card ──
  @override String get contenitoreCardBtnInvasetta => '🫙 Jar';

  // ── Lotto vasetti section ──
  @override String lottoVasettiCount(int n) => '$n jar${n == 1 ? "" : "s"}';
  @override String lottoVasettiDisponibili(int n) => '$n avail.';
  @override String lottoVasettiiBtnVendi(int n) => 'Sell $n jar${n == 1 ? "" : "s"}';

  // ── Controllo form ──
  @override String get controlloFormTitleNew => 'New Inspection';
  @override String get controlloFormTitleEdit => 'Edit Inspection';
  @override String get controlloFormTitleLoading => 'Hive Inspection';
  @override String controlloFormArniaLabel(int numero) => 'Hive $numero';
  @override String controlloFormNucleoLabel(int numero) => 'Nuc $numero';
  @override String get controlloFormBtnSalva => 'SAVE';
  @override String get controlloFormBtnAggiorna => 'UPDATE';
  @override String get controlloFormSectionData => 'Inspection Date';
  @override String get controlloFormLblData => 'Date';
  @override String get controlloFormSectionTelaini => 'Frame Configuration';
  @override String get controlloFormTelainiCovata => 'Brood';
  @override String get controlloFormTelainiScorte => 'Honey';
  @override String get controlloFormTelainiFoglioCereo => 'Wax';
  @override String get controlloFormTelainiDiaframma => 'Divider';
  @override String get controlloFormTelainiNutritore => 'Feeder';
  @override String get controlloFormTelainiVuoto => 'Empty';
  @override String get controlloFormAutoOrdina => 'Auto-sort';
  @override String get controlloFormPreCaricato => 'Pre-loaded from last inspection';
  @override String get controlloFormToccaTelaino => 'Tap a frame to change its type';
  @override String get controlloFormSectionRegina => 'Queen';
  @override String get controlloFormLblStatoRegina => 'Queen status';
  @override String get controlloFormReginaAssente => 'Absent';
  @override String get controlloFormReginaPresente => 'Present';
  @override String get controlloFormReginaVista => 'Seen';
  @override String get controlloFormUovaFresche => 'Fresh eggs';
  @override String get controlloFormUovaFrescheDesc => 'Fresh eggs have been seen';
  @override String get controlloFormCelleReali => 'Queen cells';
  @override String get controlloFormCelleRealiDesc => 'Queen cells are present';
  @override String get controlloFormLblNumeroCelleReali => 'Number of queen cells';
  @override String get controlloFormReginaSostituita => 'Queen replaced';
  @override String get controlloFormReginaSostituitaDesc => 'The queen was replaced during this inspection';
  @override String get controlloFormReginaColorata => 'Queen marked';
  @override String get controlloFormReginaColorataDesc => 'The queen was marked/painted during this inspection';
  @override String get controlloFormColoreRegina => 'Marking colour';
  @override String get controlloFormSectionSciamatura => 'Swarming';
  @override String get controlloFormSciamatura => 'Swarm detected';
  @override String get controlloFormSciamaturaCodice => 'The colony has swarmed';
  @override String get controlloFormNoteSciamatura => 'Swarm notes';
  @override String get controlloFormSectionProblemi => 'Health Issues';
  @override String get controlloFormProblemi => 'Health issues detected';
  @override String get controlloFormProblemiDesc => 'Health issues have been detected';
  @override String get controlloFormDettagliProblemi => 'Health issue details';
  @override String get controlloFormValidateProblemi => 'Please describe the health issues';
  @override String get controlloFormSectionNote => 'General Notes';
  @override String get controlloFormLblNote => 'Notes';
  @override String get controlloFormHintNote => 'Enter any additional notes...';
  @override String get controlloFormOfflineMsg => 'You are offline. Changes will be saved locally and synced when you go back online.';
  @override String get controlloFormSavedOk => 'Inspection recorded successfully';
  @override String get controlloFormSavedOffline => 'Inspection saved locally. It will sync when you go back online';
  @override String get controlloFormUpdatedOk => 'Inspection updated successfully';
  @override String get controlloFormUpdatedOffline => 'Update saved locally. It will sync when you go back online';
  @override String get controlloFormErrGeneric => 'An error occurred. Please try again.';
  @override String get controlloFormErrCaricoArnia => 'Unable to load hive data. Check your connection.';
  @override String get controlloFormSyncOk => 'Data synced successfully';
  @override String get controlloFormReginaAutoCreata => 'Queen detected: basic record created automatically. Open it to complete the details.';
  @override String controlloFormLastControllo(String data) => 'Last inspection: $data';
  @override String controlloFormReginaLabel(String stato) => 'Queen: $stato';
  @override String controlloFormCovataCount(int n) => 'Brood $n';
  @override String controlloFormScorteCount(int n) => 'Honey $n';
  @override String controlloFormDiaframmaCount(int n) => 'Divider $n';
  @override String controlloFormFoglioCereoCount(int n) => 'Wax $n';

  // ── Pagamenti screen ──
  @override String get pagamentiTitle => 'Payment Management';
  @override String get pagamentiTabPagamenti => 'Payments';
  @override String get pagamentiTabBilancio => 'Balance';
  @override String get pagamentiTooltipSync => 'Sync data';
  @override String get pagamentiTooltipNuovoPagamento => 'New Payment';
  @override String pagamentiErrLoading(String e) => 'Error loading data: $e';
  @override String get pagamentiEmptyTitle => 'No payments recorded';
  @override String get pagamentiRegistraPagamento => 'Record Payment';
  @override String get pagamentiLinkRapidi => 'Quick Links';
  @override String get pagamentiLinkAttrezzature => 'Equipment Management';
  @override String get pagamentiAttrezzatureHint => 'Equipment expenses are automatically recorded in payments';
  @override String get pagamentiTooltipSaldo => 'Balance payment';
  @override String get pagamentiTooltipAttrezzatura => 'Equipment expense';
  @override String get pagamentiBilancioEmptyTitle => 'No balance available';
  @override String get pagamentiBilancioEmptyHint => 'To calculate the balance, group members need assigned shares and recorded payments.';
  @override String pagamentiBilancioTotale(String amount) => 'Group total expenses: $amount';
  @override String get pagamentiTooltipGestisci => 'Manage shares';
  @override String get pagamentiQuoteLabel => 'Shares';
  @override String get pagamentiTrasferimentiNecessari => 'Required transfers';
  @override String get pagamentiQuoteGruppo => 'Group shares';
  @override String get pagamentiGestisci => 'Manage';
  @override String get pagamentoPagato => 'Paid';
  @override String get pagamentoDovuto => 'Owed';
  @override String get pagamentoSaldo => 'Balance';
  @override String get pagamentiTooltipRegistraSaldo => 'Record balance payment';
  @override String pagamentiSaldoDesc(String da, String a) => 'Balance payment: $da → $a';
  @override String pagamentiBilancioWarnSommaQuote(String sum) => 'Group shares add up to $sum%, not 100%. The balance may not be accurate.';
  @override String get pagamentiBilancioWarnMembriSenzaQuota => 'Some members have made payments without an assigned share. Add a share from the "Manage" panel.';

  // ── Pagamento detail screen ──
  @override String get pagamentoDetailTitle => 'Payment Detail';
  @override String get pagamentoDetailNotFound => 'Payment not found';
  @override String pagamentoDetailErrLoading(String e) => 'Error loading payment: $e';
  @override String get pagamentoDetailDeleteMsg => 'Are you sure you want to delete this payment?';
  @override String get pagamentoDetailDeletedOk => 'Payment deleted successfully';
  @override String get pagamentoDetailErrDelete => 'Error deleting payment';
  @override String get pagamentoDetailLabelDescrizione => 'Description';
  @override String get pagamentoDetailLabelUtente => 'User';
  @override String get pagamentoDetailLabelGruppo => 'Group';

  // ── Pagamento form screen ──
  @override String get pagamentoFormTitleNew => 'New Payment';
  @override String get pagamentoFormTitleEdit => 'Edit Payment';
  @override String get pagamentoFormUpdatedOk => 'Payment updated successfully';
  @override String get pagamentoFormCreatedOk => 'Payment created successfully';
  @override String pagamentoFormErrSave(String e) => 'Error saving payment: $e';
  @override String get pagamentoFormLabelImporto => 'Amount (€)';
  @override String get pagamentoFormValidImportoRequired => 'Enter the amount';
  @override String get pagamentoFormValidImportoInvalid => 'Enter a valid amount';
  @override String get pagamentoFormValidImportoPositivo => 'Amount must be greater than zero';
  @override String get pagamentoFormValidDescRequired => 'Enter a description';
  @override String get pagamentoFormValidDestinatarioDiverso => 'Recipient must be different from the payer';
  @override String get pagamentoFormErrAuth => 'Session expired. Please sign in again.';
  @override String get pagamentoFormLabelGruppo => 'Group (optional)';
  @override String get pagamentoFormNoGruppo => 'No group';
  @override String get pagamentoFormLabelChiPaga => 'Who paid?';
  @override String get pagamentoFormIoStesso => '- myself -';
  @override String get pagamentoFormHelperChiPaga => 'Indicate the member who actually covered the expense';
  @override String get pagamentoFormSaldoTitle => 'Balance payment';
  @override String get pagamentoFormSaldoSubtitle => 'Money transferred directly between two members to settle the balance';
  @override String get pagamentoFormLabelDestinatario => 'To whom? (recipient)';
  @override String get pagamentoFormHelperDestinatario => 'Member receiving the money';
  @override String get pagamentoFormValidDestinatarioRequired => 'Select the recipient';

  // ── Quote screen ──
  @override String get quoteTitle => 'Share Management';
  @override String quoteErrLoading(String e) => 'Error loading shares: $e';
  @override String get quoteUpdatedOk => 'Share updated successfully';
  @override String quoteErrUpdate(String e) => 'Error updating share: $e';
  @override String get quoteEditTitle => 'Edit share';
  @override String quoteEditMsg(String username) => 'Edit the percentage for $username';
  @override String get quoteLabelPercentuale => 'Percentage';
  @override String get quoteValidPercRequired => 'Enter a percentage';
  @override String get quoteValidPercInvalid => 'Enter a valid percentage';
  @override String get quoteDeleteMsg => 'Are you sure you want to delete this share?';
  @override String get quoteDeletedOk => 'Share deleted successfully';
  @override String get quoteErrDelete => 'Error deleting share';
  @override String quoteErrDeleteE(String e) => 'Error deleting share: $e';
  @override String get quoteAddNoGruppo => 'Select a group before adding a share';
  @override String get quoteAddedOk => 'Share added successfully';
  @override String quoteErrAdd(String e) => 'Error adding share: $e';
  @override String get quoteAddTitle => 'Add share';
  @override String get quoteLabelIdUtente => 'User ID';
  @override String get quoteValidIdRequired => 'Enter the user ID';
  @override String get quoteValidIdInvalid => 'Invalid user ID';
  @override String get quoteValidPercRange => 'Percentage must be between 0 and 100';
  @override String get quoteAddLabelUtente => 'Group member';
  @override String get quoteValidUtenteRequired => 'Select a member';
  @override String get quoteAddNoMembriDisponibili => 'All group members already have a share. Edit an existing share to redistribute.';
  @override String quoteAddErrCaricamentoMembri(String e) => 'Error loading group members: $e';
  @override String quoteValidSommaSupera100(String sum) => 'Group shares would exceed 100% ($sum%). Reduce an existing share before adding a new one.';
  @override String quoteConfirmSommaNon100Title(String sum) => 'Shares total: $sum%';
  @override String get quoteConfirmSommaNon100Msg => 'Group shares do not add up to 100%. Balance calculation may not distribute expenses correctly. Save anyway?';
  @override String get quoteConfirmSommaNon100Continue => 'Save anyway';
  @override String get quoteLabelFiltroGruppo => 'Filter by group';
  @override String get quoteTuttiGruppi => 'All groups';
  @override String get quoteTooltipAdd => 'Add Share';
  @override String get quoteEmptyTitle => 'No shares found';

  // ── Statistiche screen ──
  @override String get statisticheTitle => 'Statistics';
  @override String get statisticheTabDashboard => 'Dashboard';
  @override String get statisticheTabAnalisi => 'Analysis';
  @override String get statisticheTabChiediAI => 'Ask AI';

  // ── Dashboard card base ──
  @override String get dashboardErrCaricamento => 'Error loading data';

  // ── Dashboard widget titles ──
  @override String get dashboardTitleProduzione => 'Honey Production per Year';
  @override String get dashboardTitleSaluteArnie => 'Hive Health';
  @override String get dashboardTitleRegineStats => 'Queens - Statistics';
  @override String get dashboardTitleFrequenzaControlli => 'Inspection Frequency';
  @override String get dashboardTitleFioritureVicine => 'Nearby Blooms';
  @override String get dashboardTitleAttrezzature => 'Equipment Summary';
  @override String get dashboardTitleProduzionePerTipo => 'Production by Honey Type';
  @override String get dashboardTitleTrattamenti => 'Treatments Over Time';
  @override String get dashboardTitleAndamentoScorte => 'Store Trends';
  @override String get dashboardTitleAndamentoCovata => 'Brood Trends';
  @override String get dashboardTitlePerformanceRegine => 'Queen Performance';
  @override String get dashboardTitleQuoteGruppo => 'Group Shares';
  @override String dashboardTitleBilancio(int anno) => 'Balance $anno';

  // ── Salute arnie widget ──
  @override String get dashboardSaluteNoArnie => 'No hives found';
  @override String get dashboardSaluteOttima => 'Excellent';
  @override String get dashboardSaluteAttenzione => 'Attention';
  @override String get dashboardSaluteCritica => 'Critical';
  @override String dashboardSaluteTotale(int n) => 'Total: $n hives';
  @override String dashboardSaluteCritiche(String list) => 'Critical: $list';
  @override String get dashboardSaluteInfoTitle => 'Hive health';
  @override String get dashboardSaluteInfoIntro => 'Status based on the latest inspection recorded in the past 90 days.';
  @override String get dashboardSaluteInfoOttima => 'Recent inspection, queen present, no health issues.';
  @override String get dashboardSaluteInfoAttenzione => 'Recent inspection, but the queen is missing or health issues were reported.';
  @override String get dashboardSaluteInfoCritica => 'No inspection recorded in the past 90 days: this hive needs a check.';
  @override String get dashboardSaluteInfoSuggerimento => 'Tap a chart slice or a legend entry to see which hives fall in each category.';
  @override String get dashboardSaluteListaVuota => 'No hives in this category.';
  @override String dashboardSaluteListaTitolo(String stato) => 'Hives - $stato';
  @override String get dashboardSaluteApiarioPrefisso => 'Apiary:';

  // ── Regine statistiche widget ──
  @override String get dashboardRegineAttive => 'Active queens';
  @override String get dashboardRegineSostituzioni => 'Replacements';
  @override String get dashboardRegineVitaMedia => 'Avg lifespan';
  @override String dashboardRegineVitaMesiStr(String durata) => '$durata months';
  @override String get dashboardRegineMotiviSostituzione => 'Replacement reasons:';

  // ── Performance regine widget ──
  @override String get dashboardPerformanceNoRegine => 'No queens with ratings';
  @override String get dashboardPerformanceHdrRegina => 'Queen';
  @override String get dashboardPerformanceHdrProd => 'Prod.';
  @override String get dashboardPerformanceHdrDoc => 'Doc.';
  @override String get dashboardPerformanceHdrResist => 'Resist.';
  @override String get dashboardPerformanceHdrSc => 'Sw.';

  // ── Bilancio widget ──
  @override String get dashboardBilancioSaldoAnnuale => 'Annual balance: ';
  @override String get dashboardBilancioEntrate => 'Income';
  @override String get dashboardBilancioUscite => 'Expenses';

  // ── Frequenza controlli widget ──
  @override String get dashboardFrequenzaMedia => 'Avg days between inspections';
  @override String dashboardFrequenzaGiorni(int n) => '$n days';
  @override String get dashboardFrequenzaDettaglio => 'Detail by hive:';

  // ── Fioriture vicine widget ──
  @override String get dashboardFioritureNessuna => 'No blooms within 5 km radius';
  @override String get dashboardFioritureFiltroTutti => 'All apiaries';

  // ── Attrezzature widget ──
  @override String get dashboardAttrezzatureNessuna => 'No equipment recorded';
  @override String get dashboardAttrezzatureCategoria => 'Category';
  @override String get dashboardAttrezzatureNumero => 'No.';
  @override String get dashboardAttrezzatureValore => 'Value';
  @override String get dashboardAttrezzatureInventario => 'Total inventory';

  // ── Varroa trend widget ──
  @override String get dashboardVarroaNessuno => 'No treatments in the period';

  // ── Andamento scorte widget ──
  @override String get dashboardScorteNessuno => 'No store data available';

  // ── Andamento covata widget ──
  @override String get dashboardCovataNessuno => 'No brood data available';

  // ── Produzione tipo widget ──
  @override String get dashboardProdTipoNessuno => 'No extractions recorded';
  @override String dashboardProdTipoTotale(String kg) => 'Total: $kg kg';

  // ── Quote gruppo widget ──
  @override String get dashboardQuoteGruppoSoloCoord => 'Visible to group coordinators only';
  @override String get dashboardQuoteGruppoNessunaSpesa => 'No expenses recorded for the selected period';
  @override String get dashboardQuoteGruppoQuoteIncomplete => 'Share percentages do not add up to 100%';
  @override String get dashboardQuoteGruppoLabelDovuto => 'Owed';
  @override String get dashboardQuoteGruppoLabelPagato => 'Paid';
  @override String get dashboardQuoteGruppoLabelSpeso => 'Spent';
  @override String get dashboardQuoteGruppoLabelCopertura => 'Coverage';
  @override String get dashboardQuoteGruppoSelezionaGruppo => 'Select group';

  // ── NL Query tab ──
  @override String get nlQuerySuggerite => 'Suggested questions:';
  @override String get nlQuerySuggerimento1 => 'Which hives haven\'t been inspected in 30 days?';
  @override String get nlQuerySuggerimento2 => 'When did I produce the most honey?';
  @override String get nlQuerySuggerimento3 => 'Which queens have the highest rating?';
  @override String get nlQuerySuggerimento4 => 'How many inspections have I done this year?';
  @override String get nlQuerySuggerimento5 => 'What is my balance this year?';
  @override String get nlQuerySuggerimento6 => 'Which treatments have I done?';
  @override String get nlQueryPensando => 'AI is thinking…';
  @override String get nlQueryRispostaAI => 'AI Response';
  @override String nlQueryRisultati(int n) => '$n results';
  @override String get nlQueryErrLento => 'The AI server is slow, try again in a moment';
  @override String get nlQueryErrRifiuto => 'I cannot answer this question';
  @override String get nlQueryErrGenerico => 'Error: please try again';
  @override String get nlQueryErrSessione => 'Session expired. Please sign in again.';
  @override String get nlQueryErrServizio => 'AI service is temporarily unavailable.';
  @override String get nlQueryInputHint => 'Ask a question about your data…';

  // ── Risultato query widget ──
  @override String nlQueryRighe(int n) => '$n rows';
  @override String get risultatoNessunDato => 'No data available';
  @override String get risultatoNessunRisultato => 'No results';

  // ── Export bottom sheet ──
  @override String get exportTitle => 'Export data';
  @override String get exportExcel => 'Excel';
  @override String get exportPdf => 'PDF';
  @override String get exportExcelSalvato => 'Excel file saved';
  @override String exportErrExcel(String e) => 'Excel export error: $e';
  @override String get exportPdfSalvato => 'PDF file saved';
  @override String exportErrPdf(String e) => 'PDF export error: $e';

  // ── Query builder tab ──
  @override String get queryBuilderEseguiAnalisi => 'Run analysis';
  @override String get queryBuilderAvanti => 'Next';
  @override String get queryBuilderIndietro => 'Back';
  @override String get queryBuilderStepAnalizzare => 'What to analyse?';
  @override String get queryBuilderStepFiltri => 'Filters and aggregation';
  @override String get queryBuilderStepRisultati => 'Results';
  @override String get queryBuilderEntitaControlli => 'Hive inspections';
  @override String get queryBuilderEntitaSmielature => 'Extractions';
  @override String get queryBuilderEntitaRegine => 'Queens';
  @override String get queryBuilderEntitaVendite => 'Sales';
  @override String get queryBuilderEntitaSpese => 'Expenses';
  @override String get queryBuilderEntitaFioriture => 'Blooms';
  @override String get queryBuilderEntitaArnie => 'Hives';
  @override String get queryBuilderDataDa => 'Date from';
  @override String get queryBuilderDataA => 'Date to';
  @override String get queryBuilderAggregazione => 'Aggregation';
  @override String get queryBuilderAggCount => 'Count';
  @override String get queryBuilderAggSum => 'Sum';
  @override String get queryBuilderAggAvg => 'Average';
  @override String get queryBuilderAggNone => 'None (table)';
  @override String get queryBuilderRaggruppaPer => 'Group by';
  @override String get queryBuilderRaggruppaMese => 'Month';
  @override String get queryBuilderRagruppaAnno => 'Year';
  @override String queryBuilderErrore(String e) => 'Error: $e';
  @override String get queryBuilderRunFirst => 'Run the analysis to see results';
  @override String get queryBuilderVizBarre => 'Bars';
  @override String get queryBuilderVizLinea => 'Line';
  @override String get queryBuilderVizTabella => 'Table';

  // ── Voice transcript review screen ──
  @override String voiceReviewTitleCount(int n) => 'Review ($n)';
  @override String get voiceReviewBtnDeleteAll => 'Delete all';
  @override String get voiceReviewDeleteAllTitle => 'Delete all?';
  @override String get voiceReviewDeleteAllMsg => 'All transcriptions will be removed from the list.';
  @override String get voiceReviewDeleteItemTitle => 'Delete transcription?';
  @override String get voiceReviewInfoBanner => 'Drag ≡ to reorder, then merge adjacent entries.';
  @override String get voiceReviewEmpty => 'No transcriptions remaining.';
  @override String get voiceReviewEmptyHint => 'Press "Keep in queue" to exit or go back.';
  @override String get voiceReviewBtnKeepQueue => 'Keep in queue';
  @override String get voiceReviewBtnSendAI => 'Send for processing';
  @override String get voiceReviewProcessing => 'Processing…';
  @override String get voiceReviewMerging => 'Merging…';
  @override String get voiceReviewMergeWith => 'Merge with next ↓';
  @override String get voiceReviewTooltipEdit => 'Edit';
  @override String get voiceReviewTooltipSave => 'Save';
  @override String get voiceReviewTooltipDelete => 'Delete';

  // ── Voice entry verification screen ──
  @override String get voiceVerifTitle => 'Verify voice data';
  @override String get voiceVerifTooltipRemove => 'Remove recording';
  @override String get voiceVerifSaving => 'Saving...';
  @override String get voiceVerifDeleteTitle => 'Delete record';
  @override String voiceVerifDeleteMsg(String label) => 'Do you want to delete the $label record?\n\nThis cannot be undone.';
  @override String get voiceVerifScheda => 'this record';
  @override String get voiceVerifNewArnieTitolo => 'New hives detected';
  @override String voiceVerifNewArnieMsg(String list) => 'The following hives are not in the database:\n\n$list\n\nDo you want to create them in the selected apiary and save the inspections?';
  @override String get voiceVerifCreateSave => 'CREATE AND SAVE';
  @override String get voiceVerifErrCreazArnieTitolo => 'Hive creation error';
  @override String voiceVerifSavedOk(int n) => 'Data saved successfully ($n records)';
  @override String voiceVerifPartialSaved(int saved, int remaining) => 'Saved $saved records. $remaining not saved:\n';
  @override String get voiceVerifNoSaved => 'No records saved:\n';
  @override String voiceVerifInvalidSkipped(String arnia) => 'Hive $arnia: invalid data, skipped.';
  @override String voiceVerifNotFoundCache(String arnia) => 'Hive $arnia: not found in cache. Refresh the hive list and try again.';
  @override String get voiceVerifEmptyTitle => 'No data to verify';
  @override String get voiceVerifEmptySubtitle => 'Go back and record new inspections';
  @override String get voiceVerifBtnGoBack => 'Go back';
  @override String voiceVerifRecordOf(int current, int total) => 'Record $current of $total';
  @override String get voiceVerifSectionPosizione => 'Location';
  @override String get voiceVerifSectionRegistrazione => 'Original recording';
  @override String get voiceVerifAudioLabel => 'Original audio - tap to listen';
  @override String get voiceVerifSectionGenerali => 'General information';
  @override String get voiceVerifLblTipo => 'Type';
  @override String get voiceVerifSectionRegina => 'Queen';
  @override String get voiceVerifSectionTelaini => 'Frames';
  @override String get voiceVerifLblTotale => 'Total';
  @override String get voiceVerifLblForzaFamiglia => 'Colony strength';
  @override String get voiceVerifSectionProblemi => 'Problems';
  @override String get voiceVerifLblProblemiSanitari => 'Health issues';
  @override String get voiceVerifLblTipoProblema => 'Problem type';
  @override String get voiceVerifSectionColorazione => 'Queen marking';
  @override String get voiceVerifLblReginaColorata => 'Marked/colored queen';
  @override String get voiceVerifLblColoreRegina => 'Marking color';
  @override String get voiceVerifSectionNote => 'Notes';
  @override String get voiceVerifLblNoteAggiuntive => 'Additional notes';
  @override String get voiceVerifTooltipPrecedente => 'Previous';
  @override String get voiceVerifTooltipSuccessivo => 'Next';
  @override String get voiceVerifBtnSaveAll => 'SAVE ALL';
  @override String get voiceVerifTooltipPausa => 'Pause';
  @override String get voiceVerifTooltipRiproduci => 'Play';
  @override String get voiceVerifTooltipStop => 'Stop';
  @override String get trattamentoTitle => 'Treatment';
  @override String get trattamentoFormNomeProdotto => 'Product Name';
  @override String get voiceVerifInfoCreazioneArnia => 'A new empty hive will be created in this apiary. You can add a colony to it later.';

  // ── Voice command screen ──
  @override String get voiceCommandTitle => 'Voice entry';
  @override String get voiceCommandTooltipMenu => 'Menu';
  @override String get voiceCommandTooltipQueue => 'Process offline queue';
  @override String get voiceCommandTooltipHideGuide => 'Hide guide';
  @override String get voiceCommandTooltipShowTutorial => 'Review tutorial';
  @override String voiceCommandDraftRestored(int n) => '$n transcriptions recovered from the previous session. Press the queue to process them.';
  @override String get voiceCommandUnsavedTitle => 'Unsaved data found';
  @override String voiceCommandUnsavedMsg(int n) => 'There are $n inspection records processed by Gemini that were not saved. Do you want to resume them?';
  @override String get voiceCommandBtnScarta => 'DISCARD';
  @override String get voiceCommandBtnRiprendi => 'RESUME';
  @override String voiceCommandRecoveredSaved(int n) => 'Data recovered and saved ($n records)';
  @override String get voiceCommandNoTranscription => 'No transcription to save';
  @override String voiceCommandSavedToQueue(int n) => 'Transcription saved to queue ($n pending)';
  @override String get voiceCommandNoValidEntry => 'No valid entries extracted from the queue';
  @override String get voiceCommandNoValidData => 'No valid data extracted. Check the transcriptions and try again.';
  @override String voiceCommandQueueSaved(int n) => 'Data from queue saved ($n records)';
  @override String voiceCommandSavedWithRemaining(int saved, int remaining) => 'Data saved ($saved records). $remaining transcriptions in queue.';
  @override String voiceCommandSavedOk(int n) => 'Data saved successfully ($n records)';
  @override String get voiceCommandBtnSaveLater => 'Save for later';
  @override String get voiceCommandGuideTitle => 'How voice entry works';
  @override String get voiceCommandGuideStep1Title => 'Select apiary';
  @override String get voiceCommandGuideStep1Desc => 'Tap the banner at the top to select the apiary. Then just say the hive number.';
  @override String get voiceCommandGuideStep2Title => 'Start speaking';
  @override String get voiceCommandGuideStep2Desc => 'Press the microphone button and speak clearly';
  @override String get voiceCommandGuideStep3Title => 'Verify and save';
  @override String get voiceCommandGuideStep3Desc => 'Check the data recognized by Gemini before saving';
  @override String get voiceCommandGuideOffline => 'Without connection: use "Save for later" and resume when online.';
  @override String get voiceCommandGuideExamplesTitle => 'Examples:';
  @override String get voiceCommandGuideKeywordsTitle => 'Multiple mode keywords:';
  @override String get voiceCommandGuideKeyNextCmd => '"next" / "ok" / "go" / "continue" → records next hive';
  @override String get voiceCommandGuideKeyStopCmd => '"stop" / "done" / "enough" / "finished" → ends batch and goes to review';

  // ── Voice tutorial sheet ──
  @override String get voiceTutorialTitle => 'Voice entry';
  @override String get voiceTutorialSubtitle => 'How to record an inspection hands-free';
  @override String get voiceTutorialStep1Title => 'Select the apiary';
  @override String get voiceTutorialStep1Body => 'Tap the orange banner at the top and choose the apiary you are working on. From then on, just say the hive number - no need to repeat it every time.';
  @override String get voiceTutorialStep2Title => 'Speak clearly';
  @override String get voiceTutorialStep2Body => 'Press the microphone button and describe the inspection as you would to a colleague. No precise syntax needed: the AI understands natural language.';
  @override String get voiceTutorialStep2BodyStt => 'Press the microphone and describe the inspection. In this mode, use clear keywords like "hive", "queen", "brood" to help the system recognize data correctly.';
  @override String get voiceTutorialStep2BodyAudio => 'Press the microphone and speak naturally as if to a colleague. Gemini AI can understand complex speech and free-form terminology without needing fixed keywords.';
  @override String get voiceTutorialStep3Title => 'Gemini interprets the text';
  @override String get voiceTutorialStep3TitleStt => 'Local extraction';
  @override String get voiceTutorialStep3TitleAudio => 'Gemini analyzes audio';
  @override String get voiceTutorialStep3Body => 'The recognized text is sent to Gemini AI, which automatically extracts: hive number, frames, queen status, health issues and more.';
  @override String get voiceTutorialStep3BodyStt => 'The transcription made with phone integrated speech to text is analyzed via predefined rules (regex). It\'s faster and cheaper, but may not recognize non-standard expressions.';
  @override String get voiceTutorialStep3BodyAudio => 'The entire audio recording is analyzed by an advanced AI model (Gemini Pro) which transcribes and extracts the data. It offers maximum flexibility in understanding natural language.';
  @override String get voiceTutorialStep4Title => 'Verify and save';
  @override String get voiceTutorialStep4Body => 'Check the interpreted data on the verification screen, correct any errors and press Save.';
  @override String get voiceTutorialExamplesTitle => 'Example phrases';
  @override String get voiceTutorialMultiTitle => 'Multiple mode (several hives in sequence)';
  @override String get voiceTutorialMultiNextKeyword => '"next" / "ok" / "go" / "continue"';
  @override String get voiceTutorialMultiNextDesc => 'records the next hive';
  @override String get voiceTutorialMultiStopKeyword => '"stop" / "done" / "enough" / "finished"';
  @override String get voiceTutorialMultiStopDesc => 'ends the batch and goes to review';
  @override String get voiceTutorialOfflineMsg => 'Without connection use "Save for later": transcriptions are queued and you can process them as soon as you are back online.';
  @override String get voiceTutorialOfflineMsgStt => 'This mode works completely OFFLINE. You can record and save inspections even without signal.';
  @override String get voiceTutorialOfflineMsgAudio => 'This mode requires CONNECTION. If you are offline you can still record: transcriptions will be queued and processed by Gemini as soon as you are back online.';
  @override String get voiceTutorialBtnStart => 'Start recording';

  // ── Common shared ──
  @override String get btnClose => 'Close';

  // ── Settings screen (remaining) ──
  @override String get settingsPhotoUpdated => 'Profile photo updated';
  @override String get settingsPhotoError => 'Error uploading photo';

  // ── Chat screen ──
  @override String get chatTooltipClear => 'Clear conversation';
  @override String get chatClearTitle => 'Clear conversation?';
  @override String get chatClearMsg => 'This action will delete all messages and cannot be undone.';
  @override String get chatClearBtn => 'CLEAR';
  @override String get chatInfoBanner => 'ApiarioAI has access to your apiary data and can generate charts for your analyses.';
  @override String get chatEmpty => 'No messages. Start a conversation!\nTry asking "Show me a chart of hive 3 population"';
  @override String get chatLoading => 'ApiarioAI is processing...';
  @override String chatErrMsg(String e) => 'Error: $e';
  @override String get chatRetrySnackbar => 'Retrying to send the message...';
  @override String get chatHint => 'Write a message...';
  @override String get chatGeneratingChart => 'Generating chart...';
  @override String get chatQuotaUpgradeHint =>
      'You can add a personal Gemini key in settings or upgrade your plan.';
  @override String get chatQuotaInputDisabled => 'Quota exceeded - try again after reset';

  // ── AI quota gating (shared) ──
  @override String get quotaVoiceExhaustedTitle => 'AI voice quota exceeded';
  @override String quotaRetryInWithUpgrade(String duration) =>
      'Try again in $duration or upgrade your plan.';
  @override String get quotaRetryAfterReset =>
      'Try again after the daily reset or upgrade.';
  @override String get quotaStatsExhausted =>
      'Stats AI quota exceeded. Try again after reset or set a personal Groq key in settings.';
  @override String get nlQueryInputHintExhausted => 'Quota exceeded - try again after reset';
  @override String get voiceQueuePreflightTitle => 'Quota running out';
  @override String voiceQueuePreflightMessage(int available, int total) =>
      'You have $available voice AI calls available but there are $total recordings in queue. '
      'Only the first $available will be sent; the rest will stay in queue for the next reset.';
  @override String get voiceQueuePreflightProceed => 'Proceed';
  @override String get voiceQueuePreflightCancel => 'Cancel';
  @override String get voiceQueuePreflightExhausted =>
      'Voice AI quota already exhausted. Try again after the daily reset.';

  // ── AI Tier ──
  @override String get aiTierLabel => 'AI Plan';
  @override String get aiTierUpgrade => 'Upgrade';
  @override String get aiTierUpgradeComingSoon => 'Plan upgrades will be available soon!';
  @override String get aiTierTotal => 'Total';
  @override String get aiTierFreeDesc => 'Chat: 10/day, Voice: 5/day';
  @override String get aiTierApicoltoreDesc => 'Chat: 30/day, Voice: 30/day';
  @override String get aiTierProfessionaleDesc => 'Chat: 200/day, Voice: 100/day';

  // ── AI Tier upgrade screen ──
  @override String get aiUpgradeTitle => 'AI Plans';
  @override String get aiUpgradeSubtitle => 'Choose the plan that best fits your beekeeping needs';
  @override String get aiUpgradeCurrentPlan => 'Current plan';
  @override String get aiUpgradeChatPerDay => 'chat/day';
  @override String get aiUpgradeVoicePerDay => 'voice/day';
  @override String get aiUpgradeTotalPerDay => 'total/day';
  @override String get aiUpgradeFeatureAdvanced => 'Advanced AI analysis';
  @override String get aiUpgradeContactUs => 'Request upgrade';
  @override String get aiUpgradeContactEmail => 'Email sent for upgrade request!';
  @override String get aiUpgradeContactSent => 'We will contact you shortly to activate the plan.';
  @override String get aiUpgradeFreeNote => 'Perfect to get started and try the AI assistant';
  @override String get aiUpgradeApicoltoreNote => 'For beekeepers managing multiple hives';
  @override String get aiUpgradeProfessionaleNote => 'For beekeeping businesses and professionals';
  @override String get aiUpgradeMostPopular => 'Most popular';
  @override String get aiUpgradeDowngradeNote => 'To change or downgrade your plan, contact us.';
  @override String get chatQuotaPreCheckError => 'You have reached the daily message limit. Upgrade your plan or try again tomorrow.';
  @override String get chatQuotaResetNotice => 'Your quota has been reset. You can send new messages.';

  // ── Subscription / Paywall ──
  @override String get subPaywallTitle => 'Testing Phase & Open Source';
  @override String get subPaywallSubtitle => 'Contribute to the project development';
  @override String get subMonthly => 'Monthly';
  @override String get subYearly => 'Yearly';
  @override String get subYearlySave => 'Save';
  @override String get subRestore => 'Restore';
  @override String get subRestoreSuccess => 'Access restored!';
  @override String get subRestoreNone => 'No code found.';
  @override String get subRestoreError => 'Error during restoration.';
  @override String get subPurchaseSuccess => 'Thank you for your contribution!';
  @override String get subPurchaseError => 'Error. Please try again.';
  @override String get subManage => 'Manage Access';
  @override String get subCurrentPlan => 'Current Plan';
  @override String get subFreeDesc => 'Free basic features for everyone';
  @override String get subProMonthlyDesc => 'Full access via contribution';
  @override String get subProYearlyDesc => 'Full access via contribution';
  @override String get subFeatureUnlimitedChat => 'Intensive ApiaryAI Testing';
  @override String get subFeatureVoice => 'Voice Entry Experimentation';
  @override String get subFeatureAdvancedAI => 'Open Source Code & Feedback';
  @override String get subCostExplanation => 'Apiary is an Open Source project born out of passion. Since using AI involves costs for external APIs (Google Gemini, Groq), access tiers allow us to keep the server running and continue development without ads.';
  @override String get subLoading => 'Loading...';
  @override String get subNoProducts => 'No plans available at this time.';
  @override String subPricePerMonth(String price) => '$price/month';
  @override String subPricePerYear(String price) => '$price/year';
  @override String subSavePercent(int percent) => 'Save $percent%';
  @override String get subFreeTrial => 'Free trial';
  @override String subFreeTrialDays(int days) => '$days days free';
  @override String get subThenPrice => 'then';
  @override String get subBestValue => 'Best value';
  @override String get subMostPopular => 'Recommended';
  @override String get subSubscribe => 'Subscribe';
  @override String get subPerMonth => '/month';
  @override String get subPerYear => '/year';
  @override String get subChoosePlan => 'Choose your plan';
  @override String get subTermsNotice => 'Subscription auto-renews. You can cancel anytime from Play Store settings.';
  @override String subPackageDuration(String type) {
    switch (type) {
      case 'MONTHLY': return 'Monthly';
      case 'ANNUAL': return 'Yearly';
      case 'SIX_MONTH': return '6 Months';
      case 'THREE_MONTH': return '3 Months';
      case 'TWO_MONTH': return '2 Months';
      case 'WEEKLY': return 'Weekly';
      case 'LIFETIME': return 'Lifetime';
      default: return type;
    }
  }
  @override String get subComingSoon => 'Extended access';
  @override String get subComingSoonDesc => 'The app is in testing phase. Higher tiers are currently available via access code, reserved for testers helping us improve the app. If you have one, you can enter it below.';
  @override String get subActivateCode => 'Have an access code?';
  @override String get subActivateCodeHint => 'Enter access code';
  @override String get subActivateBtn => 'Activate';
  @override String get subActivateSuccess => 'Code activated! Your tier has been updated.';
  @override String get subActivateError => 'Activation error. Please try again.';
  @override String get subActivateInvalid => 'Invalid or expired code.';
  @override String get subActivating => 'Activating...';

  // ── Analisi telaino list screen ──
  @override String get analisiListTitle => 'Frame Analyses';
  @override String get analisiListTooltipNew => 'New analysis';
  @override String get analisiListEmpty => 'No analyses recorded';
  @override String get analisiListBtnStart => 'Start Analysis';
  @override String analisiListCardTitle(int n, String side) => 'Frame $n - Side $side';
  @override String analisiListTagApi(int n) => 'Bees: $n';
  @override String analisiListTagRegine(int n) => 'Queens: $n';
  @override String analisiListTagFuchi(int n) => 'Drones: $n';
  @override String analisiListTagCelleR(int n) => 'Q. Cells: $n';

  // ── Analisi telaino screen ──
  @override String get analisiTitle => 'Frame Analysis';
  @override String analisiErrAnalysis(String e) => 'Analysis error: $e';
  @override String get analisiSnackSaved => 'Analysis saved successfully';
  @override String analisiErrSave(String e) => 'Save error: $e';
  @override String get analisiConfigTitle => 'Configuration';
  @override String get analisiLoadingControllo => 'Loading hive status...';
  @override String analisiSlotSource(String date, int count) => 'Data from inspection on $date ($count frames present)';
  @override String get analisiNoSlot => 'No recent inspection found – manual selection.';
  @override String get analisiFacciata => 'Side';
  @override String analisiTelainoN(int n) => 'Frame $n';
  @override String get analisiSelectTelaino => 'Select frame';
  @override String get analisiTelainoLabel => 'Frame n.';
  @override String get analisiAnalyzing => 'Analyzing...';
  @override String analisiProgressLabel(int n, String label) => 'Frame $n – $label';
  @override String analisiSummaryTitle(int n, String side) => 'Frame $n – Side $side';
  @override String get analisiCountApi => 'Bees';
  @override String get analisiCountRegine => 'Queens';
  @override String get analisiCountFuchi => 'Drones';
  @override String get analisiCountCelleReali => 'Queen Cells';
  @override String get analisiConfidenzaMedia => 'Average confidence: ';
  @override String get analisiNoteLbl => 'Notes (optional)';
  @override String get analisiNoteHint => 'Add observations...';
  @override String get analisiBtnRipeti => 'Retry';
  @override String get analisiBtnSalva => 'Save';
  @override String get analisiBtnScattaFoto => 'Take Photo';
  @override String get analisiBtnGalleria => 'Choose from Gallery';
  @override String get analisiDiagnostica => 'Diagnostic analysis';
  @override String analisiIdentityBadge(int n, String label) => 'Frame $n – $label';
  @override String analisiIdentityDate(String date) => 'Type from last inspection ($date)';
  @override String analisiWarnDiafammaApi(int n) => 'Bees detected on divider board ($n): the board should not be colonized.';
  @override String get analisiWarnDiafammaRegina => 'Queen detected on divider board: abnormal situation, check immediately.';
  @override String analisiWarnDiafammaCelle(int n) => 'Queen cells on divider board ($n): serious anomaly, intervention needed.';
  @override String analisiWarnDiafammaFuchi(int n) => 'Many drones on divider board ($n): the separation may not be working.';
  @override String get analisiWarnNutritoreRegina => 'Queen on feeder: has moved outside the brood area.';
  @override String analisiWarnNutritoreCelle(int n) => 'Queen cells on feeder ($n): colony may be preparing to swarm.';
  @override String analisiWarnNutritoreApi(int n) => 'Many bees on feeder ($n): check that the feeder does not obstruct movement.';
  @override String analisiWarnCovataSciamaturaAlta(int n) => 'High queen cells ($n): likely swarm preparation. Act soon.';
  @override String analisiWarnCovataSciamaturaMedia(int n) => 'Queen cells present ($n): monitor colony in the coming weeks.';
  @override String analisiWarnCovataRegine(int n) => 'Multiple queens detected ($n): anomaly – check for queen cells.';
  @override String get analisiWarnCovataVuota => 'No bees on brood frame: weakened colony, swarmed or empty frame.';
  @override String analisiWarnCovataFuchi(int n) => 'High drones on brood frame ($n): possible drone brood, orphaned colony?';
  @override String analisiWarnScorteRegina(int n) => 'Queen on stores frame ($n): unusual position, check brood space.';
  @override String analisiWarnScorteCelle(int n) => 'Queen cells on stores frame ($n): swarm or queen replacement signal.';
  @override String analisiWarnScorteApi(int n) => 'High bee density on stores ($n): possible pre-swarm accumulation.';
  @override String analisiWarnDensitaAltissima(int n) => 'Very high density ($n insects): this frame is very crowded.';

  // ── Mappa screen ──
  @override String get mappaTitle => 'Apiary Map';
  @override String get mappaOfflineTooltip => 'Offline mode - Data loaded from cache';
  @override String get mappaTooltipOsmHide => 'Hide OSM vegetation';
  @override String get mappaTooltipOsmShow => 'Show OSM vegetation';
  @override String get mappaTooltipRaggioHide => 'Hide flight range';
  @override String get mappaTooltipRaggioShow => 'Show flight range (3 km)';
  @override String get mappaTooltipNomadismo => 'Nomadic Beekeeping & Flora';
  @override String get mappaTooltipSync => 'Sync data';
  @override String get mappaErrPermission => 'Location permission denied';
  @override String get mappaErrPermissionPermanent => 'Location permissions are permanently denied. Enable them from settings.';
  @override String get mappaSnackSettings => 'Settings';
  @override String get mappaErrServiceDisabled => 'Location service disabled. Enable it to use this feature.';
  @override String get mappaSnackActivate => 'Enable';
  @override String get mappaErrPosition => 'Error retrieving position';
  @override String get mappaSnackNord => 'Map oriented to North';
  @override String mappaErrData(String e) => 'Error loading data: $e';
  @override String get mappaSnackZoom => 'Zoom in to see OSM vegetation (zoom ≥ 10)';
  @override String get mappaErrOsm => 'Error loading OSM vegetation';
  @override String get mappaStatArnie => 'Hives';
  @override String get mappaStatApicoltore => 'Beekeeper';
  @override String get mappaStatTipo => 'Type';
  @override String get mappaStatCommunity => 'Community';
  @override String get mappaStatTuoGruppo => 'Mine/Group';
  @override String get mappaApprox => 'Approximate position';
  @override String get mappaBtnVisualizza => 'View';
  @override String get mappaBtnApriApiario => 'Open Apiary';
  @override String get mappaLegenda => 'Legend';
  @override String get mappaLegendaMioApiario => 'My apiary';
  @override String get mappaLegendaCommunity => 'Community apiary';
  @override String get mappaLegendaGruppo => 'Group apiary';
  @override String get mappaLegendaRaggio => 'Flight range (3 km)';
  @override String get mappaLegendaFiorituraAttiva => 'Active bloom';
  @override String get mappaLegendaFiorituraInattiva => 'Inactive bloom';
  @override String get mappaLegendaBosco => 'Wood / Forest';
  @override String get mappaLegendaMacchia => 'Scrubland';
  @override String get mappaLegendaPrato => 'Meadow / Pasture';
  @override String get mappaLegendaFrutteto => 'Orchard';
  @override String get mappaLegendaColtura => 'Crop';
  @override String get mappaLegendaPosizione => 'Current position';
  @override String get mappaTooltipNord => 'Orient to North';
  @override String get mappaTooltipFioritura => 'Add bloom';
  @override String get mappaTooltipPosizione => 'Center on current position';
  @override String get mappaFiorApiario => 'Apiary';
  @override String get mappaFiorPeriodo => 'Period';
  @override String get mappaFiorRaggio => 'Radius';
  @override String get mappaFiorNote => 'Notes';
  @override String get mappaFiorConferme => 'Community confirmations';
  @override String mappaFiorMetri(int n) => '$n metres';
  @override String mappaFiorConferN(int n) => '$n beekeepers';
  @override String mappaFiorConferNI(int n, String avg) => '$n beekeepers · avg intensity $avg/5';
  @override String mappaFiorDalAl(String start, String end) => 'From $start to $end';
  @override String mappaFiorDal(String start) => 'From $start';
  @override String get mappaFiorDettaglio => 'Details';
  @override String get mappaApiario => 'Apiary';

  // ── Nomadismo screen ──
  @override String get nomadismoTitle => 'Nomadic Beekeeping';
  @override String get nomadismoLegendaDensita => 'GBIF density (millions of observations)';
  @override String get nomadismoLegendaApiario => 'Your apiary';
  @override String get nomadismoLegendaAreaAnalisi => 'Analysis area (5 km)';
  @override String get nomadismoLegendaDati => 'GBIF data 2010–2025';
  @override String get nomadismoSoloApiari => '🗺️ Apiary only';
  @override String get nomadismoBtnTocca => 'Tap the map…';
  @override String get nomadismoBtnAnalizza => 'Analyze point (5 km)';
  @override String get nomadismoFloraTitle => 'Honey flora - 5 km radius';
  @override String get nomadismoNessunaSpecie => 'No species found.';
  @override String get nomadismoAltrePiante => 'Other plants';
  @override String get nomadismoGbifFooter => 'GBIF data · observations 2010–2025 · 5 km radius';
  @override String nomadismoErrGbif(String e) => 'GBIF error: $e';

  // ── Splash screen ──
  @override String get splashSubtitle => 'Manage your apiaries anywhere';

  // ── Disclaimer screen ──
  @override String get disclaimerTitle => 'Security Notice';
  @override String get disclaimerBody =>
    'WARNING: Although we do our best to protect your data using HTTPS protocols, the app does not guarantee complete information security.\n\n'
    'By using this application, you accept the potential risks of:\n'
    '• Data loss in the event of a database breach\n'
    '• Unauthorised access to apiary information\n'
    '• Possible service interruptions\n\n'
    'We recommend not storing sensitive information or critical personal data within the application.\n\n'
    'If you reject these terms, the app will close. By accepting, you confirm that you understand and accept the risks listed above.';
  @override String get disclaimerDontShow => 'Do not show this message again';
  @override String get disclaimerBtnReject => 'REJECT';
  @override String get disclaimerBtnAccept => 'ACCEPT';

  // ── What's New screen ──
  @override String get whatsNewBadge => 'Update';
  @override String get whatsNewTitle => "What's new 🐝";
  @override String get whatsNewSubtitle => 'Apiary has been updated. Here are the new features.';
  @override String get whatsNewEmpty => 'Nothing new to show.';
  @override String get whatsNewBtnExplore => 'Start exploring';
  @override String whatsNewCatLabel(String cat) {
    switch (cat) {
      case 'Nuovo': return 'New';
      case 'Miglioramento': return 'Improvement';
      case 'Fix': return 'Fix';
      default: return cat;
    }
  }

  // ── Onboarding screen ──
  @override String get onboardingSkip => 'Skip';
  @override String get onboardingBack => 'Back';
  @override String get onboardingNext => 'Next';
  @override String get onboardingBtnCreate => 'Create my first apiary';
  @override String get onboardingBtnExplore => 'Explore first';
  @override String get onboardingStep1Title => 'Welcome to Apiary';
  @override String get onboardingStep1Desc => 'Your digital beekeeping diary. Record, monitor and manage everything about your bees - from inspections to sales, from queen genealogy to AI frame analysis.';
  @override String get onboardingStep2Title => 'Your Apiaries';
  @override String get onboardingStep2Desc => 'An apiary is your physical location - a field, a forest, a plot of land. Inside each apiary you find your hives. You can have multiple apiaries in different places and manage them all from here.';
  @override String get onboardingStep3Title => 'Hives & Inspections';
  @override String get onboardingStep3Desc => 'Every hive has its own story: queen, treatments, supers, harvests. Record periodic inspections to track colony strength, queen presence and health status.';
  @override String get onboardingStep4Title => 'Advanced Features';
  @override String get onboardingStep4F1Title => 'Voice Control';
  @override String get onboardingStep4F1Desc => 'Record a complete inspection simply by speaking';
  @override String get onboardingStep4F2Title => 'AI Analysis';
  @override String get onboardingStep4F2Desc => 'Photograph a frame and instantly detect bees, brood and queen cells';
  @override String get onboardingStep4F3Title => 'Statistics';
  @override String get onboardingStep4F3Desc => 'Production, health and trend charts over time';
  @override String get onboardingStep4F4Title => 'Collaboration';
  @override String get onboardingStep4F4Desc => 'Share apiaries with partners or collaborators';
  @override String get onboardingStep5Title => 'You\'re ready!';
  @override String get onboardingStep5Desc => 'Start by creating your first apiary. It will take less than a minute. You can always review this guide from the settings page.';

  // ── Donazione screen ──
  @override String get donazioneTitle => 'Buy us a coffee';
  @override String get donazioneErrLink => 'Unable to open the link.';
  @override String get donazioneTxOk => 'Thank you! Your message has been prepared.';
  @override String donazioneErrEmail(String email) => 'No email app found. Write to us at $email';
  @override String get donazioneHeroSubtitle => 'An open project, made by beekeepers for beekeepers.\nIf it helps you, buy us a coffee!';
  @override String get donazioneBtnCoffee => 'Buy us a coffee';
  @override String get donazioneCard1Desc => 'The code is public and accessible to everyone. No hidden features.';
  @override String get donazioneCard2Title => 'Made by beekeepers';
  @override String get donazioneCard2Desc => 'Every feature comes from direct field experience, for those who truly keep bees.';
  @override String get donazioneCard3Title => 'Infrastructure costs';
  @override String get donazioneCard3Desc => 'Server, domain and cloud storage have a real cost. Your help covers them.';
  @override String get donazioneCard4Title => 'Continuous growth';
  @override String get donazioneCard4Desc => 'Django · Flutter · AI/YOLO · Gemini. We invest in technology for you.';
  @override String get donazioneFeedbackTitle => 'Send us a message';
  @override String get donazioneFeedbackSubtitle => 'Report a bug, suggest a feature or leave us your feedback.';
  @override String get donazioneLblNome => 'Name *';
  @override String get donazioneErrNome => 'Name is required';
  @override String get donazioneLblEmail => 'Email (optional, so we can reply)';
  @override String get donazioneErrEmailInvalid => 'Invalid email';
  @override String get donazioneLblMsg => 'Message *';
  @override String get donazioneErrMsg => 'Message is required';
  @override String get donazioneBtnInvio => 'Sending...';
  @override String get donazioneBtnInvia => 'Send feedback';

  // ── Guida screen ──
  @override String get guidaTitle => 'Complete Guide';
  @override String get guidaSubtitle => 'Everything you need to know to get the most out of Apiary';
  @override String get guidaBtnReview => 'Review the tutorial';

  // ── Privacy Policy screen ──
  @override String get privacyTitle => 'Privacy Policy';
  @override String get privacyHeader => 'Privacy Policy';
  @override String get privacyLastUpdated => 'Last updated: 12 March 2026';
  @override String get privacyIntro =>
      'This Privacy Policy describes how Apiary collects, uses and protects '
      'user data. Please read it carefully before using the application.';
  @override String get privacyS1Title => '1. Data controller';
  @override String get privacyS1Body =>
      'The data controller is the developer of the Apiary application.\n'
      'For any privacy-related requests, you can contact us at:';
  @override String get privacyS2Title => '2. Data collected';
  @override String get privacyS2Body => 'The application may collect the following categories of data, depending on the features used:';
  @override String get privacyS2_1Title => '2.1 Data entered voluntarily by the user';
  @override List<String> get privacyS2_1Bullets => [
    'Beekeeping data: information about apiaries, hives, queens, supers, swarms, blooms, periodic inspections and frame analyses (brood, stores, dividers, feeders).',
    'Account data: username and password for backend service authentication.',
    'Email address (upcoming feature): may be required for registration, password recovery or sending application-related notifications.',
  ];
  @override String get privacyS2_2Title => '2.2 Data collected automatically';
  @override List<String> get privacyS2_2Bullets => [
    'Usage data: technical information about app usage (e.g. version, OS, device language) for diagnostic and improvement purposes. This data does not personally identify the user.',
    'Device identifiers: may be collected anonymously or pseudonymously to ensure proper app operation.',
  ];
  @override String get privacyS2_3Title => '2.3 Data collected via camera';
  @override String get privacyS2_3Body =>
      'The application requires camera access for the AI-powered frame analysis feature '
      '(detection of bees, drones, queen cells and brood). Captured images are processed '
      'locally on the device and/or sent to the backend server for analysis. '
      'Images are not shared with third parties nor used for purposes other than beekeeping analysis.';
  @override String get privacyS3Title => '3. Purpose of processing';
  @override List<String> get privacyS3Bullets => [
    'Service delivery: managing apiary data, syncing across devices via the remote backend, AI frame analysis.',
    'App improvement: aggregate and anonymous analyses to identify malfunctions and optimize features.',
    'Service communications: notifications related to your account or app operation.',
    'Marketing and newsletters (planned): with explicit consent, your email address may be used to send updates or offers related to the application.',
    'Advertising (planned): in the future, third-party advertising services (e.g. Google AdMob) may be integrated. Users will be informed and, where required by law, their consent will be requested.',
  ];
  @override String get privacyS4Title => '4. Legal basis for processing';
  @override List<String> get privacyS4Bullets => [
    'Performance of a contract (Art. 6(1)(b) GDPR): for data necessary for app operation and account management.',
    'Consent (Art. 6(1)(a) GDPR): for camera access, marketing communications and personalized advertising. Consent may be withdrawn at any time.',
    'Legitimate interest (Art. 6(1)(f) GDPR): for diagnostic and service security purposes.',
  ];
  @override String get privacyS5Title => '5. Data retention';
  @override List<String> get privacyS5Bullets => [
    'Apiary data is stored on the backend server (cible99.pythonanywhere.com) for the duration of the active account, plus an additional 30 days after deletion, unless required by law.',
    'Data stored locally on the device (SQLite and SharedPreferences) remains on the device until app uninstallation or manual deletion by the user.',
    'Email data collected for marketing purposes will be retained until consent is withdrawn.',
  ];
  @override String get privacyS6Title => '6. Sharing with third parties';
  @override String get privacyS6Body => 'Personal data is not sold or transferred to third parties. It may only be shared with:';
  @override List<String> get privacyS6Bullets => [
    'Hosting provider: PythonAnywhere (backend server), which processes data as a data processor in compliance with GDPR.',
    'Analytics and advertising services (future): e.g. Google AdMob / Google Analytics, which have their own privacy policies.',
    'Competent authorities: where required by law or to protect legitimate rights.',
  ];
  @override String get privacyS7Title => '7. User rights (GDPR)';
  @override String get privacyS7Body => 'As a data subject, you have the right to:';
  @override List<String> get privacyS7Bullets => [
    'Access – obtain confirmation of processing and a copy of your data.',
    'Rectification – correct inaccurate or incomplete data.',
    'Erasure ("right to be forgotten") – request deletion of your data, subject to legal retention obligations.',
    'Restriction of processing – request suspension of processing in certain cases.',
    'Data portability – receive your data in a structured, machine-readable format.',
    'Objection – object to processing based on legitimate interest or for direct marketing purposes.',
    'Withdrawal of consent – withdraw previously given consent at any time.',
  ];
  @override String get privacyS7Contact => 'To exercise these rights, contact:';
  @override String get privacyS7Garante => 'You also have the right to lodge a complaint with the Data Protection Authority:';
  @override String get privacyS8Title => '8. Security';
  @override String get privacyS8Body =>
      'We adopt adequate technical and organizational measures to protect data from '
      'unauthorized access, loss or destruction, including the use of HTTPS connections '
      'for data transmission between app and server.';
  @override String get privacyS9Title => '9. Minors';
  @override String get privacyS9Body =>
      'The application is not intended for children under 16 years of age. We do not knowingly '
      'collect data from minors. Should we become aware of accidental collection of such data, '
      'we will proceed with its immediate deletion.';
  @override String get privacyS10Title => '10. Changes to this policy';
  @override String get privacyS10Body =>
      'We reserve the right to update this policy. In case of significant changes, '
      'the user will be notified via in-app notification or email. '
      'Continued use of the app following publication of changes '
      'constitutes acceptance thereof.';
  @override String get privacyS11Title => '11. Contact';
  @override String get privacyS11Body => 'For any privacy-related questions:';
  @override String get privacyCopyright => '© 2026 Apiary – All rights reserved.';

  // ── Weather widget ──
  @override String get weatherErrorNoData => 'Unable to load weather data. Check your connection.';
  @override String weatherUpdatedAt(String time) => 'Updated: $time';
  @override String weatherFeelsLike(String temp) => 'Feels like $temp°C';
  @override String get weatherHumidity => 'Humidity';
  @override String get weatherWind => 'Wind';
  @override String get weatherRain => 'Rain';
  @override String get weatherPressure => 'Pressure';
  @override String get weatherForecast7Days => '7-day forecast';
  @override String get weatherToday => 'Today';
  @override List<String> get weatherDayNamesShort => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ── QR code ──
  @override String get qrUnsupportedEntity => 'Entity type not supported for QR generation';
  @override String get qrLabelApiario => 'Apiary';
  @override String get qrLabelUnknown => 'Unknown';
  @override String qrLabelPosition(String position) => 'Location: $position';
  @override String get qrLabelNotSpecified => 'Not specified';
  @override String get qrBtnCopy => 'Copy';
  @override String get qrCopiedToClipboard => 'QR code copied to clipboard';
  @override String get qrBtnShare => 'Share';
  @override String qrShareText(String title) => '$title - Scan me to view details';
  @override String qrShareError(String error) => 'Error while sharing: $error';
  @override String get qrNavUnsupportedTitle => 'Unsupported QR type';
  @override String get qrNavUnsupportedMsg => 'The scanned QR code format is not recognized.';
  @override String get qrNavErrorTitle => 'Error';
  @override String qrNavErrorMsg(String error) => 'An error occurred: $error';
  @override String get qrNavArniaNonTrovatoTitle => 'Hive not found';
  @override String get qrNavArniaNonTrovatoMsg => 'The scanned hive was not found in the system. Make sure you have the necessary permissions.';
  @override String get qrNavArniaOfflineTitle => 'Hive not available offline';
  @override String get qrNavArniaOfflineMsg => 'The scanned hive is not available in offline mode. Connect to the internet to download the data.';
  @override String get qrNavApiarioNonTrovatoTitle => 'Apiary not found';
  @override String get qrNavApiarioNonTrovatoMsg => 'The scanned apiary was not found in the system. Make sure you have the necessary permissions.';
  @override String get qrNavApiarioOfflineTitle => 'Apiary not available offline';
  @override String get qrNavApiarioOfflineMsg => 'The scanned apiary is not available in offline mode. Connect to the internet to download the data.';

  // ── Minimap / edit mode ──
  @override String mapAddTitle(String label) => 'Add $label';
  @override String mapAddNumberLabel(String label) => '$label number';
  @override String get mapLabelColor => 'Color';
  @override String get mapBtnAdd => 'Add';
  @override String mapNucleoTitle(String num) => 'Nuc $num';
  @override String get mapNucleoLegacyHint => 'Legacy element - remove it from the map if no longer in use.';
  @override String get mapRemoveFromMap => 'Remove from map';
  @override String get mapNumberConflictTitle => 'Number already exists';
  @override String mapNumberConflictMsg(String current) => 'Hive number $current already exists.\nChoose a number for the new hive:';
  @override String get mapArniaNumberLabel => 'Hive number';
  @override String get mapSaved => 'Map saved';
  @override String get mapRemoveElementTitle => 'Remove element';
  @override String get mapNoArnie => 'No hives in this apiary';
  @override String get mapNoArnieCta => 'Press + to add one';
  @override String get mapEditModeHint => 'Drag · Tap path to extend it';
  @override String get mapSelectionHint => 'Tap to select';
  @override String mapSelectedCount(int count) => '$count selected';
  @override String get mapLongPressToDelete => 'Long press to delete';
  @override String get mapLabelArnia => 'Hive';
  @override String get mapLabelApidea => 'Apidea';
  @override String get mapLabelMiniPlus => 'Mini-Plus';
  @override String get mapLabelPortasciami => 'Nuc box';
  @override String get mapLabelAlbero => 'Tree';
  @override String get mapLabelVialetto => 'Path';
  @override String get mapTooltipCenter => 'Center';
  @override String get mapSnapOn => 'Snap ON';
  @override String get mapSnapOff => 'Snap OFF';
  @override String get mapBtnSave => 'Save*';
  @override String get mapBtnDone => 'Done';
  @override String get mapLabelInactive => 'inactive';
  @override String get mapLabelInactiveFem => 'inactive';

  // ── Colony data in arnia detail ──
  @override String get arniaColoniaVuota => 'Empty hive - no active colony';
  @override String get arniaInsediaColonia => 'Settle colony';
  @override String arniaColoniaHeader(int id, String date) => 'Colony #$id - since $date';
  @override String arniaColoniaRegina(String razza, String origine) => 'Queen: $razza · $origine';
  @override String get arniaMenuStoriaColonie => 'Colony history';
  @override String get arniaMenuInsediaNuovaColonia => 'Settle new colony';

  // ── Equipment model display ──
  @override String get attrezzaturaStatoNonSpecificato => 'Not specified';
  @override String get attrezzaturaCondizioneNonSpecificato => 'Not specified';

  // ── Sales banner ──
  @override List<String> get monthNames => [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  @override String venditeBannerSummary(int count, String total) => '$count sales  •  $total €';
  @override String get venditeCanaleMercatino => 'Market';
  @override String get venditeCanaleNegozio => 'Shop';
  @override String get venditeCanaleOnline => 'Online';
  @override String get venditeCanalePravato => 'Private';
  @override String get venditeCanaleAltro => 'Other';

  // ── Voice command examples ──
  @override String get voiceCommandExample1 => '"Hive 3, queen present, spotted, 4 brood frames, 3 stores"';
  @override String get voiceCommandExample2 => '"Hive 7, strong colony, health issues, varroa"';
  @override String get voiceCommandExample3 => '"Hive 2, 7 total frames, 2 queen cells, swarming risk"';
  @override String voiceCommandGeminiError(String detail) => 'Gemini: $detail';

  // ── Guide sections ──
  @override String get guidaSection1Title => 'Getting Started - Create your first apiary';
  @override String get guidaSection2Title => 'Hives & Inspections - Record an inspection';
  @override String get guidaSection3Title => 'Queens - Manage and track queens';
  @override String get guidaSection4Title => 'Supers & Harvests - From super to cellar';
  @override String get guidaSection5Title => 'AI Features - Chat, voice, frame analysis';
  @override String get guidaSection6Title => 'Collaboration - Share with other beekeepers';
  @override String get guidaSection7Title => 'Exports - PDF and CSV';
  @override List<String> get guidaSection1Items => [
    'Tap the menu and go to Apiaries → New Apiary',
    'Enter name, map location and apiary type',
    'Save - your apiary is ready',
    'From inside the apiary, tap + to add hives',
    '💡 Give descriptive names to hives (e.g. "Hive 1 - Ligustica") to find them easily.',
  ];
  @override List<String> get guidaSection2Items => [
    'Enter the hive you want to inspect',
    'Tap New Inspection',
    'Fill in: date, colony strength (1–10), queen presence, health status',
    'Add free-text notes for specific observations',
    '💡 Colony strength: 1 = very weak, 5 = average, 10 = very strong occupying all frames.',
  ];
  @override List<String> get guidaSection3Items => [
    'Each hive can have an associated queen - add her from the hive detail',
    'Record: birth date, breed, marking color, origin',
    'View the genealogical tree to track lineages',
    'Use Compare Queens to evaluate performance',
    '💡 International colors: White (1/6), Yellow (2/7), Red (3/8), Green (4/9), Blue (5/0).',
  ];
  @override List<String> get guidaSection4Items => [
    'Add a super to the hive when it\'s harvest time',
    'When ready, record the extraction: date, gross weight, quality',
    'Extracted honey goes to Cellar: maturators and storage containers',
    'From the jarring section, track jars produced and final weight',
  ];
  @override List<String> get guidaSection5Items => [
    '🗨️ AI Chat - Tap the chat widget to ask questions to the Gemini assistant',
    '🎤 Voice Input - Speak and the app automatically transcribes the inspection',
    '📷 Frame Analysis - Upload a frame photo to detect bees, brood and queen cells',
    '💡 For frame analysis use diffused natural light and hold the frame parallel to the camera.',
  ];
  @override List<String> get guidaSection6Items => [
    'Go to Groups from the main menu',
    'Create a group and invite other beekeepers via email or link',
    'Assign roles: Owner, Collaborator, Viewer',
    'Share one or more apiaries with the group from inside the apiary',
  ];
  @override List<String> get guidaSection7Items => [
    'Inspection PDF: from inside an apiary → Export PDF',
    'Treatments CSV: from Management → Treatments → Export CSV',
    'Sales CSV: from Management → Sales → Export CSV',
    '💡 CSVs are compatible with Excel and Google Sheets for traceability and accounting.',
  ];

  // ── AI Chat ──
  @override String get chatWelcomeMessage => 'Hello! I\'m ApiarioAI, your beekeeping assistant. How can I help you today?';
  @override String get chatTitle => 'ApiarioAI Assistant';
  @override String get chatChartDefaultTitle => 'Chart';

  // ── Hive frame visualizer ──
  @override String get frameLabelCovata => 'Brood';
  @override String get frameLabelScorte => 'Stores';
  @override String get frameLabelFoglioCereo => 'Wax foundation';
  @override String get frameLabelDiaframma => 'Dummy board';
  @override String get frameLabelNutritore => 'Feeder';
  @override String get frameLabelVuoto => 'Empty';
  @override String get frameNoControllo => 'No inspection recorded';
  @override String get frameReginaPresente => 'Queen present';
  @override String get frameReginaAssente => 'Queen absent';
  @override String frameCelleRealiTooltip(int numero, int days) =>
      'Queen cells${numero > 0 ? ": $numero" : ""} - detected $days days ago';

  // ── Hive type names ──
  @override String arniaTypeName(String key) {
    switch (key) {
      case 'dadant':             return 'Dadant-Blatt';
      case 'langstroth':         return 'Langstroth';
      case 'top_bar':            return 'Top Bar';
      case 'warre':              return 'Warré';
      case 'osservazione':       return 'Observation hive';
      case 'pappa_reale':        return 'Royal jelly hive';
      case 'nucleo_legno':       return 'Wooden nucleus';
      case 'nucleo_polistirolo': return 'Polystyrene nucleus';
      case 'portasciami':        return 'Swarm trap';
      case 'apidea':             return 'Apidea / Kieler';
      case 'mini_plus':          return 'Mini-Plus';
      default:                   return key;
    }
  }

  // ── Audio input widget ──
  @override String get audioInputStatusRecording => 'Recording…';
  @override String audioInputStatusExtending(String dur) => 'Extending audio… (+$dur)';
  @override String get audioInputStatusProcessing => 'Sending to Gemini…';
  @override String audioInputStatusProcessingQueue(int cur, int total) =>
      'Processing queue: $cur/$total…';
  @override String get audioInputStatusError => 'Processing error';
  @override String get audioInputStatusSaving => 'Saving to session…';
  @override String get audioInputStatusIdlePrompt => 'Press to start recording';
  @override String get audioInputStatusIdleNext => 'Record the next hive';
  @override String get audioInputStatusIdleSend => 'Record the next hives or send everything to Gemini';
  @override String get audioInputGeminiProcessing => 'Gemini is processing…';
  @override String audioInputQueueProgress(int cur, int total) => 'Queue: $cur/$total…';
  @override String get audioInputListening => 'Listening…';
  @override String get audioInputListenBeforeSend => 'Listen before sending';
  @override String get audioInputErrStartMic =>
      'Unable to start recording. Check microphone permission.';
  @override String get audioInputErrRecInvalid => 'Invalid recording. Try again.';
  @override String get audioInputErrExtInvalid => 'Invalid extension. Try again.';
  @override String get audioInputErrNoArniaDetected =>
      'Hive number not detected in the audio. Select the hive from the menu or add audio with the number.';
  @override String get audioInputErrNoArniaQueue =>
      'Hive number not detected in a recording. Select the hive from the menu or add audio with the number.';
  @override String get audioInputErrExtract =>
      'Unable to extract data from the audio. Try again.';
  @override String get audioInputErrUnknown => 'unknown error';
  @override String audioInputRecFailed(int idx, int total, String err) =>
      'Recording $idx/$total not processed: $err';
  @override String get audioInputSelectArnia => 'Select hive:';
  @override String get audioInputChooseArnia => 'Choose hive…';
  @override String audioInputArniaItem(int n) => 'Hive $n';
  @override String audioInputBatchHeader(int n) => 'Batch: $n ${n == 1 ? 'hive' : 'hives'}';
  @override String audioInputSessionHeader(int n) => 'Session: $n recording(s) to send';
  @override String audioInputRecordingItem(int n) => 'Recording $n';
  @override String get audioInputAbandonTitle => 'Cancel session?';
  @override String get audioInputAbandonMsgSingle => 'The current recording will be deleted.';
  @override String audioInputAbandonMsgMulti(int n) =>
      'All $n recording(s) of the session will be deleted.';
  @override String get audioInputBtnBack => 'BACK';
  @override String get audioInputBtnDeleteAll => 'DELETE ALL';
  @override String get audioInputBtnAddAudioWithNum => 'Add audio with hive number';
  @override String get audioInputBtnDiscard => 'Discard';
  @override String get audioInputBtnRetry => 'Retry';
  @override String get audioInputBtnSaveQueue => 'Save to queue';
  @override String audioInputBtnSendAll(int n) => 'Send all to Gemini ($n)';
  @override String audioInputBtnStopReview(int n) => 'STOP – Review ($n)';
  @override String get audioInputBtnAbandon => 'Cancel session';
  @override String get audioInputHintPressMicToStart => 'Press the microphone to start';
  @override String get audioInputHintRecordNext => 'Record the next hive';

  // ── Voice context banner ──
  @override String get voiceContextSelect => 'Select apiary…';
  @override String voiceContextSelected(String name) => 'Apiary: $name';
  @override String get voiceContextNoApiari => 'No apiary available';
  @override String get voiceContextSheetTitle => 'Select apiary';
  @override String get voiceContextSheetHint =>
      'Tap the pin to set a default apiary.';
  @override String get voiceContextSetDefault => 'Set as default';
  @override String get voiceContextRemoveDefault => 'Remove default';
  @override String get voiceContextOffline => 'OFFLINE';

  // ── Controllo form contextual hint ──
  @override String get controlloFormIntroHint =>
      '📋 Record the hive state: brood frames (red), stores (yellow) and queen presence. The more details you enter, the better you can monitor the colony\'s health.';

  // ── Nomadismo presets ──
  @override String nomadismoPresetNome(String key) {
    switch (key) {
      case 'acacia':     return 'Acacia';
      case 'castagno':   return 'Chestnut';
      case 'tiglio':     return 'Linden';
      case 'lavanda':    return 'Lavender';
      case 'sulla':      return 'Sulla';
      case 'corbezzolo': return 'Strawberry tree';
      case 'eucalipto':  return 'Eucalyptus';
      case 'girasole':   return 'Sunflower';
      case 'trifoglio':  return 'Clover';
      case 'agrumi':     return 'Citrus';
      default:           return key;
    }
  }
  @override String nomadismoPresetPeriodo(String key) {
    switch (key) {
      case 'acacia':     return 'Apr–May';
      case 'castagno':   return 'Jun–Jul';
      case 'tiglio':     return 'Jun';
      case 'lavanda':    return 'Jul–Aug';
      case 'sulla':      return 'Apr–May';
      case 'corbezzolo': return 'Oct–Nov';
      case 'eucalipto':  return 'Jan–Mar';
      case 'girasole':   return 'Jul–Aug';
      case 'trifoglio':  return 'May–Sep';
      case 'agrumi':     return 'Mar–Apr';
      default:           return '';
    }
  }
  @override String nomadismoPresetRegioni(String key) {
    switch (key) {
      case 'acacia':     return 'Tuscany, Umbria, Lazio';
      case 'castagno':   return 'Apennines, Prealps';
      case 'tiglio':     return 'Alpine valleys, Po';
      case 'lavanda':    return 'Provence, Alta Valle Pesio';
      case 'sulla':      return 'Sicily, Calabria, Sard.';
      case 'corbezzolo': return 'Sardinia, Maremma';
      case 'eucalipto':  return 'Sardinia, Sicily';
      case 'girasole':   return 'Po Valley, Apulia';
      case 'trifoglio':  return 'Meadows, all Italy';
      case 'agrumi':     return 'Sicily, Calabria, Camp.';
      default:           return '';
    }
  }
  @override String nomadismoPresetDesc(String key) {
    switch (key) {
      case 'acacia':     return 'Light and delicate honey';
      case 'castagno':   return 'Dark and tannic honey';
      case 'tiglio':     return 'Fragrant, minty honey';
      case 'lavanda':    return 'Aromatic and floral honey';
      case 'sulla':      return 'Light honey, typical of the South';
      case 'corbezzolo': return 'Bitter and unique honey';
      case 'eucalipto':  return 'Balsamic and dark honey';
      case 'girasole':   return 'Light honey, crystallizes quickly';
      case 'trifoglio':  return 'Delicate wildflower honey';
      case 'agrumi':     return 'Fragrant orange blossom honey';
      default:           return '';
    }
  }
}
