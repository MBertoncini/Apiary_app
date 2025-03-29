// lib/services/mock_speech_recognition_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class GoogleSpeechRecognitionService with ChangeNotifier {
  bool _isInitialized = true;
  bool _isListening = false;
  String _transcription = '';
  String _languageCode = 'it-IT';
  double _confidence = 0.0;
  List<String> _partialTranscripts = [];
  Timer? _simulationTimer;
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get transcription => _transcription;
  String get languageCode => _languageCode;
  double get confidence => _confidence;
  List<String> get partialTranscripts => _partialTranscripts;
  
  GoogleSpeechRecognitionService() {
    debugPrint('Mock speech recognition service created');
  }
  
  Future<bool> hasMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    
    status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  Future<bool> startListening() async {
    if (_isListening) return true;
    
    final hasPermission = await hasMicrophonePermission();
    if (!hasPermission) return false;
    
    _transcription = '';
    _isListening = true;
    notifyListeners();
    
    // Simula il riconoscimento parziale con timer
    _simulationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      
      // Aggiorna la trascrizione simulata
      _updateSimulatedTranscription();
    });
    
    return true;
  }
  
  void _updateSimulatedTranscription() {
    // Simula il riconoscimento che aggiunge parole gradualmente
    List<String> possibleWords = [
      'apiario',
      'centrale',
      'arnia',
      'cinque',
      'regina',
      'presente',
      'tre',
      'telaini',
      'di',
      'covata',
    ];
    
    int wordsCount = _transcription.split(' ').length;
    if (wordsCount < possibleWords.length) {
      if (_transcription.isEmpty) {
        _transcription = possibleWords[0];
      } else {
        _transcription += ' ' + possibleWords[wordsCount];
      }
      notifyListeners();
    }
  }
  
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _simulationTimer?.cancel();
    _isListening = false;
    
    // Finalizza la trascrizione
    _transcription = 'apiario centrale arnia cinque regina presente tre telaini di covata';
    _confidence = 0.9;
    _partialTranscripts.add(_transcription);
    notifyListeners();
  }
  
  void setLanguageCode(String languageCode) {
    _languageCode = languageCode;
    notifyListeners();
  }
  
  void clearTranscription() {
    _transcription = '';
    _confidence = 0.0;
    _partialTranscripts.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}