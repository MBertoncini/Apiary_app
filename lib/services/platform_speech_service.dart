// lib/services/platform_speech_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
// Import the specific error type
import 'package:speech_to_text/speech_recognition_error.dart'; // <--- ADD THIS IMPORT
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class PlatformSpeechService with ChangeNotifier {
  // ... (rest of the class properties and methods are mostly the same) ...
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Current state
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _transcription = '';
  String _languageCode = 'it_IT';

  /// Maps an ISO 639-1 language code (e.g. 'it', 'en') to a speech_to_text
  /// locale identifier (e.g. 'it_IT', 'en_US').
  static String speechLocaleFor(String langCode) {
    switch (langCode) {
      case 'en': return 'en_US';
      default:   return 'it_IT';
    }
  }
  double _confidence = 0.0;
  List<String> _recognitionHistory = []; // Stores final results
  String? _error;

  // Session tracking — incremented on every startListening() call so that
  // late results delivered by Android after the session ended are silently
  // discarded rather than being mistaken for results from the NEW session.
  int _sessionGeneration = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get transcription => _transcription;
  String get languageCode => _languageCode;
  double get confidence => _confidence;
  List<String> get recognitionHistory => _recognitionHistory; // <-- Note getter name
  String? get error => _error;

 // ... (constructor, _initSpeech, _onSpeechStatus are the same) ...
  Future<bool> _initSpeech() async {
    // If already initialized or initializing, return current status
    if (_isInitialized) return true;
    // Added a check to prevent multiple initializations running concurrently
    if (_isProcessing) return false; // Or handle as appropriate

    _isProcessing = true; // Indicate initialization is in progress
    _error = null;
    notifyListeners(); // Notify UI that initialization started

    try {
      debugPrint('[PlatformSpeech] Initializing speech recognition');

      bool available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError, // Keep this as is
        debugLogging: kDebugMode, // Only use debug logging in debug mode
      );

      _isInitialized = available;
      _isProcessing = false; // Initialization finished

      if (!available) {
        _error = 'Il riconoscimento vocale non è disponibile su questo dispositivo';
        debugPrint('[PlatformSpeech] Speech recognition not available');
      } else {
        debugPrint('[PlatformSpeech] Speech recognition initialized successfully');
      }

      notifyListeners();
      return available;
    } catch (e) {
      _error = 'Errore nell\'inizializzazione del riconoscimento vocale: $e';
      debugPrint('[PlatformSpeech] Error initializing speech recognition: $e');
      _isInitialized = false;
      _isProcessing = false; // Initialization failed
      notifyListeners();
      return false;
    }
  }

  // Status change handler
  void _onSpeechStatus(String status) {
    debugPrint('[PlatformSpeech] Speech status: $status');
    final wasListening = _isListening;

    // Update listening state based on status
    _isListening = _speech.isListening; // More reliable than checking status string 'listening'

    // Clear processing flag when listening starts (startup/init is done)
    if (!wasListening && _isListening) {
      _isProcessing = false;
    }

    if (status == stt.SpeechToText.doneStatus && wasListening) {
        debugPrint('[PlatformSpeech] Listening done.');
        if(_isListening == false && _isProcessing){
           _isProcessing = false;
        }
    }

    // Prevent unnecessary notifications if state hasn't changed
    if (wasListening != _isListening) {
      // If stopping, ensure processing is marked false
      if(!_isListening) _isProcessing = false;
      notifyListeners();
    }
  }


  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint('[PlatformSpeech] Speech error: ${error.errorMsg}, Permanent: ${error.permanent}');

    // error_client = Android engine crash / session overlap — non-fatal.
    // Force re-init so the next startListening() reinitialises cleanly,
    // but don't expose an error message so the manager can retry silently.
    if (error.errorMsg == 'error_client') {
      _isListening = false;
      _isProcessing = false;
      _isInitialized = false;
      notifyListeners();
      return;
    }

    // error_speech_timeout = engine timed out waiting for speech (natural end of session).
    // Treat as a silent stop so the continuous-mode loop in the manager can finalize
    // the accumulated buffer instead of showing a raw error string.
    if (error.errorMsg == 'error_speech_timeout') {
      _isListening = false;
      _isProcessing = false;
      notifyListeners();
      return;
    }

    // "error no match" = the engine found no speech in this sub-session.
    // During continuous-mode restarts this is expected (silence between words).
    // Treat it as a silent stop so the manager's buffer-accumulation loop can
    // either keep accumulating or finalize cleanly, without discarding the buffer.
    if (error.errorMsg == 'error no match' || error.errorMsg == 'error_no_match') {
      _isListening = false;
      _isProcessing = false;
      notifyListeners();
      return;
    }

    _error = 'Errore: ${error.errorMsg}';
    _isListening = false;
    _isProcessing = false;

    // On permanent errors the underlying engine is dead — force re-init next time
    if (error.permanent) {
      _isInitialized = false;
    }

    notifyListeners();
  }


 // ... (hasMicrophonePermission, startListening, stopListening are the same) ...
  Future<bool> hasMicrophonePermission() async {
    var status = await Permission.microphone.status;
    debugPrint('[PlatformSpeech] Microphone permission status: $status');

    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('[PlatformSpeech] Requesting microphone permission');
      status = await Permission.microphone.request();
      debugPrint('[PlatformSpeech] Microphone permission after request: $status');
    }

    final bool granted = status.isGranted;

    if (!granted) {
      final permError = 'Permesso del microfono non concesso';
      // Notify listeners only if the error is new or changed
      if (_error != permError) {
         _error = permError;
         notifyListeners();
      }
    } else {
       // Clear permission error if granted now
       if (_error == 'Permesso del microfono non concesso') {
          _error = null;
          notifyListeners();
       }
    }

    return granted;
  }

  Future<bool> startListening() async {
    if (_isListening) {
      debugPrint('[PlatformSpeech] Already listening, ignoring request.');
      return true;
    }
    if (_isProcessing) {
       debugPrint('[PlatformSpeech] Already processing (initializing/stopping?), ignoring request.');
       return false;
    }

    if (!await hasMicrophonePermission()) {
      debugPrint('[PlatformSpeech] Microphone permission denied.');
      return false;
    }

    if (!_isInitialized) {
      debugPrint('[PlatformSpeech] Not initialized, attempting to initialize...');
      bool initialized = await _initSpeech();
      if (!initialized) {
        debugPrint('[PlatformSpeech] Initialization failed, cannot start listening.');
        return false;
      }
    }

    _transcription = '';
    _confidence = 0.0;
    _error = null;
    _isProcessing = true;
    _sessionGeneration++; // invalidate any in-flight results from the previous session
    final int mySession = _sessionGeneration;
    notifyListeners();

    try {
      debugPrint('[PlatformSpeech] Starting listening with locale: $_languageCode (session $mySession)');

      // speech_to_text v7+ returns Future<void> — do not assign to bool
      await _speech.listen(
        onResult: (result) {
          // Ignore results that arrive after a newer session has started.
          if (_sessionGeneration == mySession) _onSpeechResult(result);
        },
        localeId: _languageCode,
        pauseFor: const Duration(seconds: 8),
        listenFor: const Duration(seconds: 30),
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          // cancelOnError: false so a brief "no match" mid-session doesn't kill the whole session
          cancelOnError: false,
          partialResults: true,
          onDevice: false,
        ),
      );

      debugPrint('[PlatformSpeech] listen() called — waiting for status confirmation.');
      // State is managed by _onSpeechStatus / _onSpeechError
      return true;
    } catch (e) {
      debugPrint('[PlatformSpeech] Error starting speech recognition: $e');
      _error = 'Errore nell\'avvio dell\'ascolto: $e';
      _isListening = false;
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Short listen session used only to detect a trigger word.
  /// Uses dictation mode with partial results so the trigger word is
  /// detected as soon as Android returns any partial recognition.
  Future<bool> startListeningForTrigger() async {
    if (_isListening || _isProcessing) return false;
    if (!_isInitialized) {
      if (!await _initSpeech()) return false;
    }

    _transcription = '';
    _error = null;
    _sessionGeneration++;
    final int mySession = _sessionGeneration;
    notifyListeners();

    try {
      debugPrint('[PlatformSpeech] Starting trigger listen (session $mySession)');
      await _speech.listen(
        onResult: (result) {
          if (_sessionGeneration == mySession) _onSpeechResult(result);
        },
        localeId: _languageCode,
        pauseFor: const Duration(milliseconds: 1500),
        listenFor: const Duration(seconds: 10),
        listenOptions: stt.SpeechListenOptions(
          // confirmation mode is not supported on all Android devices;
          // dictation + partialResults lets us detect the word immediately.
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          onDevice: false,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[PlatformSpeech] Error starting trigger listen: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening && !_speech.isListening) {
      debugPrint('[PlatformSpeech] Not currently listening.');
      return;
    }

    _isProcessing = true; // Indicate stopping process started

    try {
      debugPrint('[PlatformSpeech] Stopping listening');
      await _speech.stop();
      // _isListening state managed by _onSpeechStatus ('done')
      _isProcessing = false; // Stopped successfully
      debugPrint('[PlatformSpeech] Listening stop command sent.');
      // Do not notify here, wait for 'done' status
    } catch (e) {
      debugPrint('[PlatformSpeech] Error stopping speech recognition: $e');
      _error = 'Errore nell\'arresto dell\'ascolto: $e';
      _isListening = false; // Ensure consistent state on error
      _isProcessing = false;
      notifyListeners();
    }
  }


  // ... (_onSpeechResult, setLanguageCode, clearTranscription, dispose are the same) ...
  void _onSpeechResult(SpeechRecognitionResult result) {
    debugPrint(
        '[PlatformSpeech] Result: final=${result.finalResult}, words="${result.recognizedWords}", confidence=${result.hasConfidenceRating ? result.confidence : 'N/A'}');

    _transcription = result.recognizedWords; // Update with latest partial/final

    bool notify = true; // Assume notification needed unless state is unchanged

    if (result.finalResult) {
      debugPrint('[PlatformSpeech] Final speech result received.');
      final bool wasListening = _isListening;
      _isListening = false; // Listening stops when a final result is confirmed

      if (result.recognizedWords.isNotEmpty) {
        _confidence = result.hasConfidenceRating && result.confidence > 0
            ? result.confidence
            : 1.0;

        _recognitionHistory.add(result.recognizedWords);
        if (_recognitionHistory.length > 10) {
          _recognitionHistory.removeAt(0);
        }
         debugPrint('[PlatformSpeech] Updated transcription: "$_transcription" (Confidence: $_confidence)');

      } else {
        debugPrint('[PlatformSpeech] Final result is empty.');
        _transcription = "";
        _confidence = 0.0;
      }
       _isProcessing = false; // No longer processing this speech segment
       if (!wasListening) notify = false; // Don't notify if wasn't listening anyway

    } else {
       // Partial result - transcription already updated.
       // Only notify if listening state is true (avoid notifying after stop/error)
       if (!_isListening && !_speech.isListening) notify = false;
    }

    if (notify) {
       notifyListeners();
    }
  }

  void setLanguageCode(String languageCode) {
    if (_languageCode != languageCode) {
      debugPrint('[PlatformSpeech] Setting language code to: $languageCode');
      _languageCode = languageCode;
      notifyListeners();
    }
  }

  void clearTranscription() {
    debugPrint('[PlatformSpeech] Clearing transcription and history');
    bool changed = _transcription.isNotEmpty || _confidence != 0.0 || _recognitionHistory.isNotEmpty || _error != null;
    _transcription = '';
    _confidence = 0.0;
    _recognitionHistory.clear();
    _error = null;
    if (changed) {
       notifyListeners();
    }
  }

   @override
  void dispose() {
    debugPrint('[PlatformSpeech] Disposing PlatformSpeechService');
    _speech.stop();
    _speech.cancel(); // Important for cleaning up platform resources
    super.dispose();
  }
} // End of class