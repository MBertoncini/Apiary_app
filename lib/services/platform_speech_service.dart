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
  double _confidence = 0.0;
  List<String> _recognitionHistory = []; // Stores final results
  String? _error;

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

    if (status == stt.SpeechToText.doneStatus && wasListening) {
        debugPrint('[PlatformSpeech] Listening done.');
        // If listening stops unexpectedly, ensure processing is false
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


  // --- Corrected Error handler ---
  // Use the imported type directly (no 'stt.' prefix needed)
  void _onSpeechError(SpeechRecognitionError error) { // <--- CORRECTED TYPE USAGE
    debugPrint('[PlatformSpeech] Speech error: ${error.errorMsg}, Permanent: ${error.permanent}');
    _error = 'Errore: ${error.errorMsg}';
    _isListening = false;
    _isProcessing = false; // Ensure processing stops on error
    notifyListeners();
  }
  // --- End of corrected handler ---


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
    notifyListeners();

    try {
      debugPrint('[PlatformSpeech] Starting listening with locale: $_languageCode');

      bool success = await _speech.listen(
        onResult: _onSpeechResult,
        localeId: _languageCode,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        onDevice: false,
      );

      // _isListening state is primarily managed by _onSpeechStatus
      // Setting _isProcessing false here might be premature if listen fails immediately
      // Let status/error handlers manage _isProcessing state more reliably.
      // _isProcessing = false; // Removed from here

      if (!success) {
        _error = 'Non è stato possibile avviare l\'ascolto.';
        debugPrint('[PlatformSpeech] Failed to start listening (listen returned false).');
        _isListening = false; // Ensure state is consistent
        _isProcessing = false; // Explicitly set processing false on failure
        notifyListeners(); // Notify about the failure state
        return false; // Return failure
      } else {
        debugPrint('[PlatformSpeech] Listening potentially started (waiting for status confirmation).');
        // Don't notify here, wait for _onSpeechStatus to confirm 'listening'
      }

      // Success here means the command was accepted, not necessarily that listening *is* active yet.
      return true; // Return true indicating the attempt was made
    } catch (e) {
      debugPrint('[PlatformSpeech] Error starting speech recognition: $e');
      _error = 'Errore nell\'avvio dell\'ascolto: $e';
      _isListening = false;
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening && !_speech.isListening) {
      debugPrint('[PlatformSpeech] Not currently listening.');
      return;
    }
     if (_isProcessing && _isListening) { // Allow stop if processing but not listening (e.g. init failed)
       debugPrint('[PlatformSpeech] Currently processing other operation, cannot stop now.');
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