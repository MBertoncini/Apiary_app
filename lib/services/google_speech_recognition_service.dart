// lib/services/google_speech_recognition_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
// Import the main library - this exports the config classes we need
import 'package:google_speech/google_speech.dart';
// Import the generated Protobuf library WITH an alias for the response type ONLY
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart'
    as speech_pb; // Alias for Protobuf response type

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';
import '../config/google_credentials.dart';

/// Servizio di riconoscimento vocale che utilizza Google Speech-to-Text API
class GoogleSpeechRecognitionService with ChangeNotifier {
  // Google Speech API
  SpeechToText? _speechToText;
  // The stream still returns the Protobuf response type
  StreamSubscription<speech_pb.StreamingRecognizeResponse>?
      _audioStreamSubscription;
  final RecorderStream _recorder = RecorderStream();

  // Stato corrente
  bool _isInitialized = false;
  bool _isListening = false;
  String _transcription = '';
  String _languageCode = 'it-IT'; // Lingua predefinita: italiano
  double _confidence = 0.0;
  List<String> _partialTranscripts = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get transcription => _transcription;
  String get languageCode => _languageCode;
  double get confidence => _confidence;
  List<String> get partialTranscripts => _partialTranscripts;

  // Constructor
  GoogleSpeechRecognitionService() {
    _initSpeech();
  }

  // Inizializza il riconoscimento vocale
  Future<bool> _initSpeech() async {
    if (_isInitialized) return true;

    try {
      debugPrint('Initializing Recorder...');
      await _recorder.initialize();
      debugPrint('Recorder Initialized.');

      final tempDir = await getTemporaryDirectory();
      final credentialsFile = File('${tempDir.path}/google_credentials.json');
      debugPrint('Writing credentials to ${credentialsFile.path}...');
      await credentialsFile.writeAsString(GoogleCredentials.serviceAccountJson);
      debugPrint('Credentials written.');

      debugPrint('Initializing SpeechToText...');
      _speechToText = SpeechToText.viaServiceAccount(
          ServiceAccount.fromString(GoogleCredentials.serviceAccountJson));
      debugPrint('SpeechToText Initialized.');

      _isInitialized = true;
      notifyListeners();
      debugPrint('Google Speech Initialized Successfully.');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error initializing Google Speech: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
      notifyListeners();
      return false;
    } finally {
      // Clean up temp file if needed
    }
  }

  // Verifica e richiede i permessi del microfono
  Future<bool> hasMicrophonePermission() async {
    var status = await Permission.microphone.status;
    debugPrint('Microphone permission status: $status');
    if (status.isGranted) return true;

    if (!status.isGranted) {
      debugPrint('Requesting microphone permission...');
      status = await Permission.microphone.request();
      debugPrint('Microphone permission status after request: $status');
      if (status.isPermanentlyDenied) {
        debugPrint('Microphone permission permanently denied. Please enable in settings.');
      }
    }
    return status.isGranted;
  }

  // Avvia l'ascolto
  Future<bool> startListening() async {
    if (_isListening) {
      debugPrint('Already listening.');
      return true;
    }
    if (!_isInitialized) {
      debugPrint('Speech service not initialized. Initializing...');
      final initialized = await _initSpeech();
      if (!initialized) {
        debugPrint('Failed to initialize speech service. Cannot start listening.');
        return false;
      }
    }
    final hasPermission = await hasMicrophonePermission();
    if (!hasPermission) {
      debugPrint('Microphone permission denied. Cannot start listening.');
      return false;
    }

    _transcription = '';
    _partialTranscripts.clear();
    _confidence = 0.0;
    notifyListeners();
    debugPrint('Starting listening...');

    try {
      // --- Configuration Changes START ---

      // 1. Create and configure SpeechContext (using the class from google_speech.dart)
      final speechContext = SpeechContext([ // Pass list directly to constructor
        'apiario', 'arnia', 'regina', 'telaini', 'covata', 'scorte',
        'controllo', 'ispezione', 'trattamento', 'sciamatura',
      ]);

      // 2. Create and configure RecognitionConfig (using the class from google_speech.dart)
      final recognitionConfig = RecognitionConfig(
        // Use the Enums from google_speech.dart/config/recognition_config_v1.dart
        encoding: AudioEncoding.LINEAR16,
        model: RecognitionModel.command_and_search, // Or other models like 'default'
        enableAutomaticPunctuation: true,
        sampleRateHertz: 16000,
        languageCode: _languageCode,
        maxAlternatives: 1,
        speechContexts: [speechContext], // Add the context
      );

      // 3. Create the StreamingRecognitionConfig (using the class from google_speech.dart)
      final streamingConfig = StreamingRecognitionConfig(
          config: recognitionConfig, // Pass the google_speech RecognitionConfig
          interimResults: true,
      );

      // --- Configuration Changes END ---

      // Start recorder *before* setting up the stream listen
      await _recorder.start();
      debugPrint('Recorder started.');

      // Set flag immediately before listening to the stream
      _isListening = true; // Assume success until proven otherwise by errors
      notifyListeners();

      // Configure the stream
      final responseStream = _speechToText!.streamingRecognize(
        streamingConfig, // Pass the helper config object
        _recorder.audioStream!,
      );

      debugPrint('Streaming recognition configured. Listening for responses...');

      _audioStreamSubscription = responseStream.listen(
        (data) {
          // Only process if still considered listening
          if (_isListening) {
             _processRecognitionResponse(data); // data is speech_pb.StreamingRecognizeResponse
          }
        },
        onDone: () {
          debugPrint('Speech recognition stream done.');
          // If we reached 'done', we were definitely listening.
          if (_isListening) {
            _recorder.stop(); // Stop recorder
             debugPrint('Recorder stopped on stream done.');
          }
          _isListening = false; // Update state *after* potential stop
          notifyListeners();
        },
        onError: (error, stackTrace) {
          debugPrint('Error in speech recognition stream: $error');
          debugPrint('Stack trace: $stackTrace');
          // If an error occurred while we thought we were listening, try to stop.
          if (_isListening) {
             _recorder.stop(); // Stop recorder on error
             debugPrint('Recorder stopped on stream error.');
          }
          _isListening = false; // Update state *after* potential stop
          notifyListeners();
        },
        cancelOnError: true,
      );

      // Redundant notification removed, already done before listen setup

      debugPrint('Listening started successfully.');
      return true;

    } catch (e, stackTrace) {
      debugPrint('Error starting speech recognition: $e');
      debugPrint('Stack trace: $stackTrace');
      _isListening = false; // Ensure state is false on failure
      notifyListeners();
      try {
        // Attempt to stop recorder if start failed midway, only if needed
        // No reliable way to check recorder state, so just try stopping
        await _recorder.stop();
        debugPrint('Attempted recorder stop after startListening failed.');
      } catch (stopError) {
        // Log nested error but don't crash
        debugPrint('Error stopping recorder after startListening failed: $stopError');
      }
      return false;
    }
  }

  // Elabora le risposte dal riconoscimento vocale
  // Parameter type remains the Protobuf response type
  void _processRecognitionResponse(speech_pb.StreamingRecognizeResponse response) {
    if (response.results.isEmpty || response.results.first.alternatives.isEmpty) {
      return;
    }
    final result = response.results.first;
    final alternative = result.alternatives.first;
    final isFinal = result.isFinal;
    final String text = alternative.transcript.trim();
    final confidence = alternative.confidence;

    _transcription = text;
    _confidence = confidence;

    if (isFinal && text.isNotEmpty) {
      debugPrint('Final Result: "$text" (Confidence: ${confidence.toStringAsFixed(3)})');
      _partialTranscripts.add(text);
      if (_partialTranscripts.length > 10) {
        _partialTranscripts.removeAt(0);
      }
    }
    notifyListeners();
  }

  // Interrompi l'ascolto
  Future<void> stopListening() async {
    // Use the _isListening flag to check state
    if (!_isListening) {
      debugPrint('Not currently listening (based on _isListening flag).');
      return;
    }

    debugPrint('Stopping listening...');
    try {
      // 1. Cancel the stream subscription
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // 2. Set listening flag to false *before* stopping recorder
      // This prevents race conditions in callbacks (onDone/onError)
      _isListening = false;
      notifyListeners(); // Notify UI immediately that listening has stopped

      // 3. Stop the recorder
      await _recorder.stop();
      debugPrint('Recorder stopped.');

      // State already updated
      debugPrint('Listening stopped successfully.');
    } catch (e, stackTrace) {
        debugPrint('Error stopping speech recognition: $e');
        debugPrint('Stack trace: $stackTrace');
        // Ensure state is consistent even on error
        _isListening = false;
        _audioStreamSubscription = null;
        notifyListeners();
    }
  }

  // Imposta la lingua per il riconoscimento
  void setLanguageCode(String languageCode) {
    if (_languageCode != languageCode) {
      debugPrint('Setting language code to: $languageCode');
      _languageCode = languageCode;
      if (_isListening) {
        debugPrint('Language changed while listening. Restarting listener...');
        stopListening().then((_) {
          startListening();
        });
      }
       notifyListeners();
    }
  }

  // Cancella la trascrizione corrente e la cronologia
  void clearTranscription() {
    debugPrint('Clearing transcription and history.');
    _transcription = '';
    _confidence = 0.0;
    _partialTranscripts.clear();
    notifyListeners();
  }

  // Dispose resources when the service is no longer needed
  @override
  void dispose() {
    debugPrint('Disposing GoogleSpeechRecognitionService...');
    // 1. Cancel subscription
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    // 2. Stop recorder (use a final check on _isListening maybe, though dispose implies stop)
    // No reliable check, just attempt stop if dispose is called.
    _recorder.stop().catchError((e) {
        // Log error during dispose-stop but don't prevent dispose
        debugPrint("Error stopping recorder during dispose: $e");
    });

    // 3. Dispose recorder itself
    _recorder.dispose();

    _isListening = false; // Ensure state is false
    debugPrint('GoogleSpeechRecognitionService disposed.');
    super.dispose();
  }
}