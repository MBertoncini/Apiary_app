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
  String get voiceAudioPremiumSheetTitle;
  String get voiceAudioPremiumSheetBody;
  String get voiceAudioPremiumSheetActivate;

  // ── Voice input: extended access block (settings) ──
  String get voiceExtendedAccessTitle;
  String get voiceExtendedAccessDesc;
  String get voiceExtendedAccessCta;

  // ── Advanced API options block (settings, collapsed by default) ──
  String get settingsAdvancedOptions;
  String get settingsAdvancedOptionsSubtitle;
  String get settingsAdvancedOptionsDesc;

  // Equipment prompt (after hive creation)
  String get sectionEquipmentPrompt;
  String get settingsAttrezzaturaPrompt;
  String get settingsAttrezzaturaPromptSub;

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

  // ── Common extra buttons & labels ────────────────────────────────────────
  String get btnDelete;
  String get btnDeleteCaps;       // 'ELIMINA' / 'DELETE' for dialogs
  String get btnRetry;
  String get btnEdit;
  String get btnAdd;
  String get btnReplace;
  String get btnStart;
  String get btnStop;
  String get btnComplete;
  String get btnSearch;           // tooltip
  String get btnSend;

  String get labelLoading;
  String get labelNotes;
  String get labelAll;
  String get labelPersonal;
  String get labelDate;
  String get labelDateStart;
  String get labelDateEnd;
  String get labelDateEndOpt;     // 'Data fine (opzionale)'
  String get labelApiario;
  String get labelArnia;
  String get labelActive;
  String get labelInactive;
  String get labelOptional;       // '(opzionale)'
  String get labelNa;             // 'N/D' / 'N/A'
  String get labelYes;            // 'Sì' / 'Yes'
  String get labelNo;             // 'No' / 'No'

  String get msgErrorLoading;
  String msgErrorGeneric(String e);
  String get msgOfflineMode;

  // Common confirm-delete dialog
  String get dialogConfirmDeleteTitle;
  String get dialogConfirmDeleteBtn;
  String get dialogCancelBtn;

  // ── Apiario screens ───────────────────────────────────────────────────────
  // List
  String get apiarioListTitle;
  String get apiarioSearchHint;
  String apiarioNotFoundForQuery(String q);
  String get apiarioFabTooltip;
  String get apiarioBadgeMap;
  String get apiarioBadgeMeteo;
  String get apiarioBadgeShared;

  // Detail
  String get apiarioDetailLoading;
  String get apiarioDetailTooltipEdit;
  String get apiarioDetailTooltipDelete;
  String get apiarioDetailTooltipQr;
  String get apiarioDetailTooltipInfo;
  String get apiarioDetailTooltipAddArnia;
  String get apiarioDetailDeleteTitle;
  String get apiarioDetailDeletedOk;
  String apiarioDetailDeleteError(String e);
  String get apiarioDetailNoPdfArnie;
  String apiarioDetailPdfError(String e);
  String get apiarioDetailNoMeteo;
  String get apiarioDetailActivateMeteo;
  String get apiarioDetailNoCoords;
  String get apiarioDetailSetCoords;
  String get apiarioDetailLblTrattamenti;
  String get apiarioDetailNoTrattamenti;
  String get apiarioDetailAddTrattamento;
  String get apiarioDetailNewTrattamento;
  String get apiarioDetailBtnDettagli;
  String get apiarioDetailLblNote;
  String get apiarioDetailLblStatistiche;
  String get apiarioDetailErrorLoad;
  // Delete dialog (parameterised by apiary name)
  String apiarioDetailDeleteMsg(String nome);
  // Tab labels
  String get apiarioTabMeteo;
  // Treatment status (in the detail card)
  String get trattamentoStatusAnnullato;
  // Info bottom sheet labels
  String get apiarioDetailInfoPos;
  String get apiarioDetailInfoCoord;
  String get apiarioDetailInfoMeteoOn;
  String get apiarioDetailInfoMeteoOff;
  String get apiarioDetailInfoVis;
  String get apiarioDetailInfoSharing;
  String get apiarioDetailInfoShared;
  String get apiarioDetailInfoNotShared;

  // Form
  String get apiarioFormTitleNew;
  String get apiarioFormTitleEdit;
  String get apiarioFormLblName;
  String get apiarioFormHintName;
  String get apiarioFormLblSearchAddr;
  String get apiarioFormHintSearchAddr;
  String get apiarioFormTooltipSearch;
  String get apiarioFormBtnUsePos;
  String get apiarioFormLblLat;
  String get apiarioFormLblLon;
  String get apiarioFormVisibOwner;
  String get apiarioFormVisibGroup;
  String get apiarioFormVisibAll;
  String get apiarioFormVisibAllPrivacyNote;
  String get mapaApproxAreaLabel;
  String get apiarioFormMeteoTitle;
  String get apiarioFormMeteoSubtitle;
  String get apiarioFormShareTitle;
  String get apiarioFormShareSubtitle;
  String get apiarioFormLblGroup;
  String get apiarioFormLblNotes;
  String get apiarioFormHintNotes;
  // Form section headers
  String get apiarioFormSectionGeneral;
  String get apiarioFormSectionPos;
  String get apiarioFormSectionVisib;
  String get apiarioFormSectionFeatures;
  // Form validation messages
  String get apiarioFormValidateName;
  String get apiarioFormValidateLon;
  String get apiarioFormValidateLat;
  String get apiarioFormValidateFormat;
  String get apiarioFormValidateGroup;
  // Form misc
  String get apiarioFormMapHint;
  String get apiarioFormNoGruppi;
  String get apiarioFormBtnCreate;
  String get apiarioFormBtnUpdate;
  String get apiarioCreatedOk;
  String get apiarioUpdatedOk;
  String get apiarioPermDenied;
  String get apiarioPermDeniedPermanent;
  String get apiarioErrorPos;
  String get apiarioErrorAddr;

  // ── Arnia screens ─────────────────────────────────────────────────────────
  // List
  String get arniaListTitle;
  String get arniaFabTooltip;
  String get arniaEmptyTitle;
  String get arniaEmptySubtitle;
  String get arniaBtnCreate;
  String get arniaBtnRetry;
  String arniaItemTitle(int num);
  String get arniaStatusActive;
  String get arniaStatusInactive;
  String get arniaNoControllo;
  String arniaControlloDate(String d);
  String get arniaChipProblemi;
  String get arniaChipSciamatura;
  String arniaActiveCount(int active, int total);
  String get arniaCatAltri;
  String get arniaCatNuclei;
  String get arniaCatSpeciali;

  // Detail
  String get arniaDetailNotFound;
  String get arniaDetailErrorLoad;
  String arniaDetailTitle(int num);
  String get arniaDetailTooltipType;
  String get arniaDetailTooltipEdit;
  String get arniaDetailTooltipDelete;
  String get arniaDetailTooltipQr;
  String get arniaDetailTooltipInfo;
  String get arniaDetailDeleteTitle;
  String get arniaDetailDeletedOk;
  String arniaDetailDeleteError(String e);
  String get arniaDetailDeleteControlloTitle;
  String get arniaDetailControlloDeletedOk;
  String arniaDetailControlloDeleteError(String e);
  String get arniaDetailReplaceReginaTitle;
  String get arniaDetailReplaceReginaBtn;
  String get arniaDetailChangeTypeTitle;
  String arniaDetailTypeUpdated(String tipo);
  String arniaDetailTypeError(String e);
  String get arniaDetailBtnRegControllo;
  String get arniaDetailBtnAddRegina;
  String get arniaDetailBtnEditRegina;
  String get arniaDetailBtnReplaceRegina;
  String get arniaDetailBtnAvviaAnalisi;
  String get arniaDetailTooltipEditControllo;
  String get arniaDetailTooltipDeleteControllo;
  String get arniaDetailLblMotivo;
  String get arniaDetailLblDataRimozione;
  String get arniaDetailLblGenealogia;
  String get arniaDetailRegistraControllo;
  String get arniaDetailBtnModifica;
  String get arniaDetailBtnSostituisci;
  String arniaDetailError(String e);

  // Tab labels
  String get arniaTabControlli;
  String get arniaTabRegina;
  String get arniaTabAnalisi;

  // Controlli tab content
  String get arniaDetailNoControlli;
  String arniaDetailControlloTitle(String date);
  String arniaDetailControlloBy(String user);
  String arniaDetailScorte(int n);
  String arniaDetailCovata(int n);
  String get arniaDetailReginaPresente;
  String get arniaDetailReginaAssente;
  String get arniaDetailReginaVista;
  String get arniaDetailUovaFresche;
  String arniaDetailCelleReali(int n);
  String get arniaDetailProblemiSanitari;

  // Regina tab content
  String get arniaDetailNoRegina;
  String get arniaDetailReginaIncompleta;
  String get arniaDetailReginaAutoMsg;
  String arniaDetailIntrodottaIl(String date);
  String get arniaDetailSectionGeneral;
  String get arniaDetailLblDataNascita;
  String get arniaDetailLblValutazioni;
  String get arniaDetailRatingDocilita;
  String get arniaDetailRatingProduttivita;
  String get arniaDetailRatingResistenza;
  String get arniaDetailRatingTendenzaSciamatura;
  String get arniaDetailLblMadre;
  String get arniaDetailReginaFondatrice;
  String get arniaDetailLblFiglie;
  String get arniaDetailLblStoria;
  String get arniaDetailStoriaCorrente;

  // Origine regina (used in _getOrigineRegina)
  String get arniaDetailOrigineAcquistata;
  String get arniaDetailOrigineAllevata;
  String get arniaDetailOrigineSciamatura;
  String get arniaDetailOrigineEmergenza;
  String get arniaDetailOrigineSconosciuta;

  // Analisi tab content
  String get arniaDetailNoAnalisi;
  String get arniaDetailBtnAnalisiTelaino;
  String arniaDetailAnalisiTagApi(int n);
  String arniaDetailAnalisiTagRegine(int n);
  String arniaDetailAnalisiTagFuchi(int n);
  String arniaDetailAnalisiTagCelleReali(int n);

  // Info sheet
  String get arniaDetailInfoInstallata;
  String get arniaDetailInfoTipo;
  String get arniaDetailInfoColore;
  String get arniaDetailInfoNonSpecificata;

  // Replace regina dialog
  String get arniaDetailReplaceReginaMsg;
  String get arniaDetailChangeMotivoSostituzione;
  String get arniaDetailChangeMotivoMorte;
  String get arniaDetailChangeMotivoSciamatura;
  String get arniaDetailChangeMotivoProblemaSanitario;
  String get arniaDetailChangeMotivoAltro;

  // Cambio tipo sheet
  String get arniaDetailChangeTypeMsg;

  // Delete confirm dialogs
  String arniaDetailDeleteMsg(String num);
  String arniaDetailDeleteControlloMsg(String date);

  // Form
  String get arniaFormTitleNew;
  String get arniaFormTitleEdit;
  String get arniaFormLblApiario;
  String get arniaFormHintApiario;
  String get arniaFormLblNumero;
  String get arniaFormHintNumero;
  String get arniaFormLblColore;
  String get arniaFormLblDataInstall;
  String get arniaFormActiveTitle;
  String get arniaFormLblNotes;
  String get arniaFormHintNotes;
  String get arniaFormLblTipoArnia;
  String get arniaFormBtnCreate;
  String get arniaFormBtnUpdate;
  String get arniaFormValidateApiario;
  String get arniaFormValidateNumero;
  String get arniaFormValidateNumeroFormat;
  String arniaFormValidateNumeroUsato(int n);
  String get arniaCreatedOk;
  String get arniaUpdatedOk;
  String get arniaLoadApiariError;
  String arniaFormError(String e);

  // ── Trattamento screens ───────────────────────────────────────────────────
  // List
  String get trattamentiTitle;
  String get trattamentiNoData;
  String get trattamentiBtnNew;
  String trattamentiInizio(String d);
  String trattamentiFine(String d);
  String trattamentiFineSOSP(String d);
  String trattamentiNote(String n);
  String get trattamentiBtnAvvia;
  String get trattamentiBtnAnnullaStatus;
  String get trattamentiBtnCompleta;
  String get trattamentiBtnInterrompi;
  String get trattamentiBtnRipristina;
  String get trattamentoRestoredOk;
  String trattamentoRestoreError(String e);
  String get trattamentiDeleteTitle;
  String get trattamentiDeletedOk;
  String trattamentiDeleteError(String e);
  String trattamentiError(String e);
  // Tab labels
  String get trattamentiTabAttivi;
  String get trattamentiTabCompletati;
  // Empty-state per tab
  String get trattamentiNoAttivi;
  String get trattamentiNoCompletati;
  // Delete dialog message
  String trattamentiDeleteMsg(String nome);
  // Hives selected label
  String trattamentiArnieSelezionate(int n);
  // Administration method labels
  String get trattamentiMetodoStrisce;
  String get trattamentiMetodoGocciolato;
  String get trattamentiMetodoSublimato;

  // Detail
  String get trattamentoDetailTitle;
  String get trattamentoDetailDeleteTitle;
  String get trattamentoDetailDeleteMsg;
  String get trattamentoDetailTooltipEdit;
  String get trattamentoDetailTooltipDelete;
  String get trattamentoDetailTooltipRestore;
  String get trattamentoDetailDeletedOk;
  String trattamentoDetailDeleteError(String e);
  String trattamentoDetailArniaLabel(String id);
  String get trattamentoDetailApplicatoTutto;
  // Detail section/field labels
  String get trattamentoDetailLblCaricamento;
  String get trattamentoDetailSectionDettagli;
  String get trattamentoDetailLblMetodo;
  String get trattamentoDetailLblDataInizio;
  String get trattamentoDetailLblDataFine;
  String get trattamentoDetailLblSospFino;
  String get trattamentoDetailLblArnieTrattate;
  String get trattamentoDetailLblBloccoCovata;
  String get trattamentoDetailLblInizioBlocko;
  String get trattamentoDetailLblFineBlocko;
  String get trattamentoDetailLblMetodoBlocko;
  String get trattamentoDetailLblNoteBlocko;

  // Form
  String get trattamentoFormOfflineMsg;
  String get trattamentoFormNewProductTitle;
  String get trattamentoFormLblProductName;
  String get trattamentoFormHintProductName;
  String get trattamentoFormLblPrincipioAttivo;
  String get trattamentoFormHintPrincipioAttivo;
  String get trattamentoFormLblGiorniSosp;
  String get trattamentoFormHintGiorniSosp;
  String get trattamentoFormLblDescrizione;
  String get trattamentoFormBloccoCovataReq;
  String get trattamentoFormLblDurataBlockco;
  String get trattamentoFormLblNote;
  String get trattamentoFormHintNote;
  String get trattamentoFormApplicaTutto;
  String get trattamentoFormApplicaSpecifiche;
  String get trattamentoFormSelectPrimaApiario;
  String get trattamentoFormNoArnie;
  String get trattamentoFormLblProdotto;
  String get trattamentoFormDataInizio;
  String get trattamentoFormDataFine;
  String get trattamentoFormBloccoCovataActive;
  String get trattamentoFormCreatedOk;
  String get trattamentoFormUpdatedOk;
  String trattamentoFormNewProductError(String e);
  String get trattamentoFormSelectApiarioMsg;
  String get trattamentoFormSelectTypeMsg;
  String get trattamentoFormSelectArnieMsg;
  String trattamentoFormError(String e);
  // Form title/buttons
  String get trattamentoFormTitleNew;
  String get trattamentoFormTitleEdit;
  String get trattamentoFormBtnCreate;
  String get trattamentoFormBtnUpdate;
  String get trattamentoFormBtnCreateProduct;
  // Form misc labels
  String get trattamentoFormLblApplica;
  String get trattamentoFormHintProdotto;
  String get trattamentoFormValidateCampoObbligatorio;
  String get trattamentoFormValidateNumeroGe0;
  String get trattamentoFormValidateNumeroGt0;
  // Blocco covata form fields
  String get trattamentoFormLblDataInizioBlocco;
  String get trattamentoFormLblDataFineBlocco;
  String get trattamentoFormErrFirstDateBlocco;
  String get trattamentoFormLblMetodoBlocco;
  String get trattamentoFormHintMetodoBlocco;
  String get trattamentoFormHintNoteBlocco;
  String get trattamentoFormLblMetodoApplicazione;
  String get trattamentoFormLblNoteBloccoCovata;

  // ── Fioritura screens ─────────────────────────────────────────────────────
  // List
  String get fiorituraListTitle;
  String get fiorituraTabMie;
  String get fiorituraTabCommunity;
  String get fiorituraFabTooltip;
  String get fiorituraSearchHint;
  String get fiorituraListNoData;
  String get fiorituraListLoadError;
  String fiorituraListDeleteMsg(String name);
  String get fiorituraDeleteTitle;
  String get fiorituraDeletedOk;
  String fiorituraDeleteError(String e);
  String get fiorituraMenuEdit;
  String get fiorituraMenuDelete;
  String get fiorituraCardAttiva;
  String get fiorituraCardNonAttiva;
  String get fiorituraCardPubblica;
  String fiorituraCardConferme(int n);
  String get fiorituraCardTu;
  String fiorituraDateFrom(String date);

  // Detail
  String get fiorituraDetailTitle;
  String get fiorituraDetailNotFound;
  String get fiorituraDetailTooltipEdit;
  String get fiorituraDetailConfirmOk;
  String get fiorituraDetailLblCommunity;
  String get fiorituraDetailLblIntensity;
  String get fiorituraDetailBtnRemove;
  String get fiorituraDetailLblPosizione;
  String fiorituraDetailError(String e);
  String get fiorituraDetailLblPeriodo;
  String get fiorituraDetailLblRaggio;
  String get fiorituraDetailLblTipoPianta;
  String get fiorituraDetailLblIntensitaStimata;
  String get fiorituraDetailLblVisibilita;
  String get fiorituraDetailValPubblica;
  String get fiorituraDetailValPrivata;
  String get fiorituraDetailLblSegnalata;
  String get fiorituraDetailStatConfermanti;
  String get fiorituraDetailStatIntensita;
  String get fiorituraDetailConfermata;
  String get fiorituraDetailConfermaQuestion;
  String get fiorituraDetailHintNota;
  String get fiorituraDetailBtnAggiorna;
  String get fiorituraDetailBtnConferma;

  // Form
  String get fiorituraFormTitleNew;
  String get fiorituraFormTitleEdit;
  String get fiorituraFormTooltipSave;
  String get fiorituraFormLblPianta;
  String get fiorituraFormLblTipoPianta;
  String get fiorituraFormLblDataInizio;
  String get fiorituraFormLblDataFine;
  String get fiorituraFormLblRaggio;
  String get fiorituraFormLblIntensita;
  String get fiorituraFormLblNote;
  String get fiorituraFormVisibilitaTitle;
  String get fiorituraFormVisibilitaSubtitle;
  String get fiorituraFormBtnUsePos;
  String get fiorituraFormHintNonSpecificato;
  String get fiorituraFormHintNonValutata;
  String get fiorituraFormHintSeleziona;
  String get fiorituraFormHintNessuna;
  String get fiorituraFormMapHint;
  String get fiorituraFormErrDataInizio;
  String get fiorituraFormErrPosition;
  String fiorituraFormError(String e);
  String get fiorituraFormTipoSpontanea;
  String get fiorituraFormTipoColtivata;
  String get fiorituraFormTipoAlberata;
  String get fiorituraFormTipoArborea;
  String get fiorituraFormTipoArbustiva;
  String get fiorituraFormIntensita1;
  String get fiorituraFormIntensita2;
  String get fiorituraFormIntensita3;
  String get fiorituraFormIntensita4;
  String get fiorituraFormIntensita5;

  // ── Regina screens ────────────────────────────────────────────────────────
  // List
  String get reginaListTitle;
  String get reginaListSyncTooltip;
  String get reginaListBtnRetry;
  String reginaListItemTitle(String arniaNr);
  String get reginaListRazza;
  String get reginaListOrigine;
  String get reginaListIntrodotta;
  String get reginaListMarcata;
  String get reginaListDetailError;

  // Detail
  String get reginaDetailTitle;
  String get reginaDetailNotFound;
  String reginaDetailTitleArnia(String arniaId);
  String get reginaDetailTooltipDelete;
  String get reginaDetailBtnEdit;
  String get reginaDetailBtnReplace;
  String get reginaDetailBtnRetry;
  String get reginaDetailDeleteTitle;
  String get reginaDetailDeletedOk;
  String reginaDetailDeleteError(String e);
  String get reginaDetailReplaceTitle;
  String get reginaDetailReplaceBtn;
  String get reginaDetailLblMotivo;
  String get reginaDetailLblDataRimozione;
  String get reginaDetailStatusAttuale;
  String get reginaDetailLblDal;
  String get reginaDetailLblAl;
  String get reginaDetailLblMotivoCambio;
  String get reginaDetailStatusAttiva;
  String get reginaDetailStatusNonAttiva;
  String reginaDetailParentela(String parentela, String data);
  String reginaDetailError(String e);

  // List extra
  String get reginaListOfflineTooltip;
  String get reginaListEmptyTitle;
  String get reginaListEmptySubtitle;

  // Detail extra
  String get reginaDetailTabDettagli;
  String get reginaDetailTabGenealogia;
  String get reginaDetailSectionGeneral;
  String get reginaDetailSectionMarcatura;
  String get reginaDetailLblDataNascita;
  String get reginaDetailLblSelezionata;
  String reginaDetailLblEta(String age);
  String get reginaDetailAlberoGenealogia;
  String reginaDetailAlberoSubtitle(String arniaId);
  String get reginaDetailNoGenealogia;
  String get reginaDetailGenealogiaNonDisp;
  String get reginaDetailReginaAttuale;
  String reginaDetailFiglie(int n);
  String get reginaDetailStoriaArnie;
  String get reginaDetailInfoAggiuntive;
  String reginaDetailChipIntrodotta(String date);
  String reginaDetailChipNata(String date);
  String reginaDetailDeleteMsg(String arniaId);
  String reginaDetailAgeAnni(int n);
  String reginaDetailAgeMesi(int n);
  String reginaDetailAgeGiorni(int n);
  String get reginaDetailColoreBianco;
  String get reginaDetailColoreGiallo;
  String get reginaDetailColoreRosso;
  String get reginaDetailColoreVerde;
  String get reginaDetailColoreBlu;
  String get reginaDetailColoreNonMarcata;

  // Form
  String get reginaFormTitleNew;
  String get reginaFormTitleEdit;
  String get reginaFormLblRazza;
  String get reginaFormLblOrigine;
  String get reginaFormLblDataIntroduzione;
  String get reginaFormLblDataNascita;
  String get reginaFormMarcataTitle;
  String get reginaFormLblColoreMarcatura;
  String get reginaFormFecondataTitle;
  String get reginaFormSelezionataTitle;
  String get reginaFormHintNessunaRegina;
  String get reginaFormBtnSave;
  String reginaFormError(String e);
  String get reginaFormHintDataNascitaVuota;
  String get reginaFormValutazioniTitle;
  String get reginaFormValutazioniHint;
  String get reginaFormLblReginaMadre;
  String get reginaFormLblNote;
  String get reginaFormCreatedOk;
  String get reginaFormUpdatedOk;

  // ── Melario / Smielatura screens ──────────────────────────────────────────
  String get melariTitle;
  String get melariTooltipAdd;
  String get melariBtnNuovaSmielatura;
  String get melariTabTutti;
  String get melariTabPersonali;
  String get melariNoSmielature;
  String get melariRiepilogoProd;
  String get melariKg;
  String melariSmielaturaItem(String tipo, String qty);
  String melariSmielaturaSubtitle(String date, String apiario, int count);
  String get melariCantinaTitolo;
  String get melariCantinaSubtitle;
  String get melariNoInvasettamento;
  String get melariRiepilogoInvasettamento;
  String melariVasettiLabel(String formato);
  String get melariVasetti;
  String melariInvasettamentoItem(String tipo, String formato, int num);
  String melariInvasettamentoSubtitle(String date, String kg, String? lotto);
  String get melariMenuEdit;
  String get melariMenuDelete;
  String get melariDeleteInvasettTitle;
  String get melariDeleteInvasettMsg;
  String get melariDeleteInvasettOk;
  String melariDeleteInvasettError(String e);
  String get melariRemoveMelarioTitle;
  String get melariRemoveMelarioDialogTitle;
  String get melariEliminaMelarioTitle;
  String get melariLblPesoStimato;
  String get melariNoData;
  String get melariMelarioLabel;
  String melariArniaLabel(String num);
  String get melariPosizionati;
  String get melariInSmielatura;
  String melariMelarioId(int id);
  String melariTelainiPosizione(int telaini, int posizione, String tipo);
  String get melariSmielBtn;
  String get melariQeLabel;

  // Melari screen extra
  String get melariTabAlveari;
  String get melariTabSmielature;
  String get melariSummaryTotale;
  String get melariSummarySmielature;
  String get melariSummaryTipi;
  String get melariSummaryInvasettato;
  String get melariSummaryRaccolto;
  String get melariHiveLegendNido;
  String get melariHiveLegendPosizionato;
  String get melariHiveLegendInSmielatura;
  String get melariHiveLblNido;
  String get melariNoMelari;
  String melariCountMelari(int n);
  String melariArniaNumLabel(int n);
  String melariFaviLabel(int n);
  String melariPosTipoLabel(int pos, String tipo);
  String melariTelainiLabel(int n);
  String melariPesoStimatoLabel(String peso);
  String get melariRemoveMelarioMsg;
  String melariDeleteMelarioMsg(int id);
  String get melariDeleteMelarioOk;
  String melariDeleteMelarioError(String e);
  String melariRemoveMelarioError(String e);
  String get melariConfirmBtn;
  String get melariMiniMapTitle;
  String get melariMiniMapNoLayout;
  String get melariMiniMapTapHint;
  // Melario form
  String get melarioFormTitle;
  String get melarioFormSectionId;
  String get melarioFormSectionProd;
  String get melarioFormLblTipo;
  String get melarioFormLblStatoFavi;
  String get melarioFormLblNumTelaini;
  String get melarioFormLblPosizione;
  String get melarioFormLblEscludiRegina;
  String get melarioFormSubEscludiRegina;
  String get melarioFormLblNote;
  String get melarioFormHintNote;
  String get melarioFormBtnAdd;
  String get melarioFormFaviCostruiti;
  String get melarioFormFaviCerei;
  String get melarioFormLblDataPos;
  String get melarioFormHintSelectApiario;
  String get melarioFormNoArnie;
  String get melarioFormValidateArnia;
  String melarioFormLoadError(String e);
  String melarioFormArnieLoadError(String e);
  String get melarioFormCreatedOk;

  // Smielatura form
  String get smielaturaFormTitleNew;
  String get smielaturaFormTitleEdit;
  String get smielaturaFormLblApiario;
  String get smielaturaFormLblData;
  String get smielaturaFormLblTipoMiele;
  String get smielaturaFormLblQuantita;
  String get smielaturaFormLblNote;
  String smielaturaFormMelarioItem(int id, String arniaNum);
  String smielaturaFormMelarioStato(String stato);
  String get smielaturaFormSelectApiarioMsg;
  String smielaturaFormError(String e);
  String get smielaturaFormOfflineMsg;
  String get smielaturaFormLblMelariDisp;
  String get smielaturaFormValidateNumero;
  String get smielaturaFormValidateQuantitaMax;
  String get smielaturaFormSelectMelarioMsg;
  String get smielaturaFormNoMelariDisp;
  String get smielaturaFormBtnCreate;
  String get smielaturaFormBtnUpdate;
  String get smielaturaFormCreatedOk;
  String get smielaturaFormUpdatedOk;
  // Smielatura detail
  String get smielaturaDetailTitle;
  String get smielaturaDetailDeleteTitle;
  String get smielaturaDetailDeleteMsg;
  String get smielaturaDetailDeletedOk;
  String get smielaturaDetailNotFound;
  String smielaturaDetailMelariCount(int n);
  String get smielaturaDetailMelariAssociati;
  String get smielaturaDetailLblMelari;

  // ── Invasettamento form ───────────────────────────────────────────────────
  String get invasettamentoFormTitleNew;
  String get invasettamentoFormTitleEdit;
  String get invasettamentoFormLblSmielatura;
  String get invasettamentoFormValidateSmielatura;
  String get invasettamentoFormCreatedOk;
  String get invasettamentoFormUpdatedOk;
  String get invasettamentoFormLblFormato;
  String get invasettamentoFormLblNumVasetti;
  String get invasettamentoFormValidateNumVasetti;
  String invasettamentoFormLblTotale(String kg);
  String get invasettamentoFormLblLotto;

  // ── Controllo form (legacy keys) ──────────────────────────────────────────
  String get controlloFormDialogTitle;
  String get controlloFormBtnAutoOrdina;
  String get controlloFormLblNumCelleReali;
  String get controlloFormLblNoteSciamatura;
  String get controlloFormLblDettagliProblemi;
  String get controlloFormLblColore;
  String get controlloFormToccoTelaino;

  // ── Dashboard Screen ─────────────────────────────────────────────────────

  // Sync / Refresh snackbars
  String get dashSyncing;
  String get dashSyncDone;

  // Exit-app dialog
  String get dashExitTitle;
  String get dashExitMessage;
  String get dashExitCancel;
  String get dashExitConfirm;

  // AppBar / Search
  String get dashTitle;
  String get dashSearchHint;
  String get dashSearchTooltip;
  String get dashCloseSearchTooltip;

  // Welcome header
  String dashWelcomeUser(String name);

  // Contextual hint
  String get dashContextualHint;

  // Calendar header & navigation
  String get dashCalendarTitle;
  String get dashCalendarToday;
  String get dashCalendarPrevWeek;
  String get dashCalendarNextWeek;
  String get dashCalendarPrevMonth;
  String get dashCalendarNextMonth;
  String get dashCalendarViewMonth;
  String get dashCalendarViewWeek;

  // Calendar legend labels
  String get dashCalendarLegendControlli;
  String get dashCalendarLegendTrattamenti;
  String get dashCalendarLegendFioriture;
  String get dashCalendarLegendRegine;
  String get dashCalendarLegendMelari;
  String get dashCalendarLegendSmielature;
  String get dashCalendarLegendSospensione;
  String get dashCalendarLegendBloccoCovata;

  // Calendar selected-day header
  String dashCalendarTodayDate(String date);
  String dashCalendarDateEvents(String date);
  String get dashCalendarNoEventsToday;
  String get dashCalendarNoEvents;

  // Weekday abbreviations (Mon=0 … Sun=6)
  List<String> get dashWeekdayAbbr;

  // Calendar event titles (built in _prepareCalendarEvents)
  String get dashEventTrattamento;
  String get dashEventSospensione;
  String get dashEventBloccoCovata;
  String get dashEventFioritura;
  String dashEventControlloArnia(String num);
  String get dashEventReginaIntrodotta;
  /// Separator used in "Queen introduced — hive 3"
  String get dashEventArniaSep;
  String get dashEventMelarioPosizionato;
  String get dashEventMelarioRimosso;
  String get dashEventSmielatura;

  // Dashboard sections
  String get dashSectionApiari;
  String get dashSectionTrattamenti;
  String get dashSectionFioriture;
  String get dashBtnViewAll;
  String get dashBtnCreateApiario;

  // Empty-state messages
  String get dashNoApiari;
  String get dashNoTrattamenti;
  String get dashNoFioriture;

  // Data-load error
  String dashLoadError(String err);

  // Alerts widget
  String get dashAlertsTitle;
  String get dashAlertViewDetails;
  String get dashAlertTrattamentoExpiringTitle;
  String dashAlertTrattamentoExpiringMsg(String nome, int days);
  String get dashAlertApiarioToVisitTitle;
  String dashAlertApiarioToVisitMsg(String nome);

  // Weather card
  String get dashWeatherLocal;
  String dashWeatherHumidity(String pct);

  // Apiario card
  String get dashPositionNone;

  // Trattamento card
  String get dashStatusNd;
  String get dashStatusInCorso;
  String get dashStatusProgrammato;
  String get dashStatusCompletato;
  String get dashStatusApiario;
  String dashTrattamentoDates(String start, String end);

  // Fioritura card
  String get dashFiorituraAttiva;
  String get dashFiorituraTerminata;
  String dashFiorituraDates(String start, String? end);

  // Search results
  String dashSearchNoResults(String query);
  String dashSearchSection(String label, int count);

  // Speed-dial labels
  String get dashFabVoiceInput;
  String get dashFabAiAssistant;
  String get dashFabScanQr;
  String get dashFabNewApiario;

  // ── Auth – Login Screen ───────────────────────────────────────────────────
  String get loginSubtitle;
  String get loginFieldUsernameLabel;
  String get loginFieldUsernameHint;
  String get loginFieldUsernameValidate;
  String get loginFieldPasswordLabel;
  String get loginFieldPasswordHint;
  String get loginFieldPasswordValidate;
  String get loginForgotPassword;
  String get loginBtnAccedi;
  String get loginOr;
  String get loginBtnGoogle;
  String get loginBtnRegister;
  String get loginErrUserNotFound;
  String get loginErrWrongPassword;
  String get loginErrWrongCredentials;
  String get loginErrGoogleAuth;
  String get loginErrGoogleToken;
  String get loginErrNetwork;
  String get loginErrTimeout;
  String get loginErrServer;
  String get loginErrDefault;
  String get loginHintForgotPassword;
  String get loginHintRegister;

  // ── Auth – Register Screen ────────────────────────────────────────────────
  String get registerTitle;
  String get registerCreateAccount;
  String get registerFieldUsername;
  String get registerHintUsername;
  String get registerValidateUsername;
  String get registerFieldEmail;
  String get registerHintEmail;
  String get registerValidateEmail;
  String get registerValidateEmailFormat;
  String get registerFieldPassword;
  String get registerHintPassword;
  String get registerValidatePassword;
  String get registerValidatePasswordLength;
  String get registerFieldConfirmPassword;
  String get registerHintConfirmPassword;
  String get registerValidateConfirmPassword;
  String get registerValidatePasswordMatch;
  String get registerErrPasswordMismatch;
  String get registerErrPrivacyRequired;
  String get registerPrivacyText;
  String get registerPrivacyLink;
  String get registerBtnRegister;
  String get registerBtnLogin;
  String get registerSuccessMsg;
  String get registerErrGeneric;
  String get registerErrNetwork;

  // ── Auth – Forgot Password Screen ─────────────────────────────────────────
  String get forgotPasswordTitle;
  String get forgotPasswordResetTitle;
  String get forgotPasswordSubtitle;
  String get forgotPasswordFieldEmail;
  String get forgotPasswordHintEmail;
  String get forgotPasswordValidateEmail;
  String get forgotPasswordValidateEmailFormat;
  String get forgotPasswordBtnSend;
  String get forgotPasswordBtnBack;
  String get forgotPasswordSuccessTitle;
  String forgotPasswordSuccessBody(String email);
  String get forgotPasswordBtnBackToLogin;
  String get forgotPasswordBtnRetry;

  // ── Colonia screens ───────────────────────────────────────────────────────
  String get coloniaDetailTitle;
  String get coloniaDetailNotFound;
  String get coloniaDetailTabInfo;
  String get coloniaDetailTabControlli;
  String get coloniaDetailMenuChiudi;
  String get coloniaDetailLblContenitore;
  String get coloniaDetailLblApiario;
  String get coloniaDetailLblInsediataIl;
  String get coloniaDetailLblChiusaIl;
  String get coloniaDetailLblMotivoFine;
  String get coloniaDetailSectionRegina;
  String get coloniaDetailLblRazza;
  String get coloniaDetailLblOrigine;
  String get coloniaDetailLblIntrodottaIl;
  String get coloniaDetailLblOrigineDa;
  String get coloniaDetailLblConfluitaIn;
  String get coloniaDetailLblTotaleControlli;
  String get coloniaDetailSectionNote;
  String get coloniaDetailNoControlli;
  String coloniaId(int id);
  String coloniaOrigineDaId(int id);
  String coloniaConfluitaInId(int id);
  String coloniaControlloSubtitle(int scorte, int covata);
  String get coloniaControlloSciamatura;

  // Colonia form
  String get coloniaFormTitle;
  String get coloniaFormLblData;
  String get coloniaFormHintData;
  String get coloniaFormValidateData;
  String get coloniaFormLblNote;
  String get coloniaFormCreatedOk;
  String get coloniaFormErrorSave;
  String coloniaFormError(String e);

  // Colonia chiudi
  String coloniaChiudiTitle(int id);
  String get coloniaChiudiWarning;
  String get coloniaChiudiLblStato;
  String get coloniaChiudiLblData;
  String get coloniaChiudiLblMotivo;
  String get coloniaChiudiLblNote;
  String get coloniaChiudiValidateStato;
  String get coloniaChiudiValidateData;
  String get coloniaChiudiBtn;
  String get coloniaChiusaOk;
  String coloniaChiudiError(String e);
  String get coloniaStatoMorta;
  String get coloniaStatoVenduta;
  String get coloniaStatoSciamata;
  String get coloniaStatoUnita;
  String get coloniaStatoNucleo;
  String get coloniaStatoEliminata;

  // Storia colonie
  String get storiaColonieTitle;
  String get storiaColonieEmpty;
  String storiaColonieItem(int id, String stato);
  String storiaColonieDates(String start, String? end);
  String get storiaColonieInCorso;

  // ── Attrezzatura screens ──────────────────────────────────────────────────
  // List
  String get attrezzatureTitle;
  String get attrezzatureFiltriAvanzatiTooltip;
  String get attrezzatureSincronizzaTooltip;
  String get attrezzaturaSearchHint;
  String get attrezzaturaCatTutti;
  String get attrezzaturaCatTutte;
  String get attrezzaturaCatConsumabili;
  String get attrezzaturaCatProtezione;
  String get attrezzaturaCatStrumenti;
  String get attrezzaturaCatAltro;
  String attrezzaturaQta(int n);
  String attrezzaturaAcquistatoDate(String d);
  String get attrezzaturaNoRegistrata;
  String get attrezzaturaNoFiltri;
  String get attrezzaturaBtnAggiungi;
  String get attrezzaturaBtnRimuoviFiltri;
  String get attrezzaturaFiltriAvanzatiTitle;
  String get attrezzaturaFiltriReset;
  String get attrezzaturaFiltriLblStato;
  String get attrezzaturaFiltriLblCondizione;
  String get attrezzaturaFiltriLblDataAcquisto;
  String get attrezzaturaFiltriLblPrezzo;
  String get attrezzaturaFiltriApplica;
  String get attrezzaturaFabTooltip;
  String get attrezzaturaErrLoading;

  // Detail
  String get attrezzaturaDetailTitle;
  String get attrezzaturaDetailTabInfo;
  String get attrezzaturaDetailTabSpese;
  String get attrezzaturaDetailTabManutenzioni;
  String get attrezzaturaDetailNonCategorizzato;
  String get attrezzaturaDetailLblCondizione;
  String get attrezzaturaDetailLblDescrizione;
  String get attrezzaturaDetailLblMarca;
  String get attrezzaturaDetailLblModello;
  String get attrezzaturaDetailLblSerie;
  String get attrezzaturaDetailLblQuantita;
  String get attrezzaturaDetailLblUnitaMisura;
  String get attrezzaturaDetailLblDataAcquisto;
  String get attrezzaturaDetailLblPrezzoAcquisto;
  String get attrezzaturaDetailLblFornitore;
  String get attrezzaturaDetailLblGaranzia;
  String get attrezzaturaDetailLblPosizione;
  String get attrezzaturaDetailLblGruppo;
  String get attrezzaturaDetailStatistiche;
  String get attrezzaturaDetailSpeseTotali;
  String get attrezzaturaDetailNessunaSpesa;
  String get attrezzaturaDetailBtnAggiungiSpesa;
  String get attrezzaturaDetailNessunaManutenzione;
  String get attrezzaturaDetailBtnAggiungiManutenzione;
  String get attrezzaturaDetailInRitardo;
  String attrezzaturaDetailProgrammata(String d);
  String get attrezzaturaDetailMenuAddSpesaTitle;
  String get attrezzaturaDetailMenuAddSpesaSubtitle;
  String get attrezzaturaDetailMenuAddManutenzioneTitle;
  String get attrezzaturaDetailMenuAddManutenzioneSubtitle;
  String get attrezzaturaDeleteTitle;
  String get attrezzaturaDeletedOk;
  String attrezzaturaDeleteError(String e);
  String get attrezzaturaDeleteSpesaTitle;
  String get attrezzaturaDeleteSpesaOk;
  String attrezzaturaDeleteSpesaError(String e);
  String get attrezzaturaDeleteManutenzioneTitle;
  String get attrezzaturaDeleteManutenzioneOk;
  String attrezzaturaDeleteManutenzioneError(String e);
  String get attrezzaturaErrDetailLoading;
  String get attrezzaturaEliminaSpesaTooltip;
  String get attrezzaturaEliminaManutenzioneTooltip;

  // ── Vendita screens ───────────────────────────────────────────────────────
  String get venditeTitle;
  String get venditeTabVendite;
  String get venditeTabClienti;
  String get venditeOfflineMsg;
  String get venditeNoVendite;
  String get venditeNoClienti;
  String get venditeErrLoading;
  String venditeArticoli(int n);
  String venditeClienteVendite(int n);
  String get venditeTooltipSync;
  String get venditeFabTooltip;
  String get venditeClientiFabTooltip;

  // ── Gruppo screens ────────────────────────────────────────────────────────
  String get gruppiTitle;
  String get gruppiFabTooltip;
  String get gruppiInvitoAccettato;
  String get gruppiInvitoRifiutato;
  String gruppiInvitoError(String e);
  String get gruppiBtnRifiuta;
  String get gruppiBtnAccetta;
  String get gruppiBtnCrea;
  String get gruppiErrLoading;
  String get gruppiBtnRiprova;
  String get gruppiTuoiGruppi;
  String get gruppiInvitiRicevuti;
  String get gruppiNoMembro;
  String gruppiInvitatoDa(String user, String ruolo);
  String gruppiDataInvio(String d);
  String gruppiScadeIl(String d);
  String gruppiMembriCount(int n);
  String gruppiApiariCondivisi(int n);
  String get gruppiErrLoadingGruppi;

  // ── Attrezzatura form ─────────────────────────────────────────────────────
  String get attrezzaturaFormTitleNew;
  String get attrezzaturaFormTitleEdit;
  String get attrezzaturaFormLblNome;
  String get attrezzaturaFormValidateNome;
  String get attrezzaturaFormValidateCampoObbligatorio;
  String get attrezzaturaFormLblMarca;
  String get attrezzaturaFormLblModello;
  String get attrezzaturaFormLblQuantita;
  String get attrezzaturaFormValidateQuantita;
  String get attrezzaturaFormValidateNumero;
  String get attrezzaturaFormLblStato;
  String get attrezzaturaFormLblCondizione;
  String get attrezzaturaFormLblDataAcquisto;
  String get attrezzaturaFormLblPrezzoAcquisto;
  String get attrezzaturaFormHelperPrezzo;
  String get attrezzaturaFormValidateImporto;
  String get attrezzaturaFormLblFornitore;
  String get attrezzaturaFormSectionCondivisione;
  String get attrezzaturaFormLblCondividi;
  String get attrezzaturaFormSubCondividi;
  String get attrezzaturaFormLblChiHaPagato;
  String get attrezzaturaFormHintIoStesso;
  String get attrezzaturaFormHelperChiPaga;
  String get attrezzaturaFormLblNote;
  String get attrezzaturaFormInfoPagamento;
  String get attrezzaturaFormBtnSalva;
  String get attrezzaturaFormBtnAggiorna;
  String get attrezzaturaFormCreatedOk;
  String get attrezzaturaFormUpdatedOk;
  String get attrezzaturaFormPagamentoAuto;
  String attrezzaturaFormLoadError(String e);
  String attrezzaturaFormSaveError(String e);
  // Stato labels
  String get attrezzaturaStatoDisponibile;
  String get attrezzaturaStatoInUso;
  String get attrezzaturaStatoManutenzione;
  String get attrezzaturaStatoDismesso;
  String get attrezzaturaStatoPrestato;
  // Condizione labels
  String get attrezzaturaCondizioneNuovo;
  String get attrezzaturaCondizioneOttimo;
  String get attrezzaturaCondizioneBuono;
  String get attrezzaturaCondizioneDiscreto;
  String get attrezzaturaCondizioneUsurato;
  String get attrezzaturaCondizioneDaRiparare;

  // ── Attrezzatura prompt (popup lite dopo creazione arnia) ────────────────
  String get attrezzaturaPromptTitle;
  String get attrezzaturaPromptBody;
  String get attrezzaturaPromptNome;
  String get attrezzaturaPromptCondizione;
  String get attrezzaturaPromptPrezzo;
  String get attrezzaturaPromptSkip;
  String get attrezzaturaPromptBtnNo;
  String get attrezzaturaPromptBtnYes;
  String get attrezzaturaPromptSuccess;
  String attrezzaturaPromptError(String e);

  // ── Manutenzione form ─────────────────────────────────────────────────────
  String get manutenzioneFormTitle;
  String get manutenzioneFormLblAttrezzatura;
  String get manutenzioneFormLblTipo;
  String get manutenzioneFormHintDescrizione;
  String get manutenzioneFormValidateDescrizione;
  String get manutenzioneFormLblDataProgrammata;
  String get manutenzioneFormHintSelezionaData;
  String get manutenzioneFormLblDataEsecuzione;
  String get manutenzioneFormLblDataEsecuzioneReq;
  String get manutenzioneFormLblCosto;
  String get manutenzioneFormHelperCosto;
  String get manutenzioneFormLblEseguitoDa;
  String get manutenzioneFormHintEseguitoDa;
  String get manutenzioneFormLblProssimaManutenzione;
  String get manutenzioneFormHintNonProgrammata;
  String get manutenzioneFormLblNote;
  String get manutenzioneFormInfoPagamento;
  String get manutenzioneFormInfoCondivisa;
  String get manutenzioneFormBtnProgramma;
  String get manutenzioneFormBtnRegistra;
  String get manutenzioneFormCreatedOk;
  String get manutenzioneFormValidateDataProgrammata;
  String get manutenzioneFormValidateDataEsecuzione;
  // Tipo manutenzione labels
  String get manutenzioneFormTipoOrdinaria;
  String get manutenzioneFormTipoStraordinaria;
  String get manutenzioneFormTipoRiparazione;
  String get manutenzioneFormTipoPulizia;
  String get manutenzioneFormTipoRevisione;
  String get manutenzioneFormTipoSostituzioneParti;
  // Stato manutenzione labels
  String get manutenzioneFormStatoProgrammata;
  String get manutenzioneFormStatoInCorso;
  String get manutenzioneFormStatoCompletata;
  String get manutenzioneFormStatoAnnullata;

  // ── Spesa attrezzatura form ───────────────────────────────────────────────
  String get spesaAttrezzaturaFormTitle;
  String get spesaAttrezzaturaFormLblTipo;
  String get spesaAttrezzaturaFormLblImporto;
  String get spesaAttrezzaturaFormValidateImporto;
  String get spesaAttrezzaturaFormLblData;
  String get spesaAttrezzaturaFormLblFornitore;
  String get spesaAttrezzaturaFormHintFornitore;
  String get spesaAttrezzaturaFormLblNumFattura;
  String get spesaAttrezzaturaFormHintNumFattura;
  String get spesaAttrezzaturaFormInfoPagamento;
  String get spesaAttrezzaturaFormInfoCondivisa;
  String get spesaAttrezzaturaFormBtnSave;
  String get spesaAttrezzaturaFormCreatedOk;
  // Tipo spesa labels
  String get spesaAttrezzaturaFormTipoAcquisto;
  String get spesaAttrezzaturaFormTipoManutenzione;
  String get spesaAttrezzaturaFormTipoRiparazione;
  String get spesaAttrezzaturaFormTipoAccessori;
  String get spesaAttrezzaturaFormTipoConsumabili;
  String get spesaAttrezzaturaFormTipoAltro;

  // ── Vendita form / detail ─────────────────────────────────────────────────
  String get venditaFormTitleNew;
  String get venditaFormTitleEdit;
  String get venditaFormLblAcquirente;
  String get venditaFormBtnUsaClienteReg;
  String get venditaFormBtnNomeLibero;
  String get venditaFormLblClienteReg;
  String get venditaFormHintNessuno;
  String get venditaFormLblAcquirenteNome;
  String get venditaFormValidateNome;
  String get venditaFormValidateAcquirente;
  String get venditaFormLblData;
  String get venditaFormSectionCanale;
  String get venditaFormSectionPagamento;
  String get venditaFormSectionArticoli;
  String get venditaFormBtnAddArticolo;
  String venditaFormTotale(String amount);
  String get venditaFormLblCondividi;
  String get venditaFormHintSoloPersonale;
  String get venditaFormCreatedOk;
  String get venditaFormUpdatedOk;
  String venditaFormArticoloLabel(int n);
  String get venditaFormLblTipoMiele;
  String get venditaFormValidateRequired;
  String get venditaFormLblFormatoVasetto;
  String get venditaFormLblQty;
  String get venditaFormLblPrezzo;
  String venditaFormSubtotale(String amount);
  // Canale options
  String get venditaCanaleMercatino;
  String get venditaCanaleNegozio;
  String get venditaCanalePrivato;
  String get venditaCanaleOnline;
  String get venditaCanaleAltro;
  // Pagamento options
  String get venditaPagamentoContanti;
  String get venditaPagamentoBonifico;
  String get venditaPagamentoCarta;
  String get venditaPagamentoAltro;
  // Categoria labels
  String get venditaCatMiele;
  String get venditaCatPropoli;
  String get venditaCatCera;
  String get venditaCatPolline;
  String get venditaCatPappaReale;
  String get venditaCatNucleo;
  String get venditaCatRegina;
  String get venditaCatAltro;
  // Detail
  String get venditaDetailTitle;
  String get venditaDetailNotFound;
  String get venditaDetailOfflineMsg;
  String get venditaDetailDeleteTitle;
  String get venditaDetailDeleteMsg;
  String get venditaDetailDeletedOk;
  String get venditaDetailLblData;
  String get venditaDetailLblAcquirente;
  String get venditaDetailLblCanale;
  String get venditaDetailLblPagamento;
  String get venditaDetailSectionArticoli;

  // ── Cliente form ──────────────────────────────────────────────────────────
  String get clienteFormTitleNew;
  String get clienteFormTitleEdit;
  String get clienteFormDeleteTitle;
  String get clienteFormDeleteMsg;
  String get clienteFormDeletedOk;
  String get clienteFormLblNome;
  String get clienteFormLblTelefono;
  String get clienteFormLblEmail;
  String get clienteFormLblIndirizzo;
  String get clienteFormLblNote;
  String get clienteFormLblCondividi;
  String get clienteFormHintSoloPersonale;
  String get clienteFormBtnCreate;
  String get clienteFormBtnUpdate;
  String get clienteFormCreatedOk;
  String get clienteFormUpdatedOk;

  // ── Gruppo form ───────────────────────────────────────────────────────────
  String get gruppoFormTitleNew;
  String get gruppoFormTitleEdit;
  String get gruppoFormCreatedOk;
  String get gruppoFormUpdatedOk;
  String get gruppoFormSectionInfo;
  String get gruppoFormSubtitleNew;
  String get gruppoFormSubtitleEdit;
  String get gruppoFormLblNome;
  String get gruppoFormHintNome;
  String get gruppoFormHintDescrizione;
  String get gruppoFormBtnCrea;
  String get gruppoFormBtnSalva;

  // ── Gruppo invito screen ──────────────────────────────────────────────────
  String get gruppoInvitoTitle;
  String get gruppoInvitoNotFound;
  String gruppoInvitoHeader(String nome);
  String get gruppoInvitoSubtitle;
  String get gruppoInvitoLblEmail;
  String get gruppoInvitoHintEmail;
  String get gruppoInvitoLblRuolo;
  String get gruppoInvitoRuoloAdmin;
  String get gruppoInvitoRuoloAdminDesc;
  String get gruppoInvitoRuoloEditor;
  String get gruppoInvitoRuoloEditorDesc;
  String get gruppoInvitoRuoloViewer;
  String get gruppoInvitoRuoloViewerDesc;
  String get gruppoInvitoBtnSend;
  String get gruppoInvitoInfo;
  String get gruppoInvitoSentOk;

  // ── Gruppo detail screen ──────────────────────────────────────────────────
  String get gruppoDetailDefaultTitle;
  String get gruppoDetailNotFound;
  String get gruppoDetailTabMembri;
  String get gruppoDetailTabApiari;
  String get gruppoDetailTabInviti;
  String get gruppoDetailTooltipInvita;
  String get gruppoDetailTooltipModifica;
  String get gruppoDetailBtnElimina;
  String get gruppoDetailBtnLascia;
  String get gruppoDetailNoMembri;
  String get gruppoDetailRuoloAdmin;
  String get gruppoDetailRuoloEditor;
  String get gruppoDetailRuoloViewer;
  String get gruppoDetailRuoloCreatore;
  String get gruppoDetailCambiaRuoloTitle;
  String get gruppoDetailRuoloAdminDesc;
  String get gruppoDetailRuoloEditorDesc;
  String get gruppoDetailRuoloViewerDesc;
  String get gruppoDetailRuoloUpdated;
  String get gruppoDetailRimuoviTitle;
  String gruppoDetailRimuoviMsg(String username);
  String get gruppoDetailRimuoviBtnConfirm;
  String gruppoDetailRimosso(String username);
  String get gruppoDetailEliminaTitle;
  String get gruppoDetailEliminaMsg;
  String get gruppoDetailEliminato;
  String get gruppoDetailLasciaTitle;
  String gruppoDetailLasciaMsg(String nome);
  String get gruppoDetailLasciaBtnConfirm;
  String get gruppoDetailLasciato;
  String get gruppoDetailNoApiariCondivisi;
  String get gruppoDetailNoInviti;
  String get gruppoDetailBtnInvitaMembro;
  String get gruppoDetailInvitoRuoloLbl;
  String get gruppoDetailInvitoScadeLbl;
  String get gruppoDetailTooltipAnnullaInvito;
  String get gruppoDetailAnnullaInvitoTitle;
  String gruppoDetailAnnullaInvitoMsg(String email);
  String get gruppoDetailAnnullaBtnConfirm;
  String get gruppoDetailInvitoAnnullato;
  String get gruppoDetailApiarioProprietario;
  String get gruppoDetailApiarioNoPos;
  String get gruppoDetailImpossibileTrovareProf;
  String get gruppoDetailImmagineAggiornata;
  String get gruppoDetailDataLoadError;
  String get gruppoDetailPopupCambiaRuolo;
  String get gruppoDetailPopupRimuovi;
  String get gruppoDetailMembroNonValido;

  // ── Cantina screen ──
  String get cantinaTitle;
  String get cantinaBtnNuovoMaturatore;
  String get cantinaInMaturazione;
  String get cantinaStoccati;
  String get cantinaVasetti;
  String get cantinaSectionMaturatori;
  String cantinaAttiviLabel(int n);
  String get cantinaNoMaturatori;
  String get cantinaSectionStoccaggio;
  String cantinaContenitoriLabel(int n);
  String get cantinaNoContenitori;
  String get cantinaSectionInvasettato;
  String cantinaVasettiLabel(int n);
  String get cantinaNoVasetti;
  String cantinaDeleteMaturatoreMsg(String nome);
  String cantinaDeleteContenitoreMsg(String nome);
  String get cantinaVenditaErrVasetti;

  // ── Aggiungi maturatore sheet ──
  String get aggiungiMaturatoreTitleNew;
  String get aggiungiMaturatoreTitleEdit;
  String get aggiungiMaturatoreHintNome;
  String get aggiungiMaturatoreLblTipoMiele;
  String get aggiungiMaturatoreLblCapacita;
  String get aggiungiMaturatoreLblKgAttuali;
  String get aggiungiMaturatoreLblGiorniMaturazione;
  String get aggiungiMaturatoreHelperGiorni;
  String get aggiungiMaturatoreLblDataInizio;

  // ── Trasferisci sheet ──
  String trasferisciTitle(String nome);
  String trasferisciErrSupera(String tot, String disp);
  String get trasferisciNoContenitori;
  String get trasferisciBtnAggiungiContenitore;
  String get trasferisciBtnConferma;
  String get trasferisciLblTipo;
  String get trasferisciLblKg;
  String trasferisciKgAssegnati(String tot, String disp);
  String trasferisciKgDisponibili(String n);

  // ── Invasetta sheet ──
  String invasettaTitle(String nome);
  String get invasettaLblFormato;
  String get invasettaLblNumeroVasetti;
  String get invasettaBtnMax;
  String invasettaKgUsati(int n, int formato, String kg);
  String invasettaRimangono(String kg);
  String get invasettaLblLotto;
  String invasettaBtnConferma(int n);

  // ── Maturatore card ──
  String get maturatoreCardBtnTrasferisci;
  String get maturatoreCardProntoOggi;
  String maturatoreCardProntoTra(int n);
  String get maturatoreCardBtnTrasferisciOra;
  String get maturatoreCardStatoPronto;

  // ── Contenitore card ──
  String get contenitoreCardBtnInvasetta;

  // ── Lotto vasetti section ──
  String lottoVasettiCount(int n);
  String lottoVasettiDisponibili(int n);
  String lottoVasettiiBtnVendi(int n);

  // ── Controllo form ──
  String get controlloFormTitleNew;
  String get controlloFormTitleEdit;
  String get controlloFormTitleLoading;
  String controlloFormArniaLabel(int numero);
  String controlloFormNucleoLabel(int numero);
  String get controlloFormBtnSalva;
  String get controlloFormBtnAggiorna;
  String get controlloFormSectionData;
  String get controlloFormLblData;
  String get controlloFormSectionTelaini;
  String get controlloFormTelainiCovata;
  String get controlloFormTelainiScorte;
  String get controlloFormTelainiFoglioCereo;
  String get controlloFormTelainiDiaframma;
  String get controlloFormTelainiNutritore;
  String get controlloFormTelainiVuoto;
  String get controlloFormAutoOrdina;
  String get controlloFormPreCaricato;
  String get controlloFormToccaTelaino;
  String get controlloFormSectionRegina;
  String get controlloFormLblStatoRegina;
  String get controlloFormReginaAssente;
  String get controlloFormReginaPresente;
  String get controlloFormReginaVista;
  String get controlloFormUovaFresche;
  String get controlloFormUovaFrescheDesc;
  String get controlloFormCelleReali;
  String get controlloFormCelleRealiDesc;
  String get controlloFormLblNumeroCelleReali;
  String get controlloFormReginaSostituita;
  String get controlloFormReginaSostituitaDesc;
  String get controlloFormReginaColorata;
  String get controlloFormReginaColorataDesc;
  String get controlloFormColoreRegina;
  String get controlloFormSectionSciamatura;
  String get controlloFormSciamatura;
  String get controlloFormSciamaturaCodice;
  String get controlloFormNoteSciamatura;
  String get controlloFormSectionProblemi;
  String get controlloFormProblemi;
  String get controlloFormProblemiDesc;
  String get controlloFormDettagliProblemi;
  String get controlloFormValidateProblemi;
  String get controlloFormSectionNote;
  String get controlloFormLblNote;
  String get controlloFormHintNote;
  String get controlloFormOfflineMsg;
  String get controlloFormSavedOk;
  String get controlloFormSavedOffline;
  String get controlloFormUpdatedOk;
  String get controlloFormUpdatedOffline;
  String get controlloFormErrGeneric;
  String get controlloFormErrCaricoArnia;
  String get controlloFormSyncOk;
  String get controlloFormReginaAutoCreata;
  String controlloFormLastControllo(String data);
  String controlloFormReginaLabel(String stato);
  String controlloFormCovataCount(int n);
  String controlloFormScorteCount(int n);
  String controlloFormDiaframmaCount(int n);
  String controlloFormFoglioCereoCount(int n);

  // ── Pagamenti screen ──
  String get pagamentiTitle;
  String get pagamentiTabPagamenti;
  String get pagamentiTabBilancio;
  String get pagamentiTooltipSync;
  String get pagamentiTooltipNuovoPagamento;
  String pagamentiErrLoading(String e);
  String get pagamentiEmptyTitle;
  String get pagamentiRegistraPagamento;
  String get pagamentiLinkRapidi;
  String get pagamentiLinkAttrezzature;
  String get pagamentiAttrezzatureHint;
  String get pagamentiTooltipSaldo;
  String get pagamentiTooltipAttrezzatura;
  String get pagamentiBilancioEmptyTitle;
  String get pagamentiBilancioEmptyHint;
  String pagamentiBilancioTotale(String amount);
  String get pagamentiTooltipGestisci;
  String get pagamentiQuoteLabel;
  String get pagamentiTrasferimentiNecessari;
  String get pagamentiQuoteGruppo;
  String get pagamentiGestisci;
  String get pagamentoPagato;
  String get pagamentoDovuto;
  String get pagamentoSaldo;
  String get pagamentiTooltipRegistraSaldo;
  String pagamentiSaldoDesc(String da, String a);
  String pagamentiBilancioWarnSommaQuote(String sum);
  String get pagamentiBilancioWarnMembriSenzaQuota;

  // ── Pagamento detail screen ──
  String get pagamentoDetailTitle;
  String get pagamentoDetailNotFound;
  String pagamentoDetailErrLoading(String e);
  String get pagamentoDetailDeleteMsg;
  String get pagamentoDetailDeletedOk;
  String get pagamentoDetailErrDelete;
  String get pagamentoDetailLabelDescrizione;
  String get pagamentoDetailLabelUtente;
  String get pagamentoDetailLabelGruppo;

  // ── Pagamento form screen ──
  String get pagamentoFormTitleNew;
  String get pagamentoFormTitleEdit;
  String get pagamentoFormUpdatedOk;
  String get pagamentoFormCreatedOk;
  String pagamentoFormErrSave(String e);
  String get pagamentoFormLabelImporto;
  String get pagamentoFormValidImportoRequired;
  String get pagamentoFormValidImportoInvalid;
  String get pagamentoFormValidImportoPositivo;
  String get pagamentoFormValidDescRequired;
  String get pagamentoFormValidDestinatarioDiverso;
  String get pagamentoFormErrAuth;
  String get pagamentoFormLabelGruppo;
  String get pagamentoFormNoGruppo;
  String get pagamentoFormLabelChiPaga;
  String get pagamentoFormIoStesso;
  String get pagamentoFormHelperChiPaga;
  String get pagamentoFormSaldoTitle;
  String get pagamentoFormSaldoSubtitle;
  String get pagamentoFormLabelDestinatario;
  String get pagamentoFormHelperDestinatario;
  String get pagamentoFormValidDestinatarioRequired;

  // ── Quote screen ──
  String get quoteTitle;
  String quoteErrLoading(String e);
  String get quoteUpdatedOk;
  String quoteErrUpdate(String e);
  String get quoteEditTitle;
  String quoteEditMsg(String username);
  String get quoteLabelPercentuale;
  String get quoteValidPercRequired;
  String get quoteValidPercInvalid;
  String get quoteDeleteMsg;
  String get quoteDeletedOk;
  String get quoteErrDelete;
  String quoteErrDeleteE(String e);
  String get quoteAddNoGruppo;
  String get quoteAddedOk;
  String quoteErrAdd(String e);
  String get quoteAddTitle;
  String get quoteLabelIdUtente;
  String get quoteValidIdRequired;
  String get quoteValidIdInvalid;
  String get quoteValidPercRange;
  String get quoteAddLabelUtente;
  String get quoteValidUtenteRequired;
  String get quoteAddNoMembriDisponibili;
  String quoteAddErrCaricamentoMembri(String e);
  String quoteValidSommaSupera100(String sum);
  String quoteConfirmSommaNon100Title(String sum);
  String get quoteConfirmSommaNon100Msg;
  String get quoteConfirmSommaNon100Continue;
  String get quoteLabelFiltroGruppo;
  String get quoteTuttiGruppi;
  String get quoteTooltipAdd;
  String get quoteEmptyTitle;

  // ── Statistiche screen ──
  String get statisticheTitle;
  String get statisticheTabDashboard;
  String get statisticheTabAnalisi;
  String get statisticheTabChiediAI;

  // ── Dashboard card base ──
  String get dashboardErrCaricamento;

  // ── Dashboard widget titles ──
  String get dashboardTitleProduzione;
  String get dashboardTitleSaluteArnie;
  String get dashboardTitleRegineStats;
  String get dashboardTitleFrequenzaControlli;
  String get dashboardTitleFioritureVicine;
  String get dashboardTitleAttrezzature;
  String get dashboardTitleProduzionePerTipo;
  String get dashboardTitleTrattamenti;
  String get dashboardTitleAndamentoScorte;
  String get dashboardTitleAndamentoCovata;
  String get dashboardTitlePerformanceRegine;
  String get dashboardTitleQuoteGruppo;
  String dashboardTitleBilancio(int anno);

  // ── Salute arnie widget ──
  String get dashboardSaluteNoArnie;
  String get dashboardSaluteOttima;
  String get dashboardSaluteAttenzione;
  String get dashboardSaluteCritica;
  String dashboardSaluteTotale(int n);
  String dashboardSaluteCritiche(String list);
  String get dashboardSaluteInfoTitle;
  String get dashboardSaluteInfoIntro;
  String get dashboardSaluteInfoOttima;
  String get dashboardSaluteInfoAttenzione;
  String get dashboardSaluteInfoCritica;
  String get dashboardSaluteInfoSuggerimento;
  String get dashboardSaluteListaVuota;
  String dashboardSaluteListaTitolo(String stato);
  String get dashboardSaluteApiarioPrefisso;

  // ── Regine statistiche widget ──
  String get dashboardRegineAttive;
  String get dashboardRegineSostituzioni;
  String get dashboardRegineVitaMedia;
  String dashboardRegineVitaMesiStr(String durata);
  String get dashboardRegineMotiviSostituzione;

  // ── Performance regine widget ──
  String get dashboardPerformanceNoRegine;
  String get dashboardPerformanceHdrRegina;
  String get dashboardPerformanceHdrProd;
  String get dashboardPerformanceHdrDoc;
  String get dashboardPerformanceHdrResist;
  String get dashboardPerformanceHdrSc;

  // ── Bilancio widget ──
  String get dashboardBilancioSaldoAnnuale;
  String get dashboardBilancioEntrate;
  String get dashboardBilancioUscite;

  // ── Frequenza controlli widget ──
  String get dashboardFrequenzaMedia;
  String dashboardFrequenzaGiorni(int n);
  String get dashboardFrequenzaDettaglio;

  // ── Fioriture vicine widget ──
  String get dashboardFioritureNessuna;
  String get dashboardFioritureFiltroTutti;

  // ── Attrezzature widget ──
  String get dashboardAttrezzatureNessuna;
  String get dashboardAttrezzatureCategoria;
  String get dashboardAttrezzatureNumero;
  String get dashboardAttrezzatureValore;
  String get dashboardAttrezzatureInventario;

  // ── Varroa trend widget ──
  String get dashboardVarroaNessuno;

  // ── Andamento scorte widget ──
  String get dashboardScorteNessuno;

  // ── Andamento covata widget ──
  String get dashboardCovataNessuno;

  // ── Produzione tipo widget ──
  String get dashboardProdTipoNessuno;
  String dashboardProdTipoTotale(String kg);

  // ── Quote gruppo widget ──
  String get dashboardQuoteGruppoSoloCoord;
  String get dashboardQuoteGruppoNessunaSpesa;
  String get dashboardQuoteGruppoQuoteIncomplete;
  String get dashboardQuoteGruppoLabelDovuto;
  String get dashboardQuoteGruppoLabelPagato;
  String get dashboardQuoteGruppoLabelSpeso;
  String get dashboardQuoteGruppoLabelCopertura;
  String get dashboardQuoteGruppoSelezionaGruppo;

  // ── NL Query tab ──
  String get nlQuerySuggerite;
  String get nlQuerySuggerimento1;
  String get nlQuerySuggerimento2;
  String get nlQuerySuggerimento3;
  String get nlQuerySuggerimento4;
  String get nlQuerySuggerimento5;
  String get nlQuerySuggerimento6;
  String get nlQueryPensando;
  String get nlQueryRispostaAI;
  String nlQueryRisultati(int n);
  String get nlQueryErrLento;
  String get nlQueryErrRifiuto;
  String get nlQueryErrGenerico;
  String get nlQueryErrSessione;
  String get nlQueryErrServizio;
  String get nlQueryInputHint;

  // ── Risultato query widget ──
  String nlQueryRighe(int n);
  String get risultatoNessunDato;
  String get risultatoNessunRisultato;

  // ── Export bottom sheet ──
  String get exportTitle;
  String get exportExcel;
  String get exportPdf;
  String get exportExcelSalvato;
  String exportErrExcel(String e);
  String get exportPdfSalvato;
  String exportErrPdf(String e);

  // ── Query builder tab ──
  String get queryBuilderEseguiAnalisi;
  String get queryBuilderAvanti;
  String get queryBuilderIndietro;
  String get queryBuilderStepAnalizzare;
  String get queryBuilderStepFiltri;
  String get queryBuilderStepRisultati;
  String get queryBuilderEntitaControlli;
  String get queryBuilderEntitaSmielature;
  String get queryBuilderEntitaRegine;
  String get queryBuilderEntitaVendite;
  String get queryBuilderEntitaSpese;
  String get queryBuilderEntitaFioriture;
  String get queryBuilderEntitaArnie;
  String get queryBuilderDataDa;
  String get queryBuilderDataA;
  String get queryBuilderAggregazione;
  String get queryBuilderAggCount;
  String get queryBuilderAggSum;
  String get queryBuilderAggAvg;
  String get queryBuilderAggNone;
  String get queryBuilderRaggruppaPer;
  String get queryBuilderRaggruppaMese;
  String get queryBuilderRagruppaAnno;
  String queryBuilderErrore(String e);
  String get queryBuilderRunFirst;
  String get queryBuilderVizBarre;
  String get queryBuilderVizLinea;
  String get queryBuilderVizTabella;

  // ── Voice transcript review screen ──
  String voiceReviewTitleCount(int n);
  String get voiceReviewBtnDeleteAll;
  String get voiceReviewDeleteAllTitle;
  String get voiceReviewDeleteAllMsg;
  String get voiceReviewDeleteItemTitle;
  String get voiceReviewInfoBanner;
  String get voiceReviewEmpty;
  String get voiceReviewEmptyHint;
  String get voiceReviewBtnKeepQueue;
  String get voiceReviewBtnSendAI;
  String get voiceReviewProcessing;
  String get voiceReviewMerging;
  String get voiceReviewMergeWith;
  String get voiceReviewTooltipEdit;
  String get voiceReviewTooltipSave;
  String get voiceReviewTooltipDelete;

  // ── Voice entry verification screen ──
  String get voiceVerifTitle;
  String get voiceVerifTooltipRemove;
  String get voiceVerifSaving;
  String get voiceVerifDeleteTitle;
  String voiceVerifDeleteMsg(String label);
  String get voiceVerifScheda;
  String get voiceVerifNewArnieTitolo;
  String voiceVerifNewArnieMsg(String list);
  String get voiceVerifCreateSave;
  String get voiceVerifErrCreazArnieTitolo;
  String voiceVerifSavedOk(int n);
  String voiceVerifPartialSaved(int saved, int remaining);
  String get voiceVerifNoSaved;
  String voiceVerifInvalidSkipped(String arnia);
  String voiceVerifNotFoundCache(String arnia);
  String get voiceVerifEmptyTitle;
  String get voiceVerifEmptySubtitle;
  String get voiceVerifBtnGoBack;
  String voiceVerifRecordOf(int current, int total);
  String get voiceVerifSectionPosizione;
  String get voiceVerifSectionRegistrazione;
  String get voiceVerifAudioLabel;
  String get voiceVerifSectionGenerali;
  String get voiceVerifLblTipo;
  String get voiceVerifSectionRegina;
  String get voiceVerifSectionTelaini;
  String get voiceVerifLblTotale;
  String get voiceVerifLblForzaFamiglia;
  String get voiceVerifSectionProblemi;
  String get voiceVerifLblProblemiSanitari;
  String get voiceVerifLblTipoProblema;
  String get voiceVerifSectionColorazione;
  String get voiceVerifLblReginaColorata;
  String get voiceVerifLblColoreRegina;
  String get voiceVerifSectionNote;
  String get voiceVerifLblNoteAggiuntive;
  String get voiceVerifTooltipPrecedente;
  String get voiceVerifTooltipSuccessivo;
  String get voiceVerifBtnSaveAll;
  String get voiceVerifTooltipPausa;
  String get voiceVerifTooltipRiproduci;
  String get voiceVerifTooltipStop;
  String get trattamentoTitle;
  String get trattamentoFormNomeProdotto;
  String get voiceVerifInfoCreazioneArnia;

  // ── Voice command screen ──
  String get voiceCommandTitle;
  String get voiceCommandTooltipMenu;
  String get voiceCommandTooltipQueue;
  String get voiceCommandTooltipHideGuide;
  String get voiceCommandTooltipShowTutorial;
  String voiceCommandDraftRestored(int n);
  String get voiceCommandUnsavedTitle;
  String voiceCommandUnsavedMsg(int n);
  String get voiceCommandBtnScarta;
  String get voiceCommandBtnRiprendi;
  String voiceCommandRecoveredSaved(int n);
  String get voiceCommandNoTranscription;
  String voiceCommandSavedToQueue(int n);
  String get voiceCommandNoValidEntry;
  String get voiceCommandNoValidData;
  String voiceCommandQueueSaved(int n);
  String voiceCommandSavedWithRemaining(int saved, int remaining);
  String voiceCommandSavedOk(int n);
  String get voiceCommandBtnSaveLater;
  String get voiceCommandGuideTitle;
  String get voiceCommandGuideStep1Title;
  String get voiceCommandGuideStep1Desc;
  String get voiceCommandGuideStep2Title;
  String get voiceCommandGuideStep2Desc;
  String get voiceCommandGuideStep3Title;
  String get voiceCommandGuideStep3Desc;
  String get voiceCommandGuideOffline;
  String get voiceCommandGuideExamplesTitle;
  String get voiceCommandGuideKeywordsTitle;
  String get voiceCommandGuideKeyNextCmd;
  String get voiceCommandGuideKeyStopCmd;

  // ── Voice tutorial sheet ──
  String get voiceTutorialTitle;
  String get voiceTutorialSubtitle;
  String get voiceTutorialStep1Title;
  String get voiceTutorialStep1Body;
  String get voiceTutorialStep2Title;
  String get voiceTutorialStep2Body;
  String get voiceTutorialStep2BodyStt;
  String get voiceTutorialStep2BodyAudio;
  String get voiceTutorialStep3Title;
  String get voiceTutorialStep3TitleStt;
  String get voiceTutorialStep3TitleAudio;
  String get voiceTutorialStep3Body;
  String get voiceTutorialStep3BodyStt;
  String get voiceTutorialStep3BodyAudio;
  String get voiceTutorialStep4Title;
  String get voiceTutorialStep4Body;
  String get voiceTutorialExamplesTitle;
  String get voiceTutorialMultiTitle;
  String get voiceTutorialMultiNextKeyword;
  String get voiceTutorialMultiNextDesc;
  String get voiceTutorialMultiStopKeyword;
  String get voiceTutorialMultiStopDesc;
  String get voiceTutorialOfflineMsg;
  String get voiceTutorialOfflineMsgStt;
  String get voiceTutorialOfflineMsgAudio;
  String get voiceTutorialBtnStart;

  // ── Common shared ──
  String get btnClose;

  // ── Settings screen (remaining) ──
  String get settingsPhotoUpdated;
  String get settingsPhotoError;

  // ── Chat screen ──
  String get chatTooltipClear;
  String get chatClearTitle;
  String get chatClearMsg;
  String get chatClearBtn;
  String get chatInfoBanner;
  String get chatEmpty;
  String get chatLoading;
  String chatErrMsg(String e);
  String get chatRetrySnackbar;
  String get chatHint;
  String get chatGeneratingChart;
  String get chatQuotaUpgradeHint;
  String get chatQuotaInputDisabled;

  // ── AI quota gating (condiviso) ──
  String get quotaVoiceExhaustedTitle;
  String quotaRetryInWithUpgrade(String duration);
  String get quotaRetryAfterReset;
  String get quotaStatsExhausted;
  String get nlQueryInputHintExhausted;
  String get voiceQueuePreflightTitle;
  String voiceQueuePreflightMessage(int available, int total);
  String get voiceQueuePreflightProceed;
  String get voiceQueuePreflightCancel;
  String get voiceQueuePreflightExhausted;

  // ── AI Tier ──
  String get aiTierLabel;
  String get aiTierUpgrade;
  String get aiTierUpgradeComingSoon;
  String get aiTierTotal;
  String get aiTierFreeDesc;
  String get aiTierApicoltoreDesc;
  String get aiTierProfessionaleDesc;

  // ── AI Tier upgrade screen ──
  String get aiUpgradeTitle;
  String get aiUpgradeSubtitle;
  String get aiUpgradeCurrentPlan;
  String get aiUpgradeChatPerDay;
  String get aiUpgradeVoicePerDay;
  String get aiUpgradeTotalPerDay;
  String get aiUpgradeFeatureAdvanced;
  String get aiUpgradeContactUs;
  String get aiUpgradeContactEmail;
  String get aiUpgradeContactSent;
  String get aiUpgradeFreeNote;
  String get aiUpgradeApicoltoreNote;
  String get aiUpgradeProfessionaleNote;
  String get aiUpgradeMostPopular;
  String get aiUpgradeDowngradeNote;
  String get chatQuotaPreCheckError;
  String get chatQuotaResetNotice;

  // ── Subscription / Paywall ──────────────────────────────────────────────
  String get subPaywallTitle;
  String get subPaywallSubtitle;
  String get subMonthly;
  String get subYearly;
  String get subYearlySave;
  String get subRestore;
  String get subRestoreSuccess;
  String get subRestoreNone;
  String get subRestoreError;
  String get subPurchaseSuccess;
  String get subPurchaseError;
  String get subManage;
  String get subCurrentPlan;
  String get subFreeDesc;
  String get subProMonthlyDesc;
  String get subProYearlyDesc;
  String get subFeatureUnlimitedChat;
  String get subFeatureVoice;
  String get subFeatureAdvancedAI;
  String get subCostExplanation;
  String get subLoading;
  String get subNoProducts;
  String subPricePerMonth(String price);
  String subPricePerYear(String price);
  String subSavePercent(int percent);
  String get subFreeTrial;
  String subFreeTrialDays(int days);
  String get subThenPrice;
  String get subBestValue;
  String get subMostPopular;
  String get subSubscribe;
  String get subPerMonth;
  String get subPerYear;
  String get subChoosePlan;
  String get subTermsNotice;
  String subPackageDuration(String type);
  String get subComingSoon;
  String get subComingSoonDesc;
  String get subActivateCode;
  String get subActivateCodeHint;
  String get subActivateBtn;
  String get subActivateSuccess;
  String get subActivateError;
  String get subActivateInvalid;
  String get subActivating;

  // ── Analisi telaino list screen ──
  String get analisiListTitle;
  String get analisiListTooltipNew;
  String get analisiListEmpty;
  String get analisiListBtnStart;
  String analisiListCardTitle(int n, String side);
  String analisiListTagApi(int n);
  String analisiListTagRegine(int n);
  String analisiListTagFuchi(int n);
  String analisiListTagCelleR(int n);

  // ── Analisi telaino screen ──
  String get analisiTitle;
  String analisiErrAnalysis(String e);
  String get analisiSnackSaved;
  String analisiErrSave(String e);
  String get analisiConfigTitle;
  String get analisiLoadingControllo;
  String analisiSlotSource(String date, int count);
  String get analisiNoSlot;
  String get analisiFacciata;
  String analisiTelainoN(int n);
  String get analisiSelectTelaino;
  String get analisiTelainoLabel;
  String get analisiAnalyzing;
  String analisiProgressLabel(int n, String label);
  String analisiSummaryTitle(int n, String side);
  String get analisiCountApi;
  String get analisiCountRegine;
  String get analisiCountFuchi;
  String get analisiCountCelleReali;
  String get analisiConfidenzaMedia;
  String get analisiNoteLbl;
  String get analisiNoteHint;
  String get analisiBtnRipeti;
  String get analisiBtnSalva;
  String get analisiBtnScattaFoto;
  String get analisiBtnGalleria;
  String get analisiDiagnostica;
  String analisiIdentityBadge(int n, String label);
  String analisiIdentityDate(String date);
  // warnings
  String analisiWarnDiafammaApi(int n);
  String get analisiWarnDiafammaRegina;
  String analisiWarnDiafammaCelle(int n);
  String analisiWarnDiafammaFuchi(int n);
  String get analisiWarnNutritoreRegina;
  String analisiWarnNutritoreCelle(int n);
  String analisiWarnNutritoreApi(int n);
  String analisiWarnCovataSciamaturaAlta(int n);
  String analisiWarnCovataSciamaturaMedia(int n);
  String analisiWarnCovataRegine(int n);
  String get analisiWarnCovataVuota;
  String analisiWarnCovataFuchi(int n);
  String analisiWarnScorteRegina(int n);
  String analisiWarnScorteCelle(int n);
  String analisiWarnScorteApi(int n);
  String analisiWarnDensitaAltissima(int n);

  // ── Mappa screen ──
  String get mappaTitle;
  String get mappaOfflineTooltip;
  String get mappaTooltipOsmHide;
  String get mappaTooltipOsmShow;
  String get mappaTooltipRaggioHide;
  String get mappaTooltipRaggioShow;
  String get mappaTooltipNomadismo;
  String get mappaTooltipSync;
  String get mappaErrPermission;
  String get mappaErrPermissionPermanent;
  String get mappaSnackSettings;
  String get mappaErrServiceDisabled;
  String get mappaSnackActivate;
  String get mappaErrPosition;
  String get mappaSnackNord;
  String mappaErrData(String e);
  String get mappaSnackZoom;
  String get mappaErrOsm;
  String get mappaStatArnie;
  String get mappaStatApicoltore;
  String get mappaStatTipo;
  String get mappaStatCommunity;
  String get mappaStatTuoGruppo;
  String get mappaApprox;
  String get mappaBtnVisualizza;
  String get mappaBtnApriApiario;
  String get mappaLegenda;
  String get mappaLegendaMioApiario;
  String get mappaLegendaCommunity;
  String get mappaLegendaGruppo;
  String get mappaLegendaRaggio;
  String get mappaLegendaFiorituraAttiva;
  String get mappaLegendaFiorituraInattiva;
  String get mappaLegendaBosco;
  String get mappaLegendaMacchia;
  String get mappaLegendaPrato;
  String get mappaLegendaFrutteto;
  String get mappaLegendaColtura;
  String get mappaLegendaPosizione;
  String get mappaTooltipNord;
  String get mappaTooltipFioritura;
  String get mappaTooltipPosizione;
  String get mappaFiorApiario;
  String get mappaFiorPeriodo;
  String get mappaFiorRaggio;
  String get mappaFiorNote;
  String get mappaFiorConferme;
  String mappaFiorMetri(int n);
  String mappaFiorConferN(int n);
  String mappaFiorConferNI(int n, String avg);
  String mappaFiorDalAl(String start, String end);
  String mappaFiorDal(String start);
  String get mappaFiorDettaglio;
  String get mappaApiario;

  // ── Nomadismo screen ──
  String get nomadismoTitle;
  String get nomadismoLegendaDensita;
  String get nomadismoLegendaApiario;
  String get nomadismoLegendaAreaAnalisi;
  String get nomadismoLegendaDati;
  String get nomadismoSoloApiari;
  String get nomadismoBtnTocca;
  String get nomadismoBtnAnalizza;
  String get nomadismoFloraTitle;
  String get nomadismoNessunaSpecie;
  String get nomadismoAltrePiante;
  String get nomadismoGbifFooter;
  String nomadismoErrGbif(String e);

  // ── Splash screen ──
  String get splashSubtitle;

  // ── Disclaimer screen ──
  String get disclaimerTitle;
  String get disclaimerBody;
  String get disclaimerDontShow;
  String get disclaimerBtnReject;
  String get disclaimerBtnAccept;

  // ── What's New screen ──
  String get whatsNewBadge;
  String get whatsNewTitle;
  String get whatsNewSubtitle;
  String get whatsNewEmpty;
  String get whatsNewBtnExplore;
  String whatsNewCatLabel(String cat);

  // ── Onboarding screen ──
  String get onboardingSkip;
  String get onboardingBack;
  String get onboardingNext;
  String get onboardingBtnCreate;
  String get onboardingBtnExplore;
  String get onboardingStep1Title;
  String get onboardingStep1Desc;
  String get onboardingStep2Title;
  String get onboardingStep2Desc;
  String get onboardingStep3Title;
  String get onboardingStep3Desc;
  String get onboardingStep4Title;
  String get onboardingStep4F1Title;
  String get onboardingStep4F1Desc;
  String get onboardingStep4F2Title;
  String get onboardingStep4F2Desc;
  String get onboardingStep4F3Title;
  String get onboardingStep4F3Desc;
  String get onboardingStep4F4Title;
  String get onboardingStep4F4Desc;
  String get onboardingStep5Title;
  String get onboardingStep5Desc;

  // ── Donazione screen ──
  String get donazioneTitle;
  String get donazioneErrLink;
  String get donazioneTxOk;
  String donazioneErrEmail(String email);
  String get donazioneHeroSubtitle;
  String get donazioneBtnCoffee;
  String get donazioneCard1Desc;
  String get donazioneCard2Title;
  String get donazioneCard2Desc;
  String get donazioneCard3Title;
  String get donazioneCard3Desc;
  String get donazioneCard4Title;
  String get donazioneCard4Desc;
  String get donazioneFeedbackTitle;
  String get donazioneFeedbackSubtitle;
  String get donazioneLblNome;
  String get donazioneErrNome;
  String get donazioneLblEmail;
  String get donazioneErrEmailInvalid;
  String get donazioneLblMsg;
  String get donazioneErrMsg;
  String get donazioneBtnInvio;
  String get donazioneBtnInvia;

  // ── Guida screen ──
  String get guidaTitle;
  String get guidaSubtitle;
  String get guidaBtnReview;

  // ── Privacy Policy screen ──
  String get privacyTitle;
  String get privacyHeader;
  String get privacyLastUpdated;
  String get privacyIntro;
  String get privacyS1Title;
  String get privacyS1Body;
  String get privacyS2Title;
  String get privacyS2Body;
  String get privacyS2_1Title;
  List<String> get privacyS2_1Bullets;
  String get privacyS2_2Title;
  List<String> get privacyS2_2Bullets;
  String get privacyS2_3Title;
  String get privacyS2_3Body;
  String get privacyS3Title;
  List<String> get privacyS3Bullets;
  String get privacyS4Title;
  List<String> get privacyS4Bullets;
  String get privacyS5Title;
  List<String> get privacyS5Bullets;
  String get privacyS6Title;
  String get privacyS6Body;
  List<String> get privacyS6Bullets;
  String get privacyS7Title;
  String get privacyS7Body;
  List<String> get privacyS7Bullets;
  String get privacyS7Contact;
  String get privacyS7Garante;
  String get privacyS8Title;
  String get privacyS8Body;
  String get privacyS9Title;
  String get privacyS9Body;
  String get privacyS10Title;
  String get privacyS10Body;
  String get privacyS11Title;
  String get privacyS11Body;
  String get privacyCopyright;

  // ── Weather widget ──
  String get weatherErrorNoData;
  String weatherUpdatedAt(String time);
  String weatherFeelsLike(String temp);
  String get weatherHumidity;
  String get weatherWind;
  String get weatherRain;
  String get weatherPressure;
  String get weatherForecast7Days;
  String get weatherToday;
  List<String> get weatherDayNamesShort;

  // ── QR code ──
  String get qrUnsupportedEntity;
  String get qrLabelApiario;
  String get qrLabelUnknown;
  String qrLabelPosition(String position);
  String get qrLabelNotSpecified;
  String get qrBtnCopy;
  String get qrCopiedToClipboard;
  String get qrBtnShare;
  String qrShareText(String title);
  String qrShareError(String error);
  String get qrNavUnsupportedTitle;
  String get qrNavUnsupportedMsg;
  String get qrNavErrorTitle;
  String qrNavErrorMsg(String error);
  String get qrNavArniaNonTrovatoTitle;
  String get qrNavArniaNonTrovatoMsg;
  String get qrNavArniaOfflineTitle;
  String get qrNavArniaOfflineMsg;
  String get qrNavApiarioNonTrovatoTitle;
  String get qrNavApiarioNonTrovatoMsg;
  String get qrNavApiarioOfflineTitle;
  String get qrNavApiarioOfflineMsg;

  // ── Minimap / edit mode ──
  String mapAddTitle(String label);
  String mapAddNumberLabel(String label);
  String get mapLabelColor;
  String get mapBtnAdd;
  String mapNucleoTitle(String num);
  String get mapNucleoLegacyHint;
  String get mapRemoveFromMap;
  String get mapNumberConflictTitle;
  String mapNumberConflictMsg(String current);
  String get mapArniaNumberLabel;
  String get mapSaved;
  String get mapRemoveElementTitle;
  String get mapNoArnie;
  String get mapNoArnieCta;
  String get mapEditModeHint;
  String get mapSelectionHint;
  String mapSelectedCount(int count);
  String get mapLongPressToDelete;
  String get mapLabelArnia;
  String get mapLabelApidea;
  String get mapLabelMiniPlus;
  String get mapLabelPortasciami;
  String get mapLabelAlbero;
  String get mapLabelVialetto;
  String get mapTooltipCenter;
  String get mapSnapOn;
  String get mapSnapOff;
  String get mapBtnSave;
  String get mapBtnDone;
  String get mapLabelInactive;
  String get mapLabelInactiveFem;

  // ── Colony data in arnia detail ──
  String get arniaColoniaVuota;
  String get arniaInsediaColonia;
  String arniaColoniaHeader(int id, String date);
  String arniaColoniaRegina(String razza, String origine);
  String get arniaMenuStoriaColonie;
  String get arniaMenuInsediaNuovaColonia;

  // ── Equipment model display ──
  String get attrezzaturaStatoNonSpecificato;
  String get attrezzaturaCondizioneNonSpecificato;

  // ── Sales banner ──
  List<String> get monthNames;
  String venditeBannerSummary(int count, String total);
  String get venditeCanaleMercatino;
  String get venditeCanaleNegozio;
  String get venditeCanaleOnline;
  String get venditeCanalePravato;
  String get venditeCanaleAltro;

  // ── Voice command examples ──
  String get voiceCommandExample1;
  String get voiceCommandExample2;
  String get voiceCommandExample3;
  String voiceCommandGeminiError(String detail);

  // ── Guide sections ──
  String get guidaSection1Title;
  String get guidaSection2Title;
  String get guidaSection3Title;
  String get guidaSection4Title;
  String get guidaSection5Title;
  String get guidaSection6Title;
  String get guidaSection7Title;
  List<String> get guidaSection1Items;
  List<String> get guidaSection2Items;
  List<String> get guidaSection3Items;
  List<String> get guidaSection4Items;
  List<String> get guidaSection5Items;
  List<String> get guidaSection6Items;
  List<String> get guidaSection7Items;

  // ── AI Chat ──
  String get chatWelcomeMessage;
  String get chatTitle;
  String get chatChartDefaultTitle;

  // ── Hive frame visualizer ──
  String get frameLabelCovata;
  String get frameLabelScorte;
  String get frameLabelFoglioCereo;
  String get frameLabelDiaframma;
  String get frameLabelNutritore;
  String get frameLabelVuoto;
  String get frameNoControllo;
  String get frameReginaPresente;
  String get frameReginaAssente;
  String frameCelleRealiTooltip(int numero, int days);

  // ── Hive type names (dadant, nucleo_polistirolo, …) ──
  String arniaTypeName(String key);

  // ── Audio input widget ──
  String get audioInputStatusRecording;
  String audioInputStatusExtending(String dur);
  String get audioInputStatusProcessing;
  String audioInputStatusProcessingQueue(int cur, int total);
  String get audioInputStatusError;
  String get audioInputStatusSaving;
  String get audioInputStatusIdlePrompt;
  String get audioInputStatusIdleNext;
  String get audioInputStatusIdleSend;
  String get audioInputGeminiProcessing;
  String audioInputQueueProgress(int cur, int total);
  String get audioInputListening;
  String get audioInputListenBeforeSend;
  String get audioInputErrStartMic;
  String get audioInputErrRecInvalid;
  String get audioInputErrExtInvalid;
  String get audioInputErrNoArniaDetected;
  String get audioInputErrNoArniaQueue;
  String get audioInputErrExtract;
  String get audioInputErrUnknown;
  String audioInputRecFailed(int idx, int total, String err);
  String get audioInputSelectArnia;
  String get audioInputChooseArnia;
  String audioInputArniaItem(int n);
  String audioInputBatchHeader(int n);
  String audioInputSessionHeader(int n);
  String audioInputRecordingItem(int n);
  String get audioInputAbandonTitle;
  String get audioInputAbandonMsgSingle;
  String audioInputAbandonMsgMulti(int n);
  String get audioInputBtnBack;
  String get audioInputBtnDeleteAll;
  String get audioInputBtnAddAudioWithNum;
  String get audioInputBtnDiscard;
  String get audioInputBtnRetry;
  String get audioInputBtnSaveQueue;
  String audioInputBtnSendAll(int n);
  String audioInputBtnStopReview(int n);
  String get audioInputBtnAbandon;
  String get audioInputHintPressMicToStart;
  String get audioInputHintRecordNext;

  // ── Voice context banner ──
  String get voiceContextSelect;
  String voiceContextSelected(String name);
  String get voiceContextNoApiari;
  String get voiceContextSheetTitle;
  String get voiceContextSheetHint;
  String get voiceContextSetDefault;
  String get voiceContextRemoveDefault;
  String get voiceContextOffline;

  // ── Controllo form contextual hint ──
  String get controlloFormIntroHint;

  // ── Nomadismo presets (melliferous plants) ──
  String nomadismoPresetNome(String key);
  String nomadismoPresetPeriodo(String key);
  String nomadismoPresetRegioni(String key);
  String nomadismoPresetDesc(String key);
}
