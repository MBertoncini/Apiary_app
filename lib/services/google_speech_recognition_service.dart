// lib/services/google_speech_recognition_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';
import '../services/voice_feedback_service.dart';

/// Servizio di riconoscimento vocale utilizzando Google Speech-to-Text API
class GoogleSpeechRecognitionService with ChangeNotifier {
  // Componenti per la registrazione e lo streaming
  final RecorderStream _recorder = RecorderStream();
  StreamSubscription<List<int>>? _audioStreamSubscription;
  
  // Componenti per Google Speech
  SpeechToText? _speechToText;
  StreamController<List<int>>? _audioStreamController;
  StreamSubscription? _recognitionSubscription;
  
  // Componenti di stato
  final VoiceFeedbackService _feedbackService;
  bool _isInitialized = false;
  bool _isListening = false;
  String _transcription = '';
  double _confidence = 0.0;
  List<String> _partialTranscripts = [];
  List<String> _locales = ['it-IT', 'en-US'];
  String _currentLocale = 'it-IT';
  
  // Timer per timeout automatico
  Timer? _listenTimeoutTimer;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get transcription => _transcription;
  String get recognitionMode => 'standard';
  double get confidence => _confidence;
  double get currentVolume => 0.0; // Non utilizzato ma mantenuto per compatibilità
  List<String> get partialTranscripts => _partialTranscripts;
  List<String> get locales => _locales;
  
  // Credenziali Google
  final String _googleCredentialsJson = '''
  {
    "type": "service_account",
    "project_id": "apiario-manager",
    "private_key_id": "your-private-key-id",
    "private_key": "your-private-key",
    "client_email": "apiario-speech@apiario-manager.iam.gserviceaccount.com",
    "client_id": "your-client-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/apiario-speech%40apiario-manager.iam.gserviceaccount.com"
  }
  ''';
  
  // Constructor
  GoogleSpeechRecognitionService({
    VoiceFeedbackService? feedbackService,
  }) : _feedbackService = feedbackService ?? VoiceFeedbackService() {
    _initSpeech();
  }
  
  // Inizializza il riconoscimento vocale
  Future<bool> _initSpeech() async {
    if (_isInitialized) return true;
    
    try {
      // Inizializza il recorder
      await _recorder.initialize();
      
      // Inizializza Google Speech
      final credentialsFile = await _saveCredentialsToTempFile();
      _speechToText = SpeechToText.fromFile(credentialsFile);
      
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Errore nell\'inizializzazione del riconoscimento vocale: $e');
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }
  
  // Salva le credenziali Google su un file temporaneo
  Future<File> _saveCredentialsToTempFile() async {
    final tempDir = await getTemporaryDirectory();
    final credentialsPath = '${tempDir.path}/google_credentials.json';
    final file = File(credentialsPath);
    await file.writeAsString(_googleCredentialsJson);
    return file;
  }
  
  // Avvia l'ascolto
  Future<bool> startListening({
    String mode = 'standard',
    String localeId = 'it-IT',
    String? wakePhrase,
    int timeoutSeconds = 60,
  }) async {
    if (_isListening) return true;
    
    if (!_isInitialized) {
      await _initSpeech();
    }
    
    if (!_isInitialized) {
      return false;
    }
    
    // Verifica e richiedi i permessi del microfono
    final permissionStatus = await Permission.microphone.request();
    if (permissionStatus != PermissionStatus.granted) {
      print('Permesso microfono non concesso');
      return false;
    }
    
    // Cancella timer precedente se esistente
    _listenTimeoutTimer?.cancel();
    
    try {
      // Pulisci lo stato precedente
      _transcription = '';
      _currentLocale = localeId;
      
      // Feedback di inizio ascolto
      _feedbackService.vibrateStart();
      
      // Configura lo stream controller per l'audio
      _audioStreamController = StreamController<List<int>>();
      
      // Configura il riconoscimento vocale
      final config = _createRecognitionConfig();
      final responseStream = _speechToText!.streamingRecognize(
        StreamingRecognitionConfig(
          config: config,
          interimResults: true,
        ),
        _audioStreamController!.stream,
      );
      
      // Ascolta i risultati del riconoscimento
      _recognitionSubscription = responseStream.listen(
        _processRecognitionResponse,
        onError: _onRecognitionError,
        onDone: _onRecognitionDone,
      );
      
      // Inizia la registrazione audio
      await _recorder.start();
      
      // Collega lo stream audio allo stream controller
      _audioStreamSubscription = _recorder.audioStream.listen((data) {
        if (_audioStreamController?.isClosed == false) {
          _audioStreamController!.add(data);
        }
      });
      
      _isListening = true;
      
      // Imposta timer per timeout automatico
      if (timeoutSeconds > 0) {
        _listenTimeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
          if (_isListening) {
            stopListening();
          }
        });
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Errore nell\'avvio del riconoscimento vocale: $e');
      _isListening = false;
      _feedbackService.vibrateError();
      notifyListeners();
      return false;
    }
  }
  
  // Crea la configurazione per il riconoscimento
  RecognitionConfig _createRecognitionConfig() {
    return RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      sampleRateHertz: 16000,
      languageCode: _currentLocale,
      maxAlternatives: 1,
      enableAutomaticPunctuation: true,
      model: 'phone_call', // 'command_and_search' può essere migliore per comandi brevi
      useEnhanced: true,
    );
  }
  
  // Processa i risultati del riconoscimento
  void _processRecognitionResponse(StreamingRecognizeResponse response) {
    // Ignora risposte vuote
    if (response.results.isEmpty) return;
    
    // Estrai il testo riconosciuto
    final result = response.results.first;
    final transcript = result.alternatives.first.transcript;
    
    // Aggiorna la trascrizione
    _transcription = transcript;
    
    // Calcola la confidenza
    if (result.alternatives.isNotEmpty) {
      _confidence = result.alternatives.first.confidence;
    }
    
    // Se è un risultato finale, registralo nella cronologia
    if (result.isFinal) {
      _partialTranscripts.add(transcript);
      
      // Limita la lunghezza della cronologia
      if (_partialTranscripts.length > 10) {
        _partialTranscripts.removeAt(0);
      }
      
      // Riproduci suono di successo
      if (transcript.isNotEmpty) {
        _feedbackService.vibrateSuccess();
      }
    }
    
    notifyListeners();
  }
  
  // Gestisci errori del riconoscimento
  void _onRecognitionError(Object error) {
    print('Errore nel riconoscimento vocale: $error');
    _feedbackService.vibrateError();
    stopListening();
  }
  
  // Gestisci la fine del riconoscimento
  void _onRecognitionDone() {
    // Non fare nulla, il riconoscimento verrà fermato manualmente
  }
  
  // Interrompi l'ascolto
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _listenTimeoutTimer?.cancel();
    
    try {
      // Ferma la registrazione
      await _recorder.stop();
      
      // Chiudi lo stream audio
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      
      // Chiudi lo stream controller
      await _audioStreamController?.close();
      _audioStreamController = null;
      
      // Annulla la sottoscrizione al riconoscimento
      await _recognitionSubscription?.cancel();
      _recognitionSubscription = null;
      
      _isListening = false;
      
      // Feedback tattile
      _feedbackService.vibrateStop();
      
      notifyListeners();
    } catch (e) {
      print('Errore nell\'interruzione del riconoscimento vocale: $e');
      _isListening = false;
      notifyListeners();
    }
  }
  
  // Annulla l'ascolto
  Future<void> cancelListening() async {
    await stopListening();
    _transcription = '';
    notifyListeners();
  }
  
  // Cancella la trascrizione corrente
  void clearTranscription() {
    _transcription = '';
    notifyListeners();
  }
  
  // Ottieni le lingue disponibili per il riconoscimento
  Future<List<Map<String, String>>> getAvailableLocales() async {
    return _locales.map((locale) {
      final parts = locale.split('-');
      String name = 'Sconosciuto';
      
      // Mappatura semplice delle lingue supportate
      if (parts[0] == 'it') name = 'Italiano';
      else if (parts[0] == 'en') name = 'Inglese';
      else if (parts[0] == 'fr') name = 'Francese';
      else if (parts[0] == 'es') name = 'Spagnolo';
      else if (parts[0] == 'de') name = 'Tedesco';
      
      return {
        'id': locale,
        'name': name,
      };
    }).toList();
  }
  
  // Verifica se il permesso del microfono è concesso
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
  
  @override
  void dispose() {
    _listenTimeoutTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _audioStreamController?.close();
    _recognitionSubscription?.cancel();
    _recorder.stop();
    super.dispose();
  }
}