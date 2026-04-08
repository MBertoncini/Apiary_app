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
  String get melariConfirmBtn;
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
  String get smielaturaFormBtnCreate;
  String get smielaturaFormBtnUpdate;
  String get smielaturaFormCreatedOk;
  String get smielaturaFormUpdatedOk;
  // Smielatura detail
  String get smielaturaDetailTitle;
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

  // ── Controllo form ────────────────────────────────────────────────────────
  String get controlloFormDialogTitle;
  String get controlloFormTitleNew;
  String get controlloFormTitleEdit;
  String get controlloFormLblData;
  String get controlloFormBtnAutoOrdina;
  String get controlloFormLblNumCelleReali;
  String get controlloFormLblNoteSciamatura;
  String get controlloFormLblDettagliProblemi;
  String get controlloFormLblNote;
  String get controlloFormHintNote;
  String get controlloFormSyncOk;
  String get controlloFormLblStatoRegina;
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
}
