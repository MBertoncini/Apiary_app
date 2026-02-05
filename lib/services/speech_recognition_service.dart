// lib/services/speech_recognition_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../services/voice_feedback_service.dart';

/// Servizio di riconoscimento vocale reale usando il pacchetto speech_to_text
class SpeechRecognitionService with ChangeNotifier {
  // Istanza di speech_to_text
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceFeedbackService _feedbackService;
  
  // Stato corrente
  bool _isInitialized = false;
  bool _isListening = false;
  String _transcription = '';
  String _recognitionMode = 'standard';
  double _confidence = 0.0;
  double _currentVolume = 0.0;
  List<String> _partialTranscripts = [];
  List<stt.LocaleName> _locales = [];
  
  // Timer per timeout automatico
  Timer? _listenTimeoutTimer;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get transcription => _transcription;
  String get recognitionMode => _recognitionMode;
  double get confidence => _confidence;
  double get currentVolume => _currentVolume;
  List<String> get partialTranscripts => _partialTranscripts;
  List<stt.LocaleName> get locales => _locales;
  
  // Constructor
  SpeechRecognitionService({VoiceFeedbackService? feedbackService}) 
      : _feedbackService = feedbackService ?? VoiceFeedbackService() {
    _initSpeech();
  }
  
  // Inizializza il riconoscimento vocale
  Future<bool> _initSpeech() async {
    try {
      _isInitialized = await _speech.initialize(
        onStatus: _onStatusChanged,
        onError: _onSpeechError,
        debugLogging: kDebugMode,
      );
      
      if (_isInitialized) {
        // Ottieni le lingue disponibili
        _locales = await _speech.locales();
        notifyListeners();
      }
      
      return _isInitialized;
    } catch (e) {
      debugPrint('Errore nell\'inizializzazione del riconoscimento vocale: $e');
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }
  
  // Callback per cambio di stato del riconoscimento
  void _onStatusChanged(String status) {
    debugPrint('Speech status: $status');
    
    if (status == 'done') {
      _isListening = false;
      notifyListeners();
    }
  }
  
  // Callback per errori del riconoscimento
  void _onSpeechError(Object error) {
    debugPrint('Speech error: $error');
    _isListening = false;
    
    // Riproduci suono di errore
    _feedbackService.playErrorSound();
    
    notifyListeners();
  }
  
  // Callback per i risultati del riconoscimento
  void _onSpeechResult(SpeechRecognitionResult result) {
    // Aggiorna la trascrizione
    _transcription = result.recognizedWords;
    _confidence = result.confidence;
    
    // Aggiungi alla lista dei risultati parziali
    if (result.finalResult && _transcription.isNotEmpty) {
      _partialTranscripts.add(_transcription);
      
      // Limita la lunghezza della cronologia
      if (_partialTranscripts.length > 10) {
        _partialTranscripts.removeAt(0);
      }
      
      // Suono di successo
      _feedbackService.playSuccessSound();
    }
    
    notifyListeners();
  }
  
  // Callback per aggiornamento volume (ampiezza sonora)
  void _onSoundLevelChange(double level) {
    _currentVolume = level;
    notifyListeners();
  }
  
  // Avvia l'ascolto
  Future<bool> startListening({
    String mode = 'standard',
    String localeId = 'it_IT',
    String? wakePhrase,
    int timeoutSeconds = 60,
  }) async {
    if (!_isInitialized) {
      await _initSpeech();
    }
    
    if (!_isInitialized) {
      return false;
    }
    
    // Cancella timer precedente se esistente
    _listenTimeoutTimer?.cancel();
    
    try {
      _recognitionMode = mode;
      _transcription = '';
      
      // Verifica che la lingua richiesta sia disponibile
      localeId = _findBestLocaleMatch(localeId);
      
      // Riproduci suono di inizio ascolto
      _feedbackService.playListeningStartSound();
      
      // Avvia il riconoscimento
      _isListening = await _speech.listen(
        onResult: _onSpeechResult,
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation,
        onSoundLevelChange: _onSoundLevelChange,
        cancelOnError: true,
        partialResults: true,
      );
      
      // Imposta timer per timeout automatico
      if (_isListening && timeoutSeconds > 0) {
        _listenTimeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
          if (_isListening) {
            stopListening();
          }
        });
      }
      
      notifyListeners();
      return _isListening;
    } catch (e) {
      debugPrint('Errore nell\'avvio del riconoscimento vocale: $e');
      _isListening = false;
      
      // Riproduci suono di errore
      _feedbackService.playErrorSound();
      
      notifyListeners();
      return false;
    }
  }
  
  // Trova la migliore corrispondenza per la lingua richiesta
  String _findBestLocaleMatch(String localeId) {
    // Se la lingua richiesta è disponibile, usala
    final exactMatch = _locales.where((locale) => locale.localeId == localeId);
    if (exactMatch.isNotEmpty) {
      return localeId;
    }
    
    // Altrimenti cerca una corrispondenza parziale (solo prefisso lingua)
    final prefix = localeId.split('_')[0];
    final partialMatch = _locales.where((locale) => locale.localeId.startsWith('${prefix}_'));
    if (partialMatch.isNotEmpty) {
      return partialMatch.first.localeId;
    }
    
    // Default fallback a inglese o alla prima lingua disponibile
    final english = _locales.where((locale) => locale.localeId.startsWith('en_'));
    if (english.isNotEmpty) {
      return english.first.localeId;
    }
    
    // Se non c'è nemmeno l'inglese, usa la prima lingua disponibile
    return _locales.isNotEmpty ? _locales.first.localeId : 'en_US';
  }
  
  // Interrompi l'ascolto
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _listenTimeoutTimer?.cancel();
    
    try {
      await _speech.stop();
      _isListening = false;
      
      // Riproduci suono di fine ascolto
      _feedbackService.playListeningStopSound();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Errore nell\'interruzione del riconoscimento vocale: $e');
    }
  }
  
  // Annulla l'ascolto
  Future<void> cancelListening() async {
    if (!_isListening) return;
    
    _listenTimeoutTimer?.cancel();
    
    try {
      await _speech.cancel();
      _isListening = false;
      _transcription = '';
      
      notifyListeners();
    } catch (e) {
      debugPrint('Errore nell\'annullamento del riconoscimento vocale: $e');
    }
  }
  
  // Cancella la trascrizione corrente
  void clearTranscription() {
    _transcription = '';
    notifyListeners();
  }
  
  // Ottieni le lingue disponibili per il riconoscimento
  Future<List<Map<String, String>>> getAvailableLocales() async {
    if (!_isInitialized) {
      await _initSpeech();
    }
    
    return _locales.map((locale) => {
      'id': locale.localeId,
      'name': locale.name,
    }).toList();
  }
  
  // Verifica se il permesso del microfono è concesso
  Future<bool> hasMicrophonePermission() async {
    if (!_isInitialized) {
      await _initSpeech();
    }
    
    return _speech.hasPermission;
  }
  
  @override
  void dispose() {
    _listenTimeoutTimer?.cancel();
    _speech.cancel();
    super.dispose();
  }
}