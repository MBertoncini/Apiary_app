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
import 'package:path_provider/path_provider.dart';

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
      try {
        final streamedResponse = await httpClient.send(request);
        final response = await http.Response.fromStream(streamedResponse);
        
        debugPrint('Wit.ai API response code: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          await _saveResponseToDebugFile(response.body);
          
          try {
            // Estrai il primo oggetto JSON dalla risposta
            final firstJsonObject = _extractFirstJsonObject(response.body);
            debugPrint('First JSON object: $firstJsonObject');
            
            if (firstJsonObject != null) {
              final responseJson = jsonDecode(firstJsonObject);
              
              // Estrai il testo trascritto
              _transcription = responseJson['text'] ?? '';
              
              // Se non c'è testo nel primo oggetto, prova il secondo
              if (_transcription.isEmpty) {
                final secondJsonObject = _extractSecondJsonObject(response.body);
                if (secondJsonObject != null) {
                  final secondJson = jsonDecode(secondJsonObject);
                  _transcription = secondJson['text'] ?? '';
                }
              }
              
              // Aggiorna la confidenza
              if (responseJson['speech'] != null && responseJson['speech']['confidence'] != null) {
                _confidence = responseJson['speech']['confidence'] ?? 0.0;
              } else {
                _confidence = _transcription.isNotEmpty ? 0.8 : 0.0;
              }
              
              if (_transcription.isNotEmpty) {
                debugPrint('Transcription: "$_transcription"');
                _partialTranscripts.add(_transcription);
                if (_partialTranscripts.length > 10) {
                  _partialTranscripts.removeAt(0);
                }
              } else {
                debugPrint('Wit.ai non ha riconosciuto alcun testo nell\'audio');
              }
            } else {
              debugPrint('Impossibile estrarre un oggetto JSON valido dalla risposta');
            }
            
            notifyListeners();
          } catch (parseError) {
            debugPrint('Error decoding JSON from Wit.ai: $parseError');
            _transcription = '';
            notifyListeners();
          }
        } else {
          debugPrint('Error from Wit.ai API: ${response.statusCode} - ${response.body}');
        }
      } finally {
        httpClient.close();
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing audio with Wit.ai: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Metodo per estrarre il primo oggetto JSON dalla risposta
  String? _extractFirstJsonObject(String text) {
    final firstOpenBrace = text.indexOf('{');
    if (firstOpenBrace < 0) return null;
    
    int depth = 0;
    for (int i = firstOpenBrace; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}') {
        depth--;
        if (depth == 0) {
          return text.substring(firstOpenBrace, i + 1);
        }
      }
    }
    
    return null; // Nessun oggetto JSON valido trovato
  }

  // Metodo per estrarre il secondo oggetto JSON dalla risposta
  String? _extractSecondJsonObject(String text) {
    // Trova il primo oggetto JSON completo
    final firstJson = _extractFirstJsonObject(text);
    if (firstJson == null) return null;
    
    // Cerca il prossimo '{' dopo il primo oggetto
    final startPos = text.indexOf(firstJson) + firstJson.length;
    final secondOpenBrace = text.indexOf('{', startPos);
    if (secondOpenBrace < 0) return null;
    
    int depth = 0;
    for (int i = secondOpenBrace; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}') {
        depth--;
        if (depth == 0) {
          return text.substring(secondOpenBrace, i + 1);
        }
      }
    }
    
    return null; // Nessun secondo oggetto JSON trovato
  }

  // Metodo per pulire la risposta JSON
  String _cleanJsonResponse(String jsonString) {
    // Rimuovi caratteri di controllo invisibili che causano problemi di parsing
    String cleaned = jsonString.replaceAll(RegExp(r'[\u0000-\u001F]'), '');
    
    // Rimuovi caratteri di formattazione o non-JSON
    cleaned = cleaned.trim();
    
    // Assicurati che inizi con { e finisca con }
    if (!cleaned.startsWith('{')) {
      int startBrace = cleaned.indexOf('{');
      if (startBrace >= 0) {
        cleaned = cleaned.substring(startBrace);
      } else {
        // Non c'è una parentesi graffa aperta, questo non è un JSON
        cleaned = '{"text":""}';
      }
    }
    
    if (!cleaned.endsWith('}')) {
      int endBrace = cleaned.lastIndexOf('}');
      if (endBrace >= 0) {
        cleaned = cleaned.substring(0, endBrace + 1);
      } else {
        // Non c'è una parentesi graffa chiusa, questo non è un JSON
        cleaned = '{"text":""}';
      }
    }
    
    return cleaned;
  }

  // Metodo per salvare la risposta per debug
  Future<void> _saveResponseToDebugFile(String responseBody) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/wit_error_response.txt');
      await file.writeAsString(responseBody);
      debugPrint('Response saved to: ${file.path}');
    } catch (e) {
      debugPrint('Error saving debug file: $e');
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