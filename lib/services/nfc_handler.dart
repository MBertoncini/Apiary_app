import 'package:flutter/material.dart';
import '../models/arnia.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/nfc_service.dart';
import '../services/nfc_settings_service.dart';
import '../services/audio_service.dart';
import '../services/language_service.dart';
import '../services/voice_feedback_service.dart';
import '../utils/navigator_key.dart';
import '../l10n/app_strings.dart';
import '../constants/app_constants.dart';
import 'package:provider/provider.dart';

class NfcHandler extends ChangeNotifier with WidgetsBindingObserver {
  final ApiService _apiService;
  final StorageService _storageService;
  final NfcService _nfcService = NfcService();
  final NfcSettingsService _nfcSettings = NfcSettingsService();
  final AudioService _audioService = AudioService();
  final VoiceFeedbackService _feedbackService = VoiceFeedbackService();

  bool _isInitialized = false;
  bool _isProcessing = false;

  NfcHandler(this._apiService, this._storageService) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nfcService.stopBackgroundSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndStartListening();
    } else if (state == AppLifecycleState.paused) {
      _nfcService.stopBackgroundSession();
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _checkAndStartListening();
  }

  Future<void> _checkAndStartListening() async {
    final alwaysListening = await _nfcSettings.getAlwaysListening();
    if (alwaysListening) {
      await _nfcService.startBackgroundSession(_onTagDiscovered);
    } else {
      await _nfcService.stopBackgroundSession();
    }
  }

  Future<void> refreshSettings() async {
    await _checkAndStartListening();
  }

  Arnia? _lastScannedArnia;
  Arnia? get lastScannedArnia => _lastScannedArnia;

  Future<void> _onTagDiscovered(String tagId) async {
    await resolveAndNavigateByNfcId(tagId, source: 'nfc');
  }

  /// Cerca un'arnia per nfc_id (UID hex) localmente poi via API e naviga
  /// alla schermata appropriata (voice o manual) in base alle settings NFC.
  ///
  /// Riusato sia dalla sessione NFC in-app che dal [DeepLinkHandler] quando
  /// l'app viene aperta da un tag scansionato dall'OS fuori dall'app.
  ///
  /// [source] è informativo ('nfc' o 'deeplink') per il logging.
  Future<void> resolveAndNavigateByNfcId(
    String tagId, {
    String source = 'nfc',
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;

    debugPrint('NFC Handler [$source]: Tag rilevato -> $tagId');

    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('NFC Handler [$source]: Context non disponibile');
        return;
      }

      final languageService = Provider.of<LanguageService>(context, listen: false);
      final s = languageService.strings;

      // 1. Cerca localmente
      Arnia? foundArnia;
      final storedData = await _storageService.getStoredData('arnie');
      if (storedData != null && storedData is List) {
        for (var a in storedData) {
          if (a is Map && a['nfc_id'] == tagId) {
            foundArnia = Arnia.fromJson(Map<String, dynamic>.from(a));
            break;
          }
        }
      }

      // 2. Cerca via API se non trovato localmente
      if (foundArnia == null) {
        try {
          final results = await _apiService.searchArnie(tagId);
          if (results.isNotEmpty) {
            for (var r in results) {
              if (r['nfc_id'] == tagId) {
                foundArnia = Arnia.fromJson(Map<String, dynamic>.from(r));
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('Errore ricerca API NFC: $e');
        }
      }

      if (foundArnia != null) {
        _lastScannedArnia = foundArnia;
        notifyListeners();

        _audioService.playSuccessSound();
        _feedbackService.vibrateSuccess();

        final action = await _nfcSettings.getAction();

        bool isOnVoiceScreen = false;
        navigatorKey.currentState?.popUntil((route) {
          if (route.settings.name == AppConstants.voiceCommandRoute) {
            isOnVoiceScreen = true;
          }
          return true;
        });

        if (action == NfcSettingsService.actionVoice) {
          if (isOnVoiceScreen) {
            debugPrint('NFC Handler: Già su VoiceCommandScreen, aggiornamento via listener');
          } else {
            _navigateToVoice(foundArnia, s);
          }
        } else {
          _navigateToManual(foundArnia);
        }
      } else {
        _feedbackService.vibrateError();
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(s.nfcTagNotFound)),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('Errore critico NFC Handler [$source]: $e');
      debugPrint('$stack');
    } finally {
      await Future.delayed(const Duration(milliseconds: 1500));
      _isProcessing = false;
    }
  }

  void _navigateToVoice(Arnia arnia, AppStrings s) {
    navigatorKey.currentState?.pushNamed(
      AppConstants.voiceCommandRoute,
      arguments: {
        'apiarioId': arnia.apiario,
        'apiarioNome': arnia.apiarioNome,
        'arniaId': arnia.id,
        'arniaNumero': arnia.numero,
        'initialArnia': arnia,
        'bannerText': s.nfcVoiceBanner(arnia.numero, arnia.apiarioNome),
      },
    );
  }

  void _navigateToManual(Arnia arnia) {
    navigatorKey.currentState?.pushNamed(
      AppConstants.controlloCreateRoute,
      arguments: {
        'arniaId': arnia.id,
      },
    );
  }
}

