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
  @override String get voiceModeSttTitle => 'Speech-to-text (free)';
  @override String get voiceModeSttSubtitle =>
      'Your device microphone transcribes speech; '
      'data is extracted locally with no connection or API needed. '
      'Recommended for everyday use.';
  @override String get voiceModeAudioTitle => 'Record audio — Gemini AI (premium)';
  @override String get voiceModeAudioSubtitle =>
      'Audio is analysed by Gemini in one step: '
      'more accurate in noisy environments and with free-form speech. '
      'Requires an internet connection.';
  @override String get voiceAudioPremiumSheetTitle => 'Premium feature';
  @override String get voiceAudioPremiumSheetBody =>
      'Gemini Audio mode sends your recording to Google Gemini AI '
      'for intelligent transcription and structured data extraction.\n\n'
      '🎉 During beta it is included for free for all users.\n\n'
      'In the future it may become part of a paid plan.';
  @override String get voiceAudioPremiumSheetActivate => 'Activate';

  // AI Quota section
  @override String get sectionQuota => 'AI Quota — Daily usage';
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
  @override String get msgOfflineMode => 'Offline mode — data updated at last access';
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
      'The colony stays the same — only the box model changes.';
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
      'Offline mode — data updated at last access';
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
  @override String get melariConfirmBtn => 'Confirm';
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
  // Smielatura form extra
  @override String get smielaturaFormLblMelariDisp => 'Available supers';
  @override String get smielaturaFormValidateNumero => 'Enter a valid number';
  @override String get smielaturaFormBtnCreate => 'REGISTER';
  @override String get smielaturaFormBtnUpdate => 'UPDATE';
  @override String get smielaturaFormCreatedOk => 'Extraction registered';
  @override String get smielaturaFormUpdatedOk => 'Extraction updated';
  // Smielatura detail
  @override String get smielaturaDetailTitle => 'Extraction Detail';
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
      'Offline mode — data updated at last access';
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

  // ── Controllo form ────────────────────────────────────────────────────────
  @override String get controlloFormDialogTitle => 'Hive Inspection';
  @override String get controlloFormTitleNew => 'New Inspection';
  @override String get controlloFormTitleEdit => 'Edit Inspection';
  @override String get controlloFormLblData => 'Date';
  @override String get controlloFormBtnAutoOrdina => 'Auto-arrange';
  @override String get controlloFormLblNumCelleReali => 'Number of queen cells';
  @override String get controlloFormLblNoteSciamatura => 'Swarm notes';
  @override String get controlloFormLblDettagliProblemi => 'Health issue details';
  @override String get controlloFormLblNote => 'Notes';
  @override String get controlloFormHintNote => 'Enter any additional notes...';
  @override String get controlloFormSyncOk => 'Data synchronised successfully';
  @override String get controlloFormLblStatoRegina => 'Queen status';
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
      '👋 Here you\'ll find a summary of all activities — hives, recent inspections and harvests. Tap a section to open it.';
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
  @override String dashCalendarTodayDate(String date) => 'Today — $date';
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
  @override String get dashEventArniaSep => ' — hive ';
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
  @override String get dashFabNewApiario => 'New apiary';

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
  @override String get forgotPasswordBtnRetry => 'I didn\'t receive the email — try again';

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
  @override String get venditeOfflineMsg => 'Offline mode — data from last access';
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
}
