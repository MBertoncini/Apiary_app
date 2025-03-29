// lib/services/wit_speech_recognition_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/voice_entry.dart';
import 'google_speech_recognition_service.dart';

class WitSpeechRecognitionService with ChangeNotifier {
  // Constants
  static const String _witApiUrl = 'https://api.wit.ai/speech';
  static const String _witApiToken = '2NJ4OP6FZXEWAJ56GC7PET2KOKXIXJZM'; // Sostituisci con il tuo token
  
  // Flutter Sound recorder
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  // Stato corrente
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _transcription = '';
  String _languageCode = 'it-IT';
  double _confidence = 0.0;
  List<String> _partialTranscripts = [];
  String? _recordingPath;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get transcription => _transcription;
  String get languageCode => _languageCode;
  double get confidence => _confidence;
  List<String> get partialTranscripts => _partialTranscripts;
  
  // Constructor
  WitSpeechRecognitionService() {
    _initRecorder();
  }
  
  // Inizializza il registratore audio
  Future<bool> _initRecorder() async {
    if (_isInitialized) return true;
    
    try {
      debugPrint('Initializing Recorder...');
      await _recorder.openRecorder();
      debugPrint('Recorder Initialized.');
      
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error initializing recorder: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
      notifyListeners();
      return false;
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
      final initialized = await _initRecorder();
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
      // Prepara percorso per la registrazione
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/temp_recording.wav';
      
      // Inizia la registrazione
      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.pcm16WAV,
        sampleRate: 16000, // Wit.ai preferisce 16kHz
      );
      
      _isListening = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }
  
  // Interrompi l'ascolto
  Future<void> stopListening() async {
    if (!_isListening) {
      debugPrint('Not currently listening.');
      return;
    }
    
    debugPrint('Stopping listening...');
    try {
      // Ferma la registrazione
      final recordingResult = await _recorder.stopRecorder();
      _isListening = false;
      notifyListeners();
      
      // Se abbiamo un percorso di registrazione, elaboriamo l'audio
      if (recordingResult != null && recordingResult.isNotEmpty) {
        _isProcessing = true;
        notifyListeners();
        
        await _processAudioWithWit(recordingResult);
        
        _isProcessing = false;
        notifyListeners();
      }
      
      debugPrint('Listening stopped successfully.');
    } catch (e, stackTrace) {
      debugPrint('Error stopping recording: $e');
      debugPrint('Stack trace: $stackTrace');
      _isListening = false;
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // Elabora l'audio con Wit.ai
  Future<void> _processAudioWithWit(String audioFilePath) async {
    try {
      debugPrint('Processing audio with Wit.ai: $audioFilePath');
      
      // Leggi il file audio
      final file = File(audioFilePath);
      if (!await file.exists()) {
        debugPrint('Audio file does not exist: $audioFilePath');
        return;
      }
      
      final audioBytes = await file.readAsBytes();
      
      // Prepara la richiesta HTTP
      final uri = Uri.parse('$_witApiUrl');
      final request = http.Request('POST', uri);
      
      // Imposta gli headers
      request.headers.addAll({
        'Authorization': 'Bearer $_witApiToken',
        'Content-Type': 'audio/wav',
        'Accept': 'application/json',
      });
      
      // Imposta il corpo della richiesta con i byte audio
      request.bodyBytes = audioBytes;
      
      // Invia la richiesta
      final httpClient = http.Client();
      final streamedResponse = await httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        debugPrint('Wit.ai response: $responseJson');
        
        // Estrai il testo trascritto
        _transcription = responseJson['text'] ?? '';
        _confidence = responseJson['entities']?.isNotEmpty ?? false ? 0.9 : 0.6;
        
        if (_transcription.isNotEmpty) {
          _partialTranscripts.add(_transcription);
          if (_partialTranscripts.length > 10) {
            _partialTranscripts.removeAt(0);
          }
        }
        
        notifyListeners();
      } else {
        debugPrint('Error from Wit.ai API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error processing audio with Wit.ai: $e');
    }
  }
  
  // Imposta la lingua per il riconoscimento (nota: Wit.ai è già configurato per lingua)
  void setLanguageCode(String languageCode) {
    if (_languageCode != languageCode) {
      debugPrint('Setting language code to: $languageCode');
      _languageCode = languageCode;
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
  
  // Dispose resources
  @override
  void dispose() {
    debugPrint('Disposing WitSpeechRecognitionService...');
    _recorder.closeRecorder();
    _isListening = false;
    debugPrint('WitSpeechRecognitionService disposed.');
    super.dispose();
  }
}